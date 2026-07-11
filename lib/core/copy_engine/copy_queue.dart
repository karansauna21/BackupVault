import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logging_service.dart';
import 'copy_job.dart';

class CopyQueue extends Notifier<List<CopyJob>> {
  bool _isQueuePaused = false;
  final Set<String> _cancelledJobIds = {};
  final Set<String> _pausedJobIds = {};

  @override
  List<CopyJob> build() {
    return [];
  }

  bool isCancelled(String jobId) => _cancelledJobIds.contains(jobId);
  bool isPaused(String jobId) => _isQueuePaused || _pausedJobIds.contains(jobId);
  bool get isQueuePaused => _isQueuePaused;

  void addJob(CopyJob job) {
    state = [...state, job];
  }

  void addJobs(List<CopyJob> jobs) {
    state = [...state, ...jobs];
  }

  void pauseJob(String jobId) {
    _pausedJobIds.add(jobId);
    _updateJobStatus(jobId, CopyStatus.paused);
  }

  void resumeJob(String jobId) {
    _pausedJobIds.remove(jobId);
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(status: CopyStatus.pending) else j
    ];
  }

  void cancelJob(String jobId) {
    _cancelledJobIds.add(jobId);
    _updateJobStatus(jobId, CopyStatus.canceled);
  }

  void pauseQueue() {
    _isQueuePaused = true;
    try {
      ref.read(loggingServiceProvider).info('CopyQueue', 'Backup queue paused.');
    } catch (_) {}
    for (final job in state) {
      if (job.status == CopyStatus.copying) {
        _updateJobStatus(job.id, CopyStatus.paused);
      }
    }
  }

  void resumeQueue() {
    _isQueuePaused = false;
    try {
      ref.read(loggingServiceProvider).info('CopyQueue', 'Backup queue resumed.');
    } catch (_) {}
    for (final job in state) {
      if (job.status == CopyStatus.paused && !_pausedJobIds.contains(job.id)) {
        state = [
          for (final j in state)
            if (j.id == job.id) j.copyWith(status: CopyStatus.pending) else j
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
            status: CopyStatus.pending,
            retryCount: 0,
            progress: 0.0,
            speed: 0.0,
            error: null,
          )
        else
          j
    ];
  }

  void updateJobProgress(String jobId, double progress, double speed) {
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(progress: progress, speed: speed) else j
    ];
  }

  void updateJobResult(
    String jobId,
    CopyStatus status, {
    String? sha256,
    Duration? duration,
    DateTime? backupTime,
    String? error,
    String? workerId,
    int? retryCount,
    String? destinationPath,
  }) {
    state = [
      for (final j in state)
        if (j.id == jobId)
          j.copyWith(
            status: status,
            sha256: sha256,
            duration: duration,
            backupTime: backupTime,
            error: error,
            workerId: workerId,
            retryCount: retryCount,
            destinationPath: destinationPath,
          )
        else
          j
    ];
  }

  void _updateJobStatus(String jobId, CopyStatus status) {
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(status: status) else j
    ];
  }
}

final copyQueueProvider = NotifierProvider<CopyQueue, List<CopyJob>>(() {
  return CopyQueue();
});
