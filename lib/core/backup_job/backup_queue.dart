import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/services/logging_service.dart';
import '../database/database_provider.dart';
import 'backup_job_repository.dart';
import 'backup_job_service.dart';
import 'backup_worker.dart';
import '../transfer/transfer_manager.dart';

class BackupQueueState {
  final List<BackupJob> jobs;
  final bool isPaused;
  final String? activeJobId;

  BackupQueueState({
    required this.jobs,
    required this.isPaused,
    this.activeJobId,
  });

  BackupQueueState copyWith({
    List<BackupJob>? jobs,
    bool? isPaused,
    String? activeJobId,
  }) {
    return BackupQueueState(
      jobs: jobs ?? this.jobs,
      isPaused: isPaused ?? this.isPaused,
      activeJobId: activeJobId ?? this.activeJobId,
    );
  }
}

class BackupQueueNotifier extends Notifier<BackupQueueState> {
  BackupWorker? _activeWorker;

  @override
  BackupQueueState build() {
    // Start asynchronous load of jobs.
    Future.microtask(() => _loadJobs());
    return BackupQueueState(
      jobs: [],
      isPaused: false,
      activeJobId: null,
    );
  }

  Future<void> _loadJobs() async {
    final repo = ref.read(backupJobRepositoryProvider);
    final list = await repo.getAllJobs();

    // Sort by createdAt ascending
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (int i = 0; i < list.length; i++) {
      final job = list[i];
      if (job.status == 'Preparing' || job.status == 'Queued' || job.status == 'Ready') {
        final resetJob = job.copyWithCustom(
          status: 'Waiting',
          progress: 0.0,
        );
        await repo.saveJob(resetJob);
        list[i] = resetJob;
      }
    }

    state = BackupQueueState(
      jobs: list,
      isPaused: state.isPaused,
      activeJobId: state.activeJobId,
    );

    _runNextJob();
  }

  Future<void> createAndAddJob(int folderId) async {
    final service = ref.read(backupJobServiceProvider);
    final job = await service.createJob(folderId);

    state = state.copyWith(
      jobs: [...state.jobs, job],
    );

    _runNextJob();
  }

  void pauseQueue() {
    state = state.copyWith(isPaused: true);
    _activeWorker?.pause();
  }

  void resumeQueue() {
    state = state.copyWith(isPaused: false);
    if (_activeWorker != null) {
      _activeWorker!.resume();
    } else {
      _runNextJob();
    }
  }

  Future<void> cancelJob(String jobId) async {
    final repo = ref.read(backupJobRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);

    if (state.activeJobId == jobId) {
      _activeWorker?.cancel();
    } else {
      final updatedJobs = state.jobs.map((job) {
        if (job.id == jobId) {
          final cancelledJob = job.copyWithCustom(
            status: 'Cancelled',
            completedTime: DateTime.now(),
          );
          repo.saveJob(cancelledJob);
          logger.warning('BackupJob', 'Job Cancelled: ${job.id}');
          return cancelledJob;
        }
        return job;
      }).toList();

      state = state.copyWith(jobs: updatedJobs);
    }
  }

  Future<void> retryJob(String jobId) async {
    final repo = ref.read(backupJobRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);

    final updatedJobs = state.jobs.map((job) {
      if (job.id == jobId) {
        final resetJob = job.copyWithCustom(
          status: 'Waiting',
          progress: 0.0,
          startedTime: null,
          completedTime: null,
          error: null,
        );
        repo.saveJob(resetJob);
        logger.info('BackupJob', 'Job Retried: ${job.id}');
        return resetJob;
      }
      return job;
    }).toList();

    state = state.copyWith(jobs: updatedJobs);
    _runNextJob();
  }

  Future<void> retryAllFailed() async {
    final repo = ref.read(backupJobRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);

    final updatedJobs = state.jobs.map((job) {
      if (job.status == 'Failed' || job.status == 'Cancelled') {
        final resetJob = job.copyWithCustom(
          status: 'Waiting',
          progress: 0.0,
          startedTime: null,
          completedTime: null,
          error: null,
        );
        repo.saveJob(resetJob);
        logger.info('BackupJob', 'Job Retried: ${job.id}');
        return resetJob;
      }
      return job;
    }).toList();

    state = state.copyWith(jobs: updatedJobs);
    _runNextJob();
  }

  Future<void> _runNextJob() async {
    if (state.isPaused) return;
    if (_activeWorker != null) return;

    // Find first Waiting or Queued job
    BackupJob? nextJob;
    for (final job in state.jobs) {
      if (job.status == 'Waiting' || job.status == 'Queued') {
        nextJob = job;
        break;
      }
    }

    if (nextJob == null) return;

    final repo = ref.read(backupJobRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);
    final db = ref.read(databaseProvider);
    final transferManager = ref.read(transferManagerProvider);

    state = state.copyWith(activeJobId: nextJob.id);

    _activeWorker = BackupWorker(
      job: nextJob,
      repository: repo,
      logger: logger,
      db: db,
      transferManager: transferManager,
      onUpdate: (updatedJob) {
        final updatedList = state.jobs.map((j) {
          return j.id == updatedJob.id ? updatedJob : j;
        }).toList();

        // If the job reaches a terminal state, clear the active worker
        final isTerminal = updatedJob.status == 'Completed' ||
            updatedJob.status == 'Failed' ||
            updatedJob.status == 'Cancelled';

        state = state.copyWith(
          jobs: updatedList,
          activeJobId: isTerminal ? null : state.activeJobId,
        );

        if (isTerminal) {
          _activeWorker = null;
          // Run the next job after a short delay
          Future.delayed(const Duration(milliseconds: 100), () => _runNextJob());
        }
      },
    );

    // Run the worker asynchronously
    unawaited(_activeWorker!.run());
  }
}

final backupJobRepositoryProvider = Provider<BackupJobRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupJobRepositoryImpl(db);
});

final backupJobServiceProvider = Provider<BackupJobService>((ref) {
  final repo = ref.watch(backupJobRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final db = ref.watch(databaseProvider);
  return BackupJobService(repo, logger, db);
});

final backupQueueProvider = NotifierProvider<BackupQueueNotifier, BackupQueueState>(() {
  return BackupQueueNotifier();
});
