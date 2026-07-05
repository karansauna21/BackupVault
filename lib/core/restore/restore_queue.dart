import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'restore_job.dart';

class RestoreQueue extends Notifier<List<RestoreJob>> {
  bool _isQueuePaused = false;
  final Set<String> _cancelledJobIds = {};
  final Set<String> _pausedJobIds = {};

  @override
  List<RestoreJob> build() {
    return [];
  }

  bool isCancelled(String jobId) => _cancelledJobIds.contains(jobId);
  bool isPaused(String jobId) => _isQueuePaused || _pausedJobIds.contains(jobId);
  bool get isQueuePaused => _isQueuePaused;

  void addJob(RestoreJob job) {
    state = [...state, job];
  }

  void addJobs(List<RestoreJob> jobs) {
    state = [...state, ...jobs];
  }

  void pauseJob(String jobId) {
    _pausedJobIds.add(jobId);
    _updateJobStatus(jobId, RestoreStatus.paused);
  }

  void resumeJob(String jobId) {
    _pausedJobIds.remove(jobId);
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(status: RestoreStatus.pending) else j
    ];
  }

  void cancelJob(String jobId) {
    _cancelledJobIds.add(jobId);
    _updateJobStatus(jobId, RestoreStatus.canceled);
  }

  void pauseQueue() {
    _isQueuePaused = true;
    for (final job in state) {
      if (job.status == RestoreStatus.restoring) {
        _updateJobStatus(job.id, RestoreStatus.paused);
      }
    }
  }

  void resumeQueue() {
    _isQueuePaused = false;
    for (final job in state) {
      if (job.status == RestoreStatus.paused && !_pausedJobIds.contains(job.id)) {
        state = [
          for (final j in state)
            if (j.id == job.id) j.copyWith(status: RestoreStatus.pending) else j
        ];
      }
    }
  }

  void retryJob(String jobId) {
    _cancelledJobIds.remove(jobId);
    _pausedJobIds.remove(jobId);
    state = [
      for (final j in state)
        if (j.id == jobId)
          j.copyWith(
            status: RestoreStatus.pending,
            retryCount: 0,
            progress: 0.0,
            error: null,
          )
        else
          j
    ];
  }

  void updateJobProgress(String jobId, double progress) {
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(progress: progress) else j
    ];
  }

  void updateJobResult(
    String jobId,
    RestoreStatus status, {
    Duration? duration,
    DateTime? restoreTime,
    String? error,
    int? retryCount,
    String? targetRestorePath,
  }) {
    state = [
      for (final j in state)
        if (j.id == jobId)
          j.copyWith(
            status: status,
            duration: duration,
            restoreTime: restoreTime,
            error: error,
            retryCount: retryCount,
            targetRestorePath: targetRestorePath,
          )
        else
          j
    ];
  }

  void _updateJobStatus(String jobId, RestoreStatus status) {
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(status: status) else j
    ];
  }
}

final restoreQueueProvider = NotifierProvider<RestoreQueue, List<RestoreJob>>(() {
  return RestoreQueue();
});
