import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/services/logging_service.dart';
import '../transport/secure_channel.dart';
import '../transport/transport_manager.dart';
import '../transport/transport_models.dart';
import 'transfer_protocol.dart';
import 'transfer_repository.dart';

class TransferSession {
  final String sessionId;
  final String deviceId;
  final SecureChannel channel;
  final bool isSender;
  final String baseFolderPath;
  final int chunkSize; // default 4MB
  final TransferRepository repository;
  final LoggingService logger;
  final TransportManager transportManager;

  final List<FileTransfer> _queue = [];
  bool _isTransferring = false;
  bool _isPaused = false;
  bool _isCancelled = false;

  int _completedBytes = 0;
  int _totalBytes = 0;
  int _completedFiles = 0;
  
  Completer<V2Packet>? _responseCompleter;

  // Progress and state callbacks
  final void Function(double progress, double speed, String currentFile, int remainingBytes, double etaSeconds)? onProgress;
  void Function(String status)? onStateChanged;

  String _sessionState = 'Pending';
  String get sessionState => _sessionState;

  TransferSession({
    required this.sessionId,
    required this.deviceId,
    required this.channel,
    required this.isSender,
    required this.baseFolderPath,
    this.chunkSize = 4 * 1024 * 1024, // 4MB
    required this.repository,
    required this.logger,
    required this.transportManager,
    this.onProgress,
    this.onStateChanged,
  });

  bool get isTransferring => _isTransferring;
  bool get isPaused => _isPaused;
  bool get isCancelled => _isCancelled;
  int get completedFiles => _completedFiles;
  int get totalFiles => _queue.length;
  int get totalBytes => _totalBytes;
  int get completedBytes => _completedBytes;
  List<FileTransfer> get queue => _queue;

  void addToQueue(FileTransfer transfer) {
    _queue.add(transfer);
    _totalBytes += transfer.fileSize;
  }

  void start() {
    _isTransferring = true;
    _isPaused = false;
    _isCancelled = false;
    
    // Register packet listener on the TransportManager for this sessionId
    transportManager.registerPacketListener(sessionId, _onPacketReceived);
    
    if (isSender) {
      unawaited(_runSenderLoop());
    } else {
      _sessionState = 'Listening';
      if (onStateChanged != null) onStateChanged!('Listening');
    }
  }

  void pause() {
    _isPaused = true;
    _sessionState = 'Paused';
    if (onStateChanged != null) onStateChanged!('Paused');
  }

  void resume() {
    _isPaused = false;
    _sessionState = 'Running';
    if (onStateChanged != null) onStateChanged!('Running');
  }

  void cancel() {
    _isCancelled = true;
    _isTransferring = false;
    _sessionState = 'Cancelled';
    _responseCompleter?.completeError(Exception('Session Cancelled'));
    transportManager.unregisterPacketListener(sessionId);
    if (onStateChanged != null) onStateChanged!('Cancelled');
  }

  void _onPacketReceived(dynamic transportPacket) {
    try {
      final jsonMap = json.decode(utf8.decode(transportPacket.payload)) as Map<String, dynamic>;
      final v2Packet = V2Packet.fromJson(jsonMap);
      
      if (!isSender && _isTransferring) {
        unawaited(_handleReceiverPacket(v2Packet));
      } else {
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(v2Packet);
        }
      }
    } catch (e, stack) {
      logger.error('TransferSession', 'Error handling incoming packet: $e', stack.toString());
    }
  }

  // --- Sender Protocol Loop ---
  Future<void> _runSenderLoop() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _sessionState = 'Handshake';
      if (onStateChanged != null) onStateChanged!('Handshake');
      await logger.info('TransferSession', 'V2 Handshake initiating for session $sessionId');

      // Handshake
      final handshakePacket = V2Packet(
        type: V2PacketType.handshake,
        sessionId: sessionId,
        index: 0,
        total: 0,
        payload: Uint8List.fromList(utf8.encode(json.encode({'chunkSize': chunkSize}))),
        checksum: V2Packet.calculateChecksum(Uint8List(0)),
      );
      await _sendV2Packet(handshakePacket);
      
      await _waitForResponse(V2PacketType.handshake);
      await logger.info('TransferSession', 'V2 Handshake confirmed by receiver');
      
      _sessionState = 'SessionStart';
      if (onStateChanged != null) onStateChanged!('SessionStart');
      // Send Session Start
      final startPacket = V2Packet(
        type: V2PacketType.sessionStart,
        sessionId: sessionId,
        index: 0,
        total: _queue.length,
        payload: Uint8List.fromList(utf8.encode(json.encode({
          'totalBytes': _totalBytes,
          'totalFiles': _queue.length,
        }))),
        checksum: V2Packet.calculateChecksum(Uint8List(0)),
      );
      await _sendV2Packet(startPacket);
      await _waitForResponse(V2PacketType.sessionStart);

      _sessionState = 'Transferring';
      if (onStateChanged != null) onStateChanged!('Transferring');
      
      for (final transfer in _queue) {
        if (_isCancelled) break;
        while (_isPaused) {
          await Future.delayed(const Duration(milliseconds: 200));
        }

        await _transferSingleFile(transfer, stopwatch);
        _completedFiles++;
      }

      if (!_isCancelled) {
        _sessionState = 'Completed';
        if (onStateChanged != null) onStateChanged!('Completed');
        final endPacket = V2Packet(
          type: V2PacketType.sessionEnd,
          sessionId: sessionId,
          index: 0,
          total: 0,
          payload: Uint8List(0),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(endPacket);
      }
    } catch (e, stack) {
      await logger.error('TransferSession', 'Error during sender loop: $e', stack.toString());
      _sessionState = 'Failed';
      if (onStateChanged != null) onStateChanged!('Failed');
    } finally {
      stopwatch.stop();
      _isTransferring = false;
      transportManager.unregisterPacketListener(sessionId);
    }
  }

  Future<void> _transferSingleFile(FileTransfer transfer, Stopwatch stopwatch) async {
    final filePath = p.join(baseFolderPath, transfer.relativePath);
    final file = File(filePath);

    if (!await file.exists()) {
      await logger.error('TransferSession', 'File not found: $filePath');
      await repository.updateTransferProgress(transfer.id, 0, 'failed');
      return;
    }

    // 1. Send file metadata and get negotiated offset
    final fileSha256 = transfer.hash ?? await _calculateFileSha256(file);
    final totalChunks = (transfer.fileSize / chunkSize).ceil();

    await logger.info('TransferSession', 'V2 File Metadata: ${transfer.relativePath} ($totalChunks chunks)');

    final metadataPacket = V2Packet(
      type: V2PacketType.fileMetadata,
      sessionId: sessionId,
      fileId: transfer.id,
      index: 0,
      total: totalChunks,
      payload: Uint8List.fromList(utf8.encode(json.encode({
        'relativePath': transfer.relativePath,
        'fileSize': transfer.fileSize,
        'hash': fileSha256,
      }))),
      checksum: V2Packet.calculateChecksum(Uint8List(0)),
    );
    
    await _sendV2Packet(metadataPacket);
    final metaResponse = await _waitForResponse(V2PacketType.fileMetadata);
    
    final responsePayload = json.decode(utf8.decode(metaResponse.payload)) as Map<String, dynamic>;
    final int startOffset = responsePayload['offset'] as int? ?? 0;
    
    await logger.info('TransferSession', 'V2 Resuming file ${transfer.relativePath} from offset $startOffset');
    
    final raf = await file.open(mode: FileMode.read);
    int currentOffset = startOffset;
    
    try {
      while (currentOffset < transfer.fileSize) {
        if (_isCancelled) break;
        while (_isPaused) {
          await Future.delayed(const Duration(milliseconds: 200));
        }

        await raf.setPosition(currentOffset);
        final readLen = (transfer.fileSize - currentOffset) > chunkSize ? chunkSize : (transfer.fileSize - currentOffset);
        final data = await raf.read(readLen);
        final chunkIndex = currentOffset ~/ chunkSize;
        final chunkHash = V2Packet.calculateChecksum(data);

        final chunkPacket = V2Packet(
          type: V2PacketType.chunkData,
          sessionId: sessionId,
          fileId: transfer.id,
          index: chunkIndex,
          total: totalChunks,
          payload: data,
          checksum: chunkHash,
        );

        // Send chunk and retry if failed or SHA-256 mismatch
        bool chunkSent = false;
        int attempts = 0;
        
        while (!chunkSent && attempts < 3 && !_isCancelled) {
          attempts++;
          try {
            await _sendV2Packet(chunkPacket);
            final ack = await _waitForResponse(V2PacketType.chunkAck).timeout(const Duration(seconds: 15));
            
            if (ack.index == chunkIndex) {
              chunkSent = true;
            } else if (ack.type == V2PacketType.nack) {
              await logger.warning('TransferSession', 'NACK received for chunk $chunkIndex. Retrying ($attempts/3)...');
            }
          } catch (e) {
            await logger.warning('TransferSession', 'Chunk $chunkIndex timeout or error: $e. Retrying ($attempts/3)...');
          }
        }

        if (!chunkSent) {
          throw Exception('Failed to send chunk $chunkIndex after 3 attempts');
        }

        currentOffset += readLen;
        _completedBytes += readLen;

        // Calculate progress stats
        final double elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        final double speed = elapsedSeconds > 0 ? _completedBytes / elapsedSeconds : 0.0;
        final int remainingBytes = _totalBytes - _completedBytes;
        final double etaSeconds = speed > 0 ? remainingBytes / speed : 0.0;
        final double progressPercent = _totalBytes > 0 ? _completedBytes / _totalBytes : 0.0;

        if (onProgress != null) {
          onProgress!(progressPercent, speed, transfer.relativePath, remainingBytes, etaSeconds);
        }

        await repository.updateTransferProgress(transfer.id, currentOffset, 'transferring');
        await logger.info('TransferSession', 'V2 Chunk $chunkIndex sent successfully (${(progressPercent * 100).toInt()}% progress)');
      }

      if (!_isCancelled) {
        // Send file end & verify hash
        final verifyPacket = V2Packet(
          type: V2PacketType.fileCompleted,
          sessionId: sessionId,
          fileId: transfer.id,
          index: 0,
          total: 0,
          payload: Uint8List(0),
          checksum: fileSha256,
        );
        await _sendV2Packet(verifyPacket);
        await _waitForResponse(V2PacketType.fileCompleted);

        await repository.updateTransferProgress(
          transfer.id,
          transfer.fileSize,
          'completed',
          completedAt: DateTime.now(),
        );
        await logger.info('TransferSession', 'V2 File complete & verified: ${transfer.relativePath}');
      }
    } finally {
      await raf.close();
    }
  }

  // --- Receiver Protocol Processing ---
  Future<void> _handleReceiverPacket(V2Packet packet) async {
    switch (packet.type) {
      case V2PacketType.handshake:
        final payload = json.decode(utf8.decode(packet.payload)) as Map<String, dynamic>;
        final senderChunkSize = payload['chunkSize'] as int? ?? chunkSize;
        
        await logger.info('TransferSession', 'Receiver: Handshake received from sender (chunkSize: $senderChunkSize)');
        
        final handshakeAck = V2Packet(
          type: V2PacketType.handshake,
          sessionId: sessionId,
          index: 0,
          total: 0,
          payload: Uint8List.fromList(utf8.encode(json.encode({'status': 'ok'}))),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(handshakeAck);
        break;

      case V2PacketType.sessionStart:
        final payload = json.decode(utf8.decode(packet.payload)) as Map<String, dynamic>;
        _totalBytes = payload['totalBytes'] as int? ?? 0;
        
        await logger.info('TransferSession', 'Receiver: Session started. Total expected size: $_totalBytes bytes');
        
        final sessionAck = V2Packet(
          type: V2PacketType.sessionStart,
          sessionId: sessionId,
          index: 0,
          total: 0,
          payload: Uint8List(0),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(sessionAck);
        break;

      case V2PacketType.fileMetadata:
        final payload = json.decode(utf8.decode(packet.payload)) as Map<String, dynamic>;
        final relativePath = payload['relativePath'] as String;
        final fileSize = payload['fileSize'] as int;
        final fileHash = payload['hash'] as String;

        await logger.info('TransferSession', 'Receiver: File metadata received for $relativePath ($fileSize bytes)');

        // Resolve conflict paths (never overwrite without versioning)
        String destFilePath = p.join(baseFolderPath, relativePath);
        final file = File(destFilePath);
        bool skipFile = false;

        if (await file.exists()) {
          final existingHash = await _calculateFileSha256(file);
          if (existingHash == fileHash) {
            await logger.info('TransferSession', 'Receiver: Identical file already exists. Skipping: $relativePath');
            skipFile = true;
          } else {
            // Version checking (e.g. filename_v2.ext)
            var version = 2;
            final dir = p.dirname(destFilePath);
            final baseName = p.basenameWithoutExtension(destFilePath);
            final ext = p.extension(destFilePath);
            
            while (true) {
              final candidatePath = p.join(dir, '${baseName}_v$version$ext');
              final candidateFile = File(candidatePath);
              if (!await candidateFile.exists()) {
                destFilePath = candidatePath;
                break;
              }
              final candidateHash = await _calculateFileSha256(candidateFile);
              if (candidateHash == fileHash) {
                await logger.info('TransferSession', 'Receiver: Identical versioned file already exists. Skipping: $candidatePath');
                destFilePath = candidatePath;
                skipFile = true;
                break;
              }
              version++;
            }
          }
        }

        int offset = 0;
        if (!skipFile) {
          // Prepare the directory structure
          await File(destFilePath).parent.create(recursive: true);
          
          final partFile = File('$destFilePath.part');
          if (await partFile.exists()) {
            offset = await partFile.length();
            // Truncate to match nearest chunk boundary
            final boundary = offset - (offset % chunkSize);
            if (boundary != offset) {
              offset = boundary;
              final opened = await partFile.open(mode: FileMode.write);
              await opened.truncate(offset);
              await opened.close();
            }
            await logger.info('TransferSession', 'Receiver: Found part file. Resuming from offset $offset');
          }
        } else {
          offset = fileSize; // Tells sender we are complete and to skip
        }

        // Store info in DB
        final fileName = p.basename(destFilePath);
        final transferRecord = FileTransfer(
          id: packet.fileId ?? const Uuid().v4(),
          sessionId: sessionId,
          fileName: fileName,
          relativePath: p.relative(destFilePath, from: baseFolderPath),
          fileSize: fileSize,
          hash: fileHash,
          status: skipFile ? 'completed' : 'transferring',
          transferredBytes: offset,
          startedAt: DateTime.now(),
        );
        await repository.saveTransfer(transferRecord);

        final metaAck = V2Packet(
          type: V2PacketType.fileMetadata,
          sessionId: sessionId,
          index: 0,
          total: 0,
          payload: Uint8List.fromList(utf8.encode(json.encode({'offset': offset}))),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(metaAck);
        break;

      case V2PacketType.chunkData:
        final transferRecord = await repository.getTransferById(packet.fileId!);
        if (transferRecord == null) {
          throw Exception('FileTransfer not initialized in database');
        }

        final destFilePath = p.join(baseFolderPath, transferRecord.relativePath);
        final partFile = File('$destFilePath.part');

        final expectedOffset = packet.index * chunkSize;

        // Verify SHA-256 integrity of the chunk
        final calculatedHash = V2Packet.calculateChecksum(packet.payload);
        if (calculatedHash != packet.checksum) {
          await logger.error('TransferSession', 'Receiver: Chunk index ${packet.index} SHA-256 mismatch! Rejecting...');
          final nack = V2Packet(
            type: V2PacketType.nack,
            sessionId: sessionId,
            index: packet.index,
            total: packet.total,
            payload: Uint8List(0),
            checksum: V2Packet.calculateChecksum(Uint8List(0)),
          );
          await _sendV2Packet(nack);
          return;
        }

        final raf = await partFile.open(mode: FileMode.write);
        await raf.setPosition(expectedOffset);
        await raf.writeFrom(packet.payload);
        await raf.close();

        final nextOffset = expectedOffset + packet.payload.length;
        _completedBytes += packet.payload.length;

        await repository.updateTransferProgress(transferRecord.id, nextOffset, 'transferring');
        
        final ack = V2Packet(
          type: V2PacketType.chunkAck,
          sessionId: sessionId,
          fileId: packet.fileId,
          index: packet.index,
          total: packet.total,
          payload: Uint8List(0),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(ack);
        break;

      case V2PacketType.fileCompleted:
        final transferRecord = await repository.getTransferById(packet.fileId!);
        if (transferRecord == null) {
          throw Exception('FileTransfer not initialized in database');
        }

        final destFilePath = p.join(baseFolderPath, transferRecord.relativePath);
        final partFile = File('$destFilePath.part');

        if (await partFile.exists()) {
          // Verify overall file checksum
          final fileHash = await _calculateFileSha256(partFile);
          if (fileHash != packet.checksum) {
            await logger.error('TransferSession', 'Receiver: Hash mismatch on reassembled file!');
            final nack = V2Packet(
              type: V2PacketType.nack,
              sessionId: sessionId,
              index: 0,
              total: 0,
              payload: Uint8List(0),
              checksum: V2Packet.calculateChecksum(Uint8List(0)),
            );
            await _sendV2Packet(nack);
            return;
          }

          // Rename .part file to final file
          await partFile.rename(destFilePath);
        }

        await repository.updateTransferProgress(
          transferRecord.id,
          transferRecord.fileSize,
          'completed',
          completedAt: DateTime.now(),
        );

        final completeAck = V2Packet(
          type: V2PacketType.fileCompleted,
          sessionId: sessionId,
          fileId: packet.fileId,
          index: 0,
          total: 0,
          payload: Uint8List(0),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(completeAck);
        break;

      case V2PacketType.sessionEnd:
        await logger.info('TransferSession', 'Receiver: Session $sessionId completed successfully');
        final endAck = V2Packet(
          type: V2PacketType.sessionEnd,
          sessionId: sessionId,
          index: 0,
          total: 0,
          payload: Uint8List(0),
          checksum: V2Packet.calculateChecksum(Uint8List(0)),
        );
        await _sendV2Packet(endAck);
        _isTransferring = false;
        transportManager.unregisterPacketListener(sessionId);
        _sessionState = 'Completed';
        if (onStateChanged != null) onStateChanged!('Completed');
        break;

      default:
        break;
    }
  }

  // --- Helper Methods ---
  Future<void> _sendV2Packet(V2Packet packet) async {
    final payloadBytes = Uint8List.fromList(utf8.encode(json.encode(packet.toJson())));
    await channel.sendSecurePacket(
      PacketType.fileData,
      payloadBytes,
      sessionId: sessionId,
    );
  }

  Future<V2Packet> _waitForResponse(V2PacketType expectedType) async {
    _responseCompleter = Completer<V2Packet>();
    final resp = await _responseCompleter!.future;
    if (resp.type != expectedType) {
      throw Exception('V2 Protocol Mismatch: Expected $expectedType, got ${resp.type}');
    }
    return resp;
  }

  Future<String> _calculateFileSha256(File file) async {
    if (!await file.exists()) return '';
    final stream = file.openRead();
    final digest = await sha256.bind(stream).single;
    return digest.toString();
  }
}
