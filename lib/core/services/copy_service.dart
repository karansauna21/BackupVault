import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/security/security_provider.dart';

class CopyService {
  final Ref? ref;
  CopyService([this.ref]);

  Future<void> copyFile({
    required String sourcePath,
    required String destinationPath,
    required void Function(double progress) onProgress,
    bool resume = true,
  }) async {
    final sourceFile = File(sourcePath);
    final destinationFile = File(destinationPath);

    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    if (ref != null) {
      final encManager = ref!.read(encryptionManagerProvider);
      if (encManager.isEncryptionActive) {
        final plainBytes = await sourceFile.readAsBytes();
        final encryptedBytes = encManager.encryptBytes(plainBytes);
        if (!await destinationFile.parent.exists()) {
          await destinationFile.parent.create(recursive: true);
        }
        await destinationFile.writeAsBytes(encryptedBytes);
        onProgress(1.0);
        return;
      }
    }

    final sourceSize = await sourceFile.length();
    if (sourceSize == 0) {
      // Empty file: create and exit
      if (!await destinationFile.parent.exists()) {
        await destinationFile.parent.create(recursive: true);
      }
      await destinationFile.writeAsBytes([]);
      onProgress(1.0);
      return;
    }

    // Spawn isolate for files larger than 5 MB to ensure multi-threaded execution
    const int multiThreadThreshold = 5 * 1024 * 1024;

    if (sourceSize > multiThreadThreshold) {
      await _copyFileMultiThreaded(
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        onProgress: onProgress,
        resume: resume,
      );
    } else {
      await _copyFileSingleThreaded(
        sourceFile: sourceFile,
        destinationFile: destinationFile,
        sourceSize: sourceSize,
        onProgress: onProgress,
        resume: resume,
      );
    }
  }

  Future<void> _copyFileSingleThreaded({
    required File sourceFile,
    required File destinationFile,
    required int sourceSize,
    required void Function(double progress) onProgress,
    required bool resume,
  }) async {
    if (!await destinationFile.parent.exists()) {
      await destinationFile.parent.create(recursive: true);
    }

    int bytesCopied = 0;
    if (resume && await destinationFile.exists()) {
      bytesCopied = await destinationFile.length();
      if (bytesCopied >= sourceSize) {
        onProgress(1.0);
        return;
      }
    }

    final sourceRaf = await sourceFile.open(mode: FileMode.read);
    final destRaf = await destinationFile.open(mode: FileMode.writeOnly);

    try {
      if (bytesCopied > 0) {
        await sourceRaf.setPosition(bytesCopied);
        await destRaf.setPosition(bytesCopied);
      }

      const int chunkSize = 1024 * 1024; // 1 MB chunk size
      final buffer = List<int>.filled(chunkSize, 0);

      while (bytesCopied < sourceSize) {
        final bytesRead = await sourceRaf.readInto(buffer);
        if (bytesRead <= 0) break;

        final dataToWrite = bytesRead == chunkSize ? buffer : buffer.sublist(0, bytesRead);
        await destRaf.writeFrom(dataToWrite);

        bytesCopied += bytesRead;
        onProgress(bytesCopied / sourceSize);
      }
    } finally {
      await sourceRaf.close();
      await destRaf.close();
    }
  }

  Future<void> _copyFileMultiThreaded({
    required String sourcePath,
    required String destinationPath,
    required void Function(double progress) onProgress,
    required bool resume,
  }) async {
    final receivePort = ReceivePort();
    
    final isolate = await Isolate.spawn(
      _isolateCopyEntryPoint,
      _CopyIsolateData(
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        sendPort: receivePort.sendPort,
        resume: resume,
      ),
    );

    final completer = Completer<void>();
    StreamSubscription? subscription;

    subscription = receivePort.listen((message) {
      if (message is double) {
        onProgress(message);
      } else if (message is String && message == 'SUCCESS') {
        subscription?.cancel();
        receivePort.close();
        isolate.kill(priority: Isolate.beforeNextEvent);
        completer.complete();
      } else if (message is Map<String, dynamic> && message['error'] != null) {
        subscription?.cancel();
        receivePort.close();
        isolate.kill(priority: Isolate.beforeNextEvent);
        completer.completeError(
          FileSystemException(
            message['error'].toString(),
            sourcePath,
          ),
        );
      }
    });

    return completer.future;
  }

  static void _isolateCopyEntryPoint(_CopyIsolateData data) async {
    final sourceFile = File(data.sourcePath);
    final destinationFile = File(data.destinationPath);

    try {
      if (!await destinationFile.parent.exists()) {
        await destinationFile.parent.create(recursive: true);
      }

      final sourceSize = await sourceFile.length();
      int bytesCopied = 0;

      if (data.resume && await destinationFile.exists()) {
        bytesCopied = await destinationFile.length();
        if (bytesCopied >= sourceSize) {
          data.sendPort.send(1.0);
          data.sendPort.send('SUCCESS');
          return;
        }
      }

      final sourceRaf = await sourceFile.open(mode: FileMode.read);
      final destRaf = await destinationFile.open(mode: FileMode.writeOnly);

      try {
        if (bytesCopied > 0) {
          await sourceRaf.setPosition(bytesCopied);
          await destRaf.setPosition(bytesCopied);
        }

        const int chunkSize = 1024 * 1024; // 1 MB chunk size
        final buffer = List<int>.filled(chunkSize, 0);

        while (bytesCopied < sourceSize) {
          final bytesRead = await sourceRaf.readInto(buffer);
          if (bytesRead <= 0) break;

          final dataToWrite = bytesRead == chunkSize ? buffer : buffer.sublist(0, bytesRead);
          await destRaf.writeFrom(dataToWrite);

          bytesCopied += bytesRead;
          data.sendPort.send(bytesCopied / sourceSize);
        }

        data.sendPort.send('SUCCESS');
      } finally {
        await sourceRaf.close();
        await destRaf.close();
      }
    } catch (e) {
      data.sendPort.send({'error': e.toString()});
    }
  }
}

class _CopyIsolateData {
  final String sourcePath;
  final String destinationPath;
  final SendPort sendPort;
  final bool resume;

  _CopyIsolateData({
    required this.sourcePath,
    required this.destinationPath,
    required this.sendPort,
    required this.resume,
  });
}

final copyServiceProvider = Provider<CopyService>((ref) {
  return CopyService(ref);
});
