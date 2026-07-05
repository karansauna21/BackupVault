import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/services/backup_engine.dart';
import 'scheduler_repository.dart';
import 'scheduler_models.dart';
import 'schedule_history.dart';
import 'job_manager.dart';
import 'scheduler_engine.dart';
import 'scheduler_service.dart';
import 'rule_engine.dart';

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

  return SchedulerEngine(
    folderRepository: folderRepo,
    schedulerRepository: schedulerRepo,
    jobManager: jobManager,
    backupEngine: backupEngine,
  );
});

// Scheduler Service Provider
final schedulerServiceProvider = Provider<SchedulerService>((ref) {
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final schedulerRepo = ref.watch(schedulerRepositoryProvider);
  final jobManager = ref.watch(schedulerJobManagerProvider.notifier);
  final backupEngine = ref.watch(backupEngineProvider);

  return SchedulerService(
    folderRepository: folderRepo,
    schedulerRepository: schedulerRepo,
    jobManager: jobManager,
    backupEngine: backupEngine,
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
    // Calculate approximate next run time if not set
    final nextTime = schedule.nextRunTime ?? now.add(const Duration(hours: 1));
    list.add(UpcomingJobInfo(schedule: schedule, nextRunTime: nextTime));
  }

  // Sort by earliest next run time
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

  // We can query the static variables in RuleEngine directly for real-time system stats
  return AutomationStatus(
    enabled: engine.automationEnabled,
    cpuUsage: RuleEngine.cpuUsage,
    batteryLevel: RuleEngine.batteryLevel,
    isCharging: RuleEngine.isCharging,
    gamingMode: RuleEngine.gamingMode,
  );
});
