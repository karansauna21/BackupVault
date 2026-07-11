import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/services/backup_engine.dart';
import '../../core/repositories/scheduler_repository.dart';
import '../../core/models/scheduler_models.dart';
import '../../core/models/schedule_history.dart';
import '../../core/scheduler/job_manager.dart';
import '../../core/scheduler/scheduler_engine.dart';
import '../../core/scheduler/scheduler_service.dart';
import '../../core/scheduler/rule_engine.dart';
import 'platform_providers.dart';

// Repository Provider
final schedulerRepositoryProvider = Provider<SchedulerRepository>((ref) {
  return SchedulerRepository();
});

// Job Manager Notifier Provider
final schedulerJobManagerProvider = NotifierProvider<JobManager, List<ScheduledBackupJob>>(() {
  return JobManager();
});

// Scheduler Engine Provider
final schedulerEngineProvider = Provider<SchedulerEngine>((ref) {
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final schedulerRepo = ref.watch(schedulerRepositoryProvider);
  final jobManager = ref.watch(schedulerJobManagerProvider.notifier);
  final backupEngine = ref.watch(backupEngineProvider);
  final platformInfo = ref.watch(platformInfoProvider);
  final storage = ref.watch(storageProvider);

  return SchedulerEngine(
    folderRepository: folderRepo,
    schedulerRepository: schedulerRepo,
    jobManager: jobManager,
    backupEngine: backupEngine,
    platformInfo: platformInfo,
    storageProvider: storage,
  );
});

// Scheduler Service Provider
final schedulerServiceProvider = Provider<SchedulerService>((ref) {
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final schedulerRepo = ref.watch(schedulerRepositoryProvider);
  final jobManager = ref.watch(schedulerJobManagerProvider.notifier);
  final backupEngine = ref.watch(backupEngineProvider);
  final platformInfo = ref.watch(platformInfoProvider);
  final storage = ref.watch(storageProvider);

  return SchedulerService(
    folderRepository: folderRepo,
    schedulerRepository: schedulerRepo,
    jobManager: jobManager,
    backupEngine: backupEngine,
    platformInfo: platformInfo,
    storageProvider: storage,
  );
});

// Current Schedules Notifier
class SchedulesNotifier extends Notifier<List<ScheduleConfig>> {
  late final SchedulerRepository _repo;

  @override
  List<ScheduleConfig> build() {
    _repo = ref.watch(schedulerRepositoryProvider);
    return _repo.schedules;
  }

  Future<void> addSchedule(ScheduleConfig schedule) async {
    await _repo.addSchedule(schedule);
    state = List<ScheduleConfig>.from(_repo.schedules);
  }

  Future<void> updateSchedule(ScheduleConfig schedule) async {
    await _repo.updateSchedule(schedule);
    state = List<ScheduleConfig>.from(_repo.schedules);
  }

  Future<void> deleteSchedule(String id) async {
    await _repo.deleteSchedule(id);
    state = List<ScheduleConfig>.from(_repo.schedules);
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    final schedule = state.firstWhere((s) => s.id == id);
    final updated = schedule.copyWith(enabled: enabled);
    await _repo.updateSchedule(updated);
    state = List<ScheduleConfig>.from(_repo.schedules);
  }
}

final schedulesProvider = NotifierProvider<SchedulesNotifier, List<ScheduleConfig>>(() {
  return SchedulesNotifier();
});

// Upcoming Jobs List Provider
class UpcomingJobInfo {
  final ScheduleConfig schedule;
  final DateTime nextRunTime;

  UpcomingJobInfo({required this.schedule, required this.nextRunTime});
}

final upcomingJobsProvider = Provider<List<UpcomingJobInfo>>((ref) {
  final schedules = ref.watch(schedulesProvider);
  final now = DateTime.now();

  final list = <UpcomingJobInfo>[];
  for (final schedule in schedules) {
    if (!schedule.enabled) continue;
    final nextTime = schedule.nextRunTime ?? now.add(const Duration(hours: 1));
    list.add(UpcomingJobInfo(schedule: schedule, nextRunTime: nextTime));
  }

  list.sort((a, b) => a.nextRunTime.compareTo(b.nextRunTime));
  return list;
});

// Running Jobs Provider
final runningJobsProvider = Provider<List<ScheduledBackupJob>>((ref) {
  final jobs = ref.watch(schedulerJobManagerProvider);
  return jobs.where((j) => j.status == 'running').toList();
});

// Paused Jobs Provider
final pausedJobsProvider = Provider<List<ScheduledBackupJob>>((ref) {
  final jobs = ref.watch(schedulerJobManagerProvider);
  return jobs.where((j) => j.status == 'paused').toList();
});

// Execution History Notifier
class HistoryNotifier extends Notifier<List<ScheduleHistory>> {
  late final SchedulerRepository _repo;

  @override
  List<ScheduleHistory> build() {
    _repo = ref.watch(schedulerRepositoryProvider);
    return _repo.history;
  }

  Future<void> clearHistory() async {
    await _repo.clearHistory();
    state = List<ScheduleHistory>.from(_repo.history);
  }

  void refresh() {
    state = List<ScheduleHistory>.from(_repo.history);
  }
}

final scheduleHistoryProvider = NotifierProvider<HistoryNotifier, List<ScheduleHistory>>(() {
  return HistoryNotifier();
});

// Automation Status Model
class AutomationStatus {
  final bool enabled;
  final double cpuUsage;
  final int batteryLevel;
  final bool isCharging;
  final bool gamingMode;

  AutomationStatus({
    required this.enabled,
    required this.cpuUsage,
    required this.batteryLevel,
    required this.isCharging,
    required this.gamingMode,
  });
}

final automationStatusProvider = Provider<AutomationStatus>((ref) {
  final engine = ref.watch(schedulerEngineProvider);
  final platformInfo = ref.watch(platformInfoProvider);

  return AutomationStatus(
    enabled: engine.automationEnabled,
    cpuUsage: RuleEngine.useSimulationMode ? 24.0 : platformInfo.cpuUsage, // RuleEngine simulations can be queried directly or via PlatformInfo simulation support if needed.
    batteryLevel: RuleEngine.useSimulationMode ? 85 : platformInfo.batteryLevel,
    isCharging: RuleEngine.useSimulationMode ? true : platformInfo.isCharging,
    gamingMode: RuleEngine.gamingMode,
  );
});

class SchedulerController {
  final Ref _ref;

  SchedulerController(this._ref);

  /// Create a new schedule
  Future<void> addSchedule({
    required String name,
    required int folderId,
    required String scheduleType,
    String? customCronExpression,
    required List<String> triggerTypes,
    String? triggerSpecificTime,
    DateTime? triggerSpecificDate,
    required SmartRules rules,
    bool enabled = true,
  }) async {
    final schedule = ScheduleConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      folderId: folderId,
      scheduleType: scheduleType,
      customCronExpression: customCronExpression,
      triggerTypes: triggerTypes,
      triggerSpecificTime: triggerSpecificTime,
      triggerSpecificDate: triggerSpecificDate,
      rules: rules,
      enabled: enabled,
    );

    await _ref.read(schedulesProvider.notifier).addSchedule(schedule);
  }

  /// Update an existing schedule
  Future<void> editSchedule(
    ScheduleConfig existing, {
    String? name,
    int? folderId,
    String? scheduleType,
    String? customCronExpression,
    List<String>? triggerTypes,
    String? triggerSpecificTime,
    DateTime? triggerSpecificDate,
    SmartRules? rules,
    bool? enabled,
  }) async {
    final updated = existing.copyWith(
      name: name,
      folderId: folderId,
      scheduleType: scheduleType,
      customCronExpression: customCronExpression,
      triggerTypes: triggerTypes,
      triggerSpecificTime: triggerSpecificTime,
      triggerSpecificDate: triggerSpecificDate,
      rules: rules,
      enabled: enabled,
    );

    await _ref.read(schedulesProvider.notifier).updateSchedule(updated);
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String id) async {
    await _ref.read(schedulesProvider.notifier).deleteSchedule(id);
  }

  /// Toggle schedule status (enabled/disabled)
  Future<void> toggleSchedule(String id, bool enabled) async {
    await _ref.read(schedulesProvider.notifier).toggleSchedule(id, enabled);
  }

  /// Run a scheduled backup job immediately (Manual override)
  Future<bool> triggerBackupManually(ScheduleConfig schedule) async {
    final folders = await _ref.read(backupFolderRepositoryProvider).getAllFolders();
    final folder = folders.where((f) => f.id == schedule.folderId).firstOrNull;
    if (folder == null || !folder.enabled) return false;

    // Queue in priority queue immediately
    await _ref.read(schedulerJobManagerProvider.notifier).queueJob(
      folder: folder,
      scheduleId: schedule.id,
      triggerSource: 'Manual Execution',
      queueType: 'priority',
    );
    return true;
  }

  /// Clear execution history
  Future<void> clearHistory() async {
    await _ref.read(scheduleHistoryProvider.notifier).clearHistory();
  }

  /// Toggle automation engine
  void toggleAutomation(bool enabled) {
    _ref.read(schedulerEngineProvider).toggleAutomation(enabled);
    _ref.invalidate(automationStatusProvider);
  }

  /// Update simulated values
  void updateSystemSimulation({
    double? cpu,
    int? battery,
    bool? charging,
    bool? gaming,
  }) {
    if (cpu != null) RuleEngine.setSimulatedCpu(cpu);
    if (battery != null) RuleEngine.setSimulatedBattery(battery);
    if (charging != null) RuleEngine.setSimulatedCharging(charging);
    if (gaming != null) RuleEngine.setGamingMode(gaming);

    _ref.invalidate(automationStatusProvider);
  }
}

final schedulerControllerProvider = Provider<SchedulerController>((ref) {
  return SchedulerController(ref);
});
