import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/backup_engine.dart';
import '../copy_engine/copy_job.dart';
import '../copy_engine/copy_queue.dart';
import '../../features/backup/workflows/backup_workflow_provider.dart';
import '../repositories/scheduler_repository.dart';
import '../models/schedule_history.dart';

class ScheduledBackupJob {
  final String id;
  final int folderId;
  final String scheduleId;
  final String folderName;
  final String sourcePath;
  final String destinationPath;
  final String queueType; // 'priority', 'normal', 'background', 'retry', 'failed', 'completed', 'pending'
  final String status; // 'pending', 'running', 'completed', 'failed', 'paused'
  final int retryCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double progress;
  final String? error;
  final String triggerSource; // e.g. 'Manual', 'Daily', 'USB Connected'

  ScheduledBackupJob({
    required this.id,
    required this.folderId,
    required this.scheduleId,
    required this.folderName,
    required this.sourcePath,
    required this.destinationPath,
    required this.queueType,
    required this.status,
    this.retryCount = 0,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.progress = 0.0,
    this.error,
    required this.triggerSource,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'scheduleId': scheduleId,
      'folderName': folderName,
      'sourcePath': sourcePath,
      'destinationPath': destinationPath,
      'queueType': queueType,
      'status': status,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'progress': progress,
      'error': error,
      'triggerSource': triggerSource,
    };
  }

  factory ScheduledBackupJob.fromJson(Map<String, dynamic> json) {
    return ScheduledBackupJob(
      id: json['id'] as String,
      folderId: json['folderId'] as int,
      scheduleId: json['scheduleId'] as String,
      folderName: json['folderName'] as String,
      sourcePath: json['sourcePath'] as String,
      destinationPath: json['destinationPath'] as String,
      queueType: json['queueType'] as String,
      status: json['status'] as String,
      retryCount: json['retryCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      progress: (json['progress'] as num? ?? 0.0).toDouble(),
      error: json['error'] as String?,
      triggerSource: json['triggerSource'] as String,
    );
  }

  ScheduledBackupJob copyWith({
    String? queueType,
    String? status,
    int? retryCount,
    DateTime? startedAt,
    DateTime? completedAt,
    double? progress,
    String? error,
  }) {
    return ScheduledBackupJob(
      id: id,
      folderId: folderId,
      scheduleId: scheduleId,
      folderName: folderName,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      queueType: queueType ?? this.queueType,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      triggerSource: triggerSource,
    );
  }
}

class JobManager extends Notifier<List<ScheduledBackupJob>> {
  late final SchedulerRepository _repository;
  bool _isProcessing = false;

  @override
  List<ScheduledBackupJob> build() {
    return [];
  }

  Future<void> init(SchedulerRepository repository, BackupEngine backupEngine) async {
    _repository = repository;

    // Load persisted pending jobs (if any) and reset their running status to pending
    final loaded = _repository.pendingJobs.map((e) {
      final job = ScheduledBackupJob.fromJson(e);
      if (job.status == 'running') {
        return job.copyWith(status: 'pending', queueType: 'pending');
      }
      return job;
    }).toList();

    state = loaded;

    // Start listening to the core copyQueueProvider to track file-level progress of folders
    ref.listen(copyQueueProvider, (prev, next) {
      _updateProgressFromCopyQueue(next);
    });

    _processQueue();
  }

  void dispose() {}

  /// Add a folder backup job to the appropriate queue
  Future<void> queueJob({
    required BackupFolder folder,
    required String scheduleId,
    required String triggerSource,
    String queueType = 'normal',
  }) async {
    final duplicate = state.any((j) =>
        j.folderId == folder.id &&
        (j.status == 'pending' || j.status == 'running' || j.status == 'paused'));
    if (duplicate) return;

    final job = ScheduledBackupJob(
      id: '${DateTime.now().millisecondsSinceEpoch}_${folder.id}',
      folderId: folder.id,
      scheduleId: scheduleId,
      folderName: folder.name,
      sourcePath: folder.sourcePath,
      destinationPath: folder.destinationPath,
      queueType: queueType,
      status: 'pending',
      createdAt: DateTime.now(),
      triggerSource: triggerSource,
    );

    state = [...state, job];
    await _persistQueue();
    _processQueue();
  }

  /// Pause a running or pending job
  Future<void> pauseJob(String jobId) async {
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(status: 'paused') else j
    ];
    await _persistQueue();
  }

  /// Resume a paused job
  Future<void> resumeJob(String jobId) async {
    state = [
      for (final j in state)
        if (j.id == jobId && j.status == 'paused') j.copyWith(status: 'pending') else j
    ];
    await _persistQueue();
    _processQueue();
  }

  /// Cancel/Remove a job
  Future<void> cancelJob(String jobId) async {
    state = state.where((j) => j.id != jobId).toList();
    await _persistQueue();
  }

  /// Process the queued jobs
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (true) {
      final pendingJobs = state.where((j) => j.status == 'pending').toList();
      if (pendingJobs.isEmpty) break;

      pendingJobs.sort((a, b) {
        final order = {'priority': 0, 'normal': 1, 'background': 2, 'retry': 3};
        final priorityA = order[a.queueType] ?? 99;
        final priorityB = order[b.queueType] ?? 99;
        if (priorityA != priorityB) return priorityA.compareTo(priorityB);
        return a.createdAt.compareTo(b.createdAt);
      });

      final nextJob = pendingJobs.first;
      await _runFolderBackup(nextJob);
    }

    _isProcessing = false;
  }

  /// Run actual backup of a folder
  Future<void> _runFolderBackup(ScheduledBackupJob job) async {
    final currentJobIndex = state.indexWhere((j) => j.id == job.id);
    if (currentJobIndex == -1 || state[currentJobIndex].status != 'pending') return;

    state = [
      for (final j in state)
        if (j.id == job.id) j.copyWith(status: 'running', startedAt: DateTime.now()) else j
    ];
    await _persistQueue();

    final startTime = DateTime.now();
    try {
      final folder = BackupFolder(
        id: job.folderId,
        name: job.folderName,
        sourcePath: job.sourcePath,
        destinationPath: job.destinationPath,
        enabled: true,
        createdAt: DateTime.now(),
        backupInterval: 'manual',
      );

      final workflow = ref.read(backupWorkflowProvider);
      await workflow.run(folder);

      await _waitForFolderCompletion(job.folderId);

      final duration = DateTime.now().difference(startTime);
      final historyItem = ScheduleHistory(
        id: job.id,
        executionTime: startTime,
        duration: duration,
        trigger: job.triggerSource,
        result: 'success',
        retryCount: job.retryCount,
        workerUsed: 'BackupEngine',
        status: 'completed',
      );

      await _repository.addHistory(historyItem);

      state = [
        for (final j in state)
          if (j.id == job.id)
            j.copyWith(
              status: 'completed',
              queueType: 'completed',
              completedAt: DateTime.now(),
              progress: 1.0,
            )
          else
            j
      ];
      await _persistQueue();
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      final errorStr = e.toString();

      if (job.retryCount < 3) {
        state = [
          for (final j in state)
            if (j.id == job.id)
              j.copyWith(
                status: 'pending',
                queueType: 'retry',
                retryCount: j.retryCount + 1,
                error: 'Error: $errorStr (Attempt ${j.retryCount + 1} failed)',
              )
            else
              j
        ];
        await _persistQueue();
      } else {
        final historyItem = ScheduleHistory(
          id: job.id,
          executionTime: startTime,
          duration: duration,
          trigger: job.triggerSource,
          result: 'failed',
          retryCount: job.retryCount,
          workerUsed: 'BackupEngine',
          status: 'failed',
          errors: errorStr,
        );

        await _repository.addHistory(historyItem);

        state = [
          for (final j in state)
            if (j.id == job.id)
              j.copyWith(
                status: 'failed',
                queueType: 'failed',
                completedAt: DateTime.now(),
                error: errorStr,
              )
            else
              j
        ];
        await _persistQueue();
      }
    }
  }

  Future<void> _waitForFolderCompletion(int folderId) async {
    final completer = Completer<void>();
    Timer? checkTimer;

    checkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final activeFileJobs = ref.read(copyQueueProvider);
      final activeForFolder = activeFileJobs.any(
        (j) => j.folderId == folderId && (j.status == CopyStatus.pending || j.status == CopyStatus.copying),
      );

      if (!activeForFolder) {
        checkTimer?.cancel();
        completer.complete();
      }
    });

    await completer.future;
  }

  void _updateProgressFromCopyQueue(List<CopyJob> coreJobs) {
    if (state.isEmpty) return;

    final foldersToUpdate = state.where((j) => j.status == 'running').toList();
    if (foldersToUpdate.isEmpty) return;

    bool changed = false;
    final updatedList = state.map((job) {
      if (job.status == 'running') {
        final folderId = job.folderId;
        final folderJobs = coreJobs.where((j) => j.folderId == folderId).toList();
        if (folderJobs.isNotEmpty) {
          final totalCount = folderJobs.length;

          double sumProgress = 0;
          for (final fJob in folderJobs) {
            if (fJob.status == CopyStatus.completed) {
              sumProgress += 1.0;
            } else if (fJob.status == CopyStatus.copying) {
              sumProgress += fJob.progress;
            }
          }
          final calculatedProgress = sumProgress / totalCount;
          if ((calculatedProgress - job.progress).abs() > 0.01) {
            changed = true;
            return job.copyWith(progress: calculatedProgress);
          }
        }
      }
      return job;
    }).toList();

    if (changed) {
      state = updatedList;
    }
  }

  Future<void> _persistQueue() async {
    final activeQueue = state
        .where((j) => j.status == 'pending' || j.status == 'running' || j.status == 'paused')
        .map((e) => e.toJson())
        .toList();
    await _repository.savePendingJobs(activeQueue);
  }

  List<ScheduledBackupJob> get jobs => state;

  List<ScheduledBackupJob> getPriorityQueue() => state.where((j) => j.queueType == 'priority').toList();
  List<ScheduledBackupJob> getNormalQueue() => state.where((j) => j.queueType == 'normal').toList();
  List<ScheduledBackupJob> getBackgroundQueue() => state.where((j) => j.queueType == 'background').toList();
  List<ScheduledBackupJob> getRetryQueue() => state.where((j) => j.queueType == 'retry').toList();
  List<ScheduledBackupJob> getFailedQueue() => state.where((j) => j.queueType == 'failed').toList();
  List<ScheduledBackupJob> getCompletedQueue() => state.where((j) => j.queueType == 'completed').toList();
  List<ScheduledBackupJob> getPendingQueue() => state.where((j) => j.status == 'pending').toList();

  void clearCompletedJobs() {
    state = state
        .where((j) => j.status != 'completed' && j.status != 'failed')
        .toList();
    _persistQueue();
  }
}
