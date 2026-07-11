import 'dart:io';

class CopyWorker {
  final String workerId;

  CopyWorker({required this.workerId});

  Future<void> copy({
    required String sourcePath,
    required String destinationPath,
    required void Function(double progress, double speed) onUpdate,
    required bool Function() isCancelled,
    required bool Function() isPaused,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    final destFile = File(destinationPath);
    await destFile.parent.create(recursive: true);

    final totalSize = await sourceFile.length();
    if (totalSize == 0) {
      await destFile.writeAsBytes(const []);
      onUpdate(1.0, 0.0);
      return;
    }

    int bytesCopied = 0;
    IOSink? destSink;
    Stream<List<int>>? sourceStream;

    // Check for resumable chunk
    if (await destFile.exists()) {
      final destSize = await destFile.length();
      if (destSize > 0 && destSize < totalSize) {
        bytesCopied = destSize;
        destSink = destFile.openWrite(mode: FileMode.append);
        sourceStream = sourceFile.openRead(destSize);
      }
    }

    if (destSink == null || sourceStream == null) {
      destSink = destFile.openWrite(mode: FileMode.write);
      sourceStream = sourceFile.openRead();
    }

    final stopwatch = Stopwatch()..start();
    int lastCheckBytes = bytesCopied;
    int lastCheckTimeMs = stopwatch.elapsedMilliseconds;

    try {
      await for (final chunk in sourceStream) {
        while (isPaused()) {
          await Future.delayed(const Duration(milliseconds: 100));
          lastCheckTimeMs = stopwatch.elapsedMilliseconds;
          lastCheckBytes = bytesCopied;
        }

        if (isCancelled()) {
          throw Exception('Copy job cancelled');
        }

        destSink.add(chunk);
        bytesCopied += chunk.length;

        final currentTimeMs = stopwatch.elapsedMilliseconds;
        final elapsedMs = currentTimeMs - lastCheckTimeMs;
        double speed = 0.0;
        if (elapsedMs >= 500) {
          final copiedDelta = bytesCopied - lastCheckBytes;
          speed = (copiedDelta / elapsedMs) * 1000;
          lastCheckBytes = bytesCopied;
          lastCheckTimeMs = currentTimeMs;
        }

        final progress = bytesCopied / totalSize;
        onUpdate(progress, speed);
      }

      await destSink.flush();
    } finally {
      await destSink.close();
      stopwatch.stop();
    }

    try {
      final mtime = await sourceFile.lastModified();
      await destFile.setLastModified(mtime);
    } catch (_) {}
  }
}
