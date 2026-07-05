import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'copy_job.dart';
import 'copy_queue.dart';
import 'storage_manager.dart';
import 'copy_engine.dart';

final activeJobsProvider = Provider<List<CopyJob>>((ref) {
  final queue = ref.watch(copyQueueProvider);
  return queue.where((j) => j.status == CopyStatus.copying).toList();
});

final remainingFilesProvider = Provider<int>((ref) {
  final queue = ref.watch(copyQueueProvider);
  return queue.where((j) => j.status == CopyStatus.pending || j.status == CopyStatus.copying).length;
});

final totalSpeedProvider = Provider<double>((ref) {
  final activeJobs = ref.watch(activeJobsProvider);
  return activeJobs.fold(0.0, (sum, j) => sum + j.speed);
});

final totalProgressProvider = Provider<double>((ref) {
  final queue = ref.watch(copyQueueProvider);
  final activeOrCompleted = queue
      .where((j) =>
          j.status == CopyStatus.copying ||
          j.status == CopyStatus.pending ||
          j.status == CopyStatus.completed)
      .toList();

  if (activeOrCompleted.isEmpty) return 0.0;

  final totalBytes = activeOrCompleted.fold<int>(0, (sum, j) => sum + j.fileSize);
  if (totalBytes == 0) return 0.0;

  final bytesCopied = activeOrCompleted.fold<double>(0.0, (sum, j) {
    if (j.status == CopyStatus.completed) return sum + j.fileSize;
    return sum + (j.fileSize * j.progress);
  });

  return bytesCopied / totalBytes;
});

final copyErrorsProvider = Provider<List<String>>((ref) {
  final queue = ref.watch(copyQueueProvider);
  return queue.where((j) => j.error != null).map((j) => j.error!).toList();
});

final destinationStorageProvider = FutureProvider.family<StorageInfo, String>((ref, path) async {
  final engine = ref.watch(copyEngineProvider);
  return engine.storageManager.getStorageInfo(path);
});
