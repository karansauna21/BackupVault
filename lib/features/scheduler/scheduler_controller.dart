import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/repository_providers.dart';
import 'scheduler_models.dart';
import 'scheduler_provider.dart';
import 'rule_engine.dart';

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
    // Refresh status provider by forcing update (can just read it)
    _ref.invalidate(automationStatusProvider);
  }

  /// Update simulated values (useful for testing and control)
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
