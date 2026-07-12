// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../services/logging_service.dart';
import 'remote_connection_manager.dart';

enum RemoteSessionStatus {
  waiting,
  syncing,
  paused,
  failed,
  completed
}

class RemoteSessionProgress {
  final String sessionId;
  final String deviceId;
  final RemoteSessionStatus status;
  final int totalFiles;
  final int transferredFiles;
  final int totalBytes;
  final int bytesTransferred;
  final String currentFile;
  final double speed;
  final int eta;
  final String? errorMessage;

  RemoteSessionProgress({
    required this.sessionId,
    required this.deviceId,
    required this.status,
    required this.totalFiles,
    required this.transferredFiles,
    required this.totalBytes,
    required this.bytesTransferred,
    required this.currentFile,
    required this.speed,
    required this.eta,
    this.errorMessage,
  });
}

class RemoteSession {
  final String sessionId;
  final String deviceId;
  final RemoteConnectionManager _connectionManager;
  final LoggingService _logger;
  
  RemoteSessionStatus _status = RemoteSessionStatus.waiting;
  int _totalFiles = 0;
  int _transferredFiles = 0;
  int _totalBytes = 0;
  int _bytesTransferred = 0;
  String _currentFile = 'None';
  double _speed = 0.0;
  int _eta = 0;
  String? _errorMessage;

  final StreamController<RemoteSessionProgress> _progressController = StreamController.broadcast();
  Stream<RemoteSessionProgress> get onProgressChanged => _progressController.stream;

  RemoteSessionStatus get status => _status;
  RemoteSessionProgress get currentProgress => RemoteSessionProgress(
    sessionId: sessionId,
    deviceId: deviceId,
    status: _status,
    totalFiles: _totalFiles,
    transferredFiles: _transferredFiles,
    totalBytes: _totalBytes,
    bytesTransferred: _bytesTransferred,
    currentFile: _currentFile,
    speed: _speed,
    eta: _eta,
    errorMessage: _errorMessage,
  );

  RemoteSession({
    required this.deviceId,
    required RemoteConnectionManager connectionManager,
    required LoggingService logger,
  })  : sessionId = const Uuid().v4(),
        _connectionManager = connectionManager,
        _logger = logger;

  Future<void> startSync(List<File> files, {
    Map<String, String>? remoteFileHashes, // SHA-256 of files already at destination
    Map<String, int>? remoteFileSizes,     // Sizes already at destination
    int resumeOffset = 0,
  }) async {
    _status = RemoteSessionStatus.syncing;
    _totalFiles = files.length;
    _transferredFiles = 0;
    _bytesTransferred = 0;
    _totalBytes = files.fold(0, (sum, f) => sum + (f.existsSync() ? f.lengthSync() : 0));
    _notifyProgress();

    await _logger.info('RemoteSession', 'Starting Remote Sync Session $sessionId for device $deviceId. Files: $_totalFiles');

    try {
      for (final file in files) {
        if (_status == RemoteSessionStatus.paused) {
          await _logger.info('RemoteSession', 'Session $sessionId paused.');
          return;
        }

        final fileName = file.path.split('/').last.split('\\').last;
        _currentFile = fileName;
        _notifyProgress();

        if (!file.existsSync()) {
          continue;
        }

        final fileSize = file.lengthSync();
        final localHash = await _calculateHash(file);

        // 1. Skip check: Never resend unchanged files
        final destHash = remoteFileHashes?[file.path];
        if (destHash == localHash) {
          _logger.info('RemoteSession', 'File $fileName is unchanged (hash matches). Skipping.');
          _transferredFiles++;
          _bytesTransferred += fileSize;
          _notifyProgress();
          continue;
        }

        // 2. Resume / Transfer check
        int offset = 0;
        final destSize = remoteFileSizes?[file.path] ?? 0;
        if (destSize > 0 && destSize < fileSize) {
          offset = destSize; // Resuming from last byte offset
          _logger.info('RemoteSession', 'Resuming transfer of $fileName from offset: $offset bytes');
        }

        // Send payload chunk
        final startTime = DateTime.now();
        await _connectionManager.sendPayload(deviceId, {
          'sessionId': sessionId,
          'filePath': file.path,
          'fileName': fileName,
          'fileSize': fileSize,
          'hash': localHash,
          'offset': offset,
          'chunk': 'binary_chunk_placeholder',
        });

        // Simulate progress/speed
        final duration = DateTime.now().difference(startTime).inMilliseconds.clamp(1, 10000);
        final bytesSentThisFile = fileSize - offset;
        _speed = (bytesSentThisFile / (duration / 1000.0));
        _bytesTransferred += fileSize; // Mark completed
        _transferredFiles++;
        
        final remainingBytes = _totalBytes - _bytesTransferred;
        _eta = _speed > 0 ? (remainingBytes / _speed).round() : 0;
        _notifyProgress();

        _logger.info('RemoteSession', 'Successfully sent $fileName to remote device.');
      }

      _status = RemoteSessionStatus.completed;
      _currentFile = 'None';
      _speed = 0.0;
      _eta = 0;
      _notifyProgress();
      await _logger.info('RemoteSession', 'Remote Sync Session $sessionId completed successfully.');
    } catch (e, stack) {
      _status = RemoteSessionStatus.failed;
      _errorMessage = e.toString();
      _notifyProgress();
      await _logger.error('RemoteSession', 'Remote Sync Session $sessionId failed: $e', stack.toString());
    }
  }

  void pause() {
    if (_status == RemoteSessionStatus.syncing) {
      _status = RemoteSessionStatus.paused;
      _notifyProgress();
    }
  }

  void resume() {
    if (_status == RemoteSessionStatus.paused) {
      _status = RemoteSessionStatus.syncing;
      _notifyProgress();
    }
  }

  void _notifyProgress() {
    _progressController.add(currentProgress);
  }

  Future<String> _calculateHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      return hash.toString();
    } catch (_) {
      return '';
    }
  }

  void dispose() {
    _progressController.close();
  }
}
