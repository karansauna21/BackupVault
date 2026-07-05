import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupJob {
  final String id;
  final int folderId;
  final String sourcePath;
  final String destinationPath;
  final String relativePath;
  final int retryCount;
  final String status; // 'pending', 'running', 'completed', 'failed'
  final double progress;
  final String? error;

  BackupJob({
    required this.id,
    required this.folderId,
    required this.sourcePath,
    required this.destinationPath,
    required this.relativePath,
    this.retryCount = 0,
    this.status = 'pending',
    this.progress = 0.0,
    this.error,
  });

  BackupJob copyWith({
    int? retryCount,
    String? status,
    double? progress,
    String? error,
  }) {
    return BackupJob(
      id: id,
      folderId: folderId,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      relativePath: relativePath,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

class QueueManager extends Notifier<List<BackupJob>> {
  bool _isProcessing = false;
  Future<void> Function(BackupJob job, void Function(double progress) onProgress)? _jobExecutor;
  void Function(BackupJob job)? _onJobCompleted;
  void Function(BackupJob job, String error)? _onJobFailed;

  @override
  List<BackupJob> build() {
    return [];
  }

  void configure({
    required Future<void> Function(BackupJob job, void Function(double progress) onProgress) executor,
    void Function(BackupJob job)? onJobCompleted,
    void Function(BackupJob job, String error)? onJobFailed,
  }) {
    _jobExecutor = executor;
    _onJobCompleted = onJobCompleted;
    _onJobFailed = onJobFailed;
  }

  void queueJob(BackupJob job) {
    state = [...state, job];
    _processQueue();
  }

  void queueJobs(List<BackupJob> jobs) {
    state = [...state, ...jobs];
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _jobExecutor == null) return;
    _isProcessing = true;

    while (true) {
      final index = state.indexWhere((j) => j.status == 'pending');
      if (index == -1) break;

      final job = state[index];
      await _runJob(index, job);
    }

    _isProcessing = false;
  }

  Future<void> _runJob(int index, BackupJob job) async {
    _updateJobStatus(job.id, 'running', 0.0);

    try {
      await _jobExecutor!(job, (progress) {
        _updateJobProgress(job.id, progress);
      });

      _updateJobStatus(job.id, 'completed', 1.0);
      _onJobCompleted?.call(state.firstWhere((j) => j.id == job.id));
    } catch (e) {
      final errorStr = e.toString();
      if (job.retryCount < 3) {
        state = [
          for (final j in state)
            if (j.id == job.id)
              j.copyWith(
                status: 'pending',
                retryCount: j.retryCount + 1,
                error: 'Error: $errorStr (Attempt ${j.retryCount + 1} failed)',
              )
            else
              j
        ];
      } else {
        _updateJobStatus(job.id, 'failed', job.progress, errorStr);
        _onJobFailed?.call(state.firstWhere((j) => j.id == job.id), errorStr);
      }
    }
  }

  void _updateJobStatus(String id, String status, double progress, [String? error]) {
    state = [
      for (final j in state)
        if (j.id == id) j.copyWith(status: status, progress: progress, error: error) else j
    ];
  }

  void _updateJobProgress(String id, double progress) {
    state = [
      for (final j in state)
        if (j.id == id) j.copyWith(progress: progress) else j
    ];
  }

  void clearCompletedJobs() {
    state = state.where((j) => j.status != 'completed').toList();
  }

  void resetFailedJobs() {
    state = [
      for (final j in state)
        if (j.status == 'failed') j.copyWith(status: 'pending', retryCount: 0, error: null) else j
    ];
    _processQueue();
  }

  void pauseQueue() {
    state = [
      for (final j in state)
        if (j.status == 'pending') j.copyWith(status: 'paused') else j
    ];
  }

  void resumeQueue() {
    state = [
      for (final j in state)
        if (j.status == 'paused') j.copyWith(status: 'pending') else j
    ];
    _processQueue();
  }
}

final queueManagerProvider = NotifierProvider<QueueManager, List<BackupJob>>(() {
  return QueueManager();
});
