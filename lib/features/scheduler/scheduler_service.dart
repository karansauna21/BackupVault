import 'scheduler_engine.dart';

class SchedulerService extends SchedulerEngine {
  SchedulerService({
    required super.folderRepository,
    required super.schedulerRepository,
    required super.jobManager,
    required super.backupEngine,
  });
}
