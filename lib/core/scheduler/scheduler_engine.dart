// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import '../../core/repositories/backup_folder_repository.dart';
import '../services/backup_engine.dart';
import '../../core/repositories/scheduler_repository.dart';
import '../../core/models/scheduler_models.dart';
import '../../core/services/platform_info.dart';
import '../../core/services/storage_provider.dart';
import 'schedule_validator.dart';
import 'rule_engine.dart';
import 'trigger_engine.dart';
import 'job_manager.dart';

class SchedulerEngine {
  final BackupFolderRepository _folderRepository;
  final SchedulerRepository _schedulerRepository;
  final JobManager _jobManager;
  final BackupEngine _backupEngine;
  final PlatformInfo _platformInfo;
  final StorageProvider _storageProvider;

  late final RuleEngine _ruleEngine;
  late final TriggerEngine _triggerEngine;

  Timer? _checkTimer;
  DateTime? _lastRunMinute;
  bool _initialized = false;
  bool _automationEnabled = true;

  bool get automationEnabled => _automationEnabled;

  // ignore: use_initializing_formals
  SchedulerEngine({
    required BackupFolderRepository folderRepository,
    required SchedulerRepository schedulerRepository,
    required JobManager jobManager,
    required BackupEngine backupEngine,
    required PlatformInfo platformInfo,
    required StorageProvider storageProvider,
  })  : _folderRepository = folderRepository,
        _schedulerRepository = schedulerRepository,
        _jobManager = jobManager,
        _backupEngine = backupEngine,
        _platformInfo = platformInfo,
        _storageProvider = storageProvider;

  Future<void> init() async {
    if (_initialized) return;

    _ruleEngine = RuleEngine(_platformInfo, _storageProvider);
    _triggerEngine = TriggerEngine(
      onTriggerFired: (triggerType, {folderId}) => _handleTriggerFired(triggerType, folderId: folderId),
      platformInfo: _platformInfo,
    );

    // Initial check of all folder watchers
    await _syncFolderWatchers();

    // Start trigger engine
    _triggerEngine.init();

    // Run timer check every 15 seconds to evaluate periodic intervals & validate destinations
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _evaluateSchedules();
      _runAutomations();
    });

    _initialized = true;
  }

  void dispose() {
    _checkTimer?.cancel();
    _triggerEngine.dispose();
    _initialized = false;
  }

  void toggleAutomation(bool enabled) {
    _automationEnabled = enabled;
  }

  /// Synchronize real-time folder watchers based on active schedule triggers
  Future<void> _syncFolderWatchers() async {
    if (!_automationEnabled) return;
    try {
      final folders = await _folderRepository.getAllFolders();
      final schedules = _schedulerRepository.schedules;

      for (final folder in folders) {
        final folderSchedules = schedules.where((s) => s.folderId == folder.id && s.enabled);
        final hasRealTimeTrigger = folderSchedules.any(
          (s) => s.scheduleType == 'Real-time' || s.triggerTypes.contains('Folder Changed') || s.triggerTypes.contains('New File') || s.triggerTypes.contains('Modified File')
        );

        if (hasRealTimeTrigger && folder.enabled) {
          // Tell BackupEngine to enable watcher for this folder
          _backupEngine.enableFolderWatching(folder);
        } else {
          // Disable watcher if no real-time trigger exists
          _backupEngine.disableFolderWatching(folder.id);
        }
      }
    } catch (_) {
      // Ignored during shutdown or startup
    }
  }

  /// System triggers callback
  Future<void> _handleTriggerFired(String triggerType, {int? folderId}) async {
    if (!_automationEnabled) return;

    final schedules = _schedulerRepository.schedules;
    final folders = await _folderRepository.getAllFolders();

    for (final schedule in schedules) {
      if (!schedule.enabled) continue;

      // If trigger specifies a folder, ensure schedule belongs to that folder
      if (folderId != null && schedule.folderId != folderId) continue;

      final folder = folders.where((f) => f.id == schedule.folderId).firstOrNull;
      if (folder == null || !folder.enabled) continue;

      // Check if schedule supports this trigger type
      final hasTrigger = schedule.triggerTypes.contains(triggerType);
      if (!hasTrigger) continue;

      // Time and Date triggers require matching specific criteria
      if (triggerType == 'Specific Time') {
        if (schedule.triggerSpecificTime != null) {
          final now = DateTime.now();
          final parts = schedule.triggerSpecificTime!.split(':');
          final targetHour = int.parse(parts[0]);
          final targetMin = int.parse(parts[1]);
          if (now.hour != targetHour || now.minute != targetMin) continue;
        }
      }

      if (triggerType == 'Specific Date') {
        if (schedule.triggerSpecificDate != null) {
          final now = DateTime.now();
          final target = schedule.triggerSpecificDate!;
          if (now.year != target.year || now.month != target.month || now.day != target.day) continue;
        }
      }

      // Check smart rules
      final ruleResult = await _ruleEngine.evaluateRules(
        config: schedule,
        folder: folder,
        activeJobs: _jobManager.jobs.map((j) => j.toJson()).toList(),
      );

      if (ruleResult.isAllowed) {
        // Queue the job!
        await _jobManager.queueJob(
          folder: folder,
          scheduleId: schedule.id,
          triggerSource: 'Trigger: $triggerType',
          queueType: _getQueueTypeForSchedule(schedule),
        );

        // Update schedule last run time
        final updated = schedule.copyWith(lastRunTime: DateTime.now());
        await _schedulerRepository.updateSchedule(updated);
      }
    }
  }

  /// Periodic scheduler logic
  Future<void> _evaluateSchedules() async {
    final now = DateTime.now();
    if (_lastRunMinute != null && _lastRunMinute!.minute == now.minute && _lastRunMinute!.hour == now.hour && _lastRunMinute!.day == now.day) {
      // Run once per minute max
      return;
    }
    _lastRunMinute = now;

    final schedules = _schedulerRepository.schedules;
    final folders = await _folderRepository.getAllFolders();

    for (final schedule in schedules) {
      if (!schedule.enabled) continue;

      final folder = folders.where((f) => f.id == schedule.folderId).firstOrNull;
      if (folder == null || !folder.enabled) continue;

      bool shouldRun = false;

      // Evaluate time intervals
      switch (schedule.scheduleType) {
        case 'Every Minute':
          shouldRun = true;
          break;
        case 'Every 5 Minutes':
          shouldRun = now.minute % 5 == 0;
          break;
        case 'Every 10 Minutes':
          shouldRun = now.minute % 10 == 0;
          break;
        case 'Every 30 Minutes':
          shouldRun = now.minute % 30 == 0;
          break;
        case 'Hourly':
          shouldRun = now.minute == 0;
          break;
        case 'Daily':
          if (schedule.triggerSpecificTime != null) {
            final parts = schedule.triggerSpecificTime!.split(':');
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            shouldRun = now.hour == h && now.minute == m;
          } else {
            shouldRun = now.hour == 0 && now.minute == 0; // midnight default
          }
          break;
        case 'Weekly':
          if (schedule.triggerSpecificTime != null) {
            final parts = schedule.triggerSpecificTime!.split(':');
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            shouldRun = now.weekday == 1 && now.hour == h && now.minute == m; // Monday
          } else {
            shouldRun = now.weekday == 1 && now.hour == 0 && now.minute == 0;
          }
          break;
        case 'Monthly':
          if (schedule.triggerSpecificTime != null) {
            final parts = schedule.triggerSpecificTime!.split(':');
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            shouldRun = now.day == 1 && now.hour == h && now.minute == m;
          } else {
            shouldRun = now.day == 1 && now.hour == 0 && now.minute == 0;
          }
          break;
        case 'Custom Cron Expression':
          if (schedule.customCronExpression != null) {
            shouldRun = ScheduleValidator.matchesCron(schedule.customCronExpression!, now);
          }
          break;
        default:
          shouldRun = false;
          break;
      }

      if (shouldRun) {
        // Evaluate smart rules
        final ruleResult = await _ruleEngine.evaluateRules(
          config: schedule,
          folder: folder,
          activeJobs: _jobManager.jobs.map((j) => j.toJson()).toList(),
        );

        if (ruleResult.isAllowed) {
          await _jobManager.queueJob(
            folder: folder,
            scheduleId: schedule.id,
            triggerSource: 'Schedule: ${schedule.scheduleType}',
            queueType: _getQueueTypeForSchedule(schedule),
          );

          // Update times
          final updated = schedule.copyWith(
            lastRunTime: now,
            nextRunTime: _calculateNextRun(schedule, now),
          );
          await _schedulerRepository.updateSchedule(updated);
        }
      }
    }
  }

  /// Run background automations (Automatically reconnect, validate destinations, resume queue)
  Future<void> _runAutomations() async {
    if (!_automationEnabled) return;

    try {
      final folders = await _folderRepository.getAllFolders();

      for (final folder in folders) {
        if (!folder.enabled) continue;

        // Auto validate destination path
        final dest = Directory(folder.destinationPath);
        final isAvailable = await dest.exists();

        if (isAvailable) {
          // Destination is reconnected / available!
          final hasPausedJobs = _jobManager.jobs.any(
            (j) => j.folderId == folder.id && j.status == 'paused' && (j.error?.contains('destination') ?? false)
          );

          if (hasPausedJobs) {
            // Find all paused jobs for this folder and resume them
            final paused = _jobManager.jobs.where((j) => j.folderId == folder.id && j.status == 'paused').toList();
            for (final job in paused) {
              await _jobManager.resumeJob(job.id);
            }
          }
        }
      }
    } catch (_) {
      // Ignored
    }
  }

  String _getQueueTypeForSchedule(ScheduleConfig schedule) {
    if (schedule.scheduleType == 'Manual') return 'priority';
    if (schedule.triggerTypes.contains('System Idle')) return 'background';
    return 'normal';
  }

  DateTime _calculateNextRun(ScheduleConfig schedule, DateTime from) {
    switch (schedule.scheduleType) {
      case 'Every Minute':
        return from.add(const Duration(minutes: 1));
      case 'Every 5 Minutes':
        return from.add(const Duration(minutes: 5));
      case 'Every 10 Minutes':
        return from.add(const Duration(minutes: 10));
      case 'Every 30 Minutes':
        return from.add(const Duration(minutes: 30));
      case 'Hourly':
        return from.add(const Duration(hours: 1));
      case 'Daily':
        return from.add(const Duration(days: 1));
      case 'Weekly':
        return from.add(const Duration(days: 7));
      case 'Monthly':
        return from.add(const Duration(days: 30));
      default:
        return from.add(const Duration(days: 1));
    }
  }
}
