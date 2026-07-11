import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'bandwidth_manager.dart';
import 'packet_manager.dart';
import 'secure_channel.dart';
import 'transport_models.dart';

class TransferSession {
  final String sessionId;
  final SecureChannel channel;
  final BandwidthManager bandwidthManager;
  final PacketManager packetManager;
  final bool isSender;
  final String baseFolderPath;
  final Function(double progress, double speed, String currentFile)? onProgress;
  final Function(String message)? onLog;

  bool _isTransferring = false;
  final List<FileTransferItem> _queue = [];
  int _completedFiles = 0;
  int _totalBytes = 0;
  int _completedBytes = 0;

  Completer<int>? _ackCompleter;
  int _expectedAckIndex = -1;

  TransferSession({
    required this.sessionId,
    required this.channel,
    required this.bandwidthManager,
    required this.packetManager,
    required this.isSender,
    required this.baseFolderPath,
    this.onProgress,
    this.onLog,
  });

  bool get isTransferring => _isTransferring;
  int get completedFiles => _completedFiles;
  int get totalFiles => _queue.length;
  int get totalBytes => _totalBytes;
  int get completedBytes => _completedBytes;
  List<FileTransferItem> get queue => _queue;

  void addToQueue(String relativePath, int size) {
    _queue.add(FileTransferItem(relativePath: relativePath, size: size));
    _totalBytes += size;
  }

  // --- Sender Methods ---

  Future<void> startSend() async {
    if (!isSender || _isTransferring) return;
    _isTransferring = true;
    _completedFiles = 0;
    _completedBytes = 0;

    _log('Starting send session $sessionId with ${_queue.length} files...');

    // Notify session start
    final sessionStartPayload = utf8.encode(json.encode({
      'totalFiles': _queue.length,
      'totalBytes': _totalBytes,
    }));
    await channel.sendSecurePacket(
      PacketType.sessionStart,
      Uint8List.fromList(sessionStartPayload),
      sessionId: sessionId,
    );

    final stopwatch = Stopwatch()..start();

    for (final item in _queue) {
      if (!_isTransferring) break;
      await _sendFile(item);
      _completedFiles++;
    }

    stopwatch.stop();
    _isTransferring = false;

    // Notify session end
    await channel.sendSecurePacket(
      PacketType.sessionEnd,
      Uint8List(0),
      sessionId: sessionId,
    );
    _log('Send session $sessionId completed in ${stopwatch.elapsed.inSeconds} seconds.');
  }

  Future<void> _sendFile(FileTransferItem item) async {
    final file = File('$baseFolderPath/${item.relativePath}');
    if (!await file.exists()) {
      _log('Source file does not exist: ${file.path}');
      return;
    }

    _log('Preparing file: ${item.relativePath} (${item.size} bytes)');

    // 1. Calculate file SHA-256
    final stream = file.openRead();
    final digest = await sha256.bind(stream).single;
    final fileSha256 = digest.toString();

    // 2. Chunk file
    final chunks = await packetManager.chunkFile(file);
    final totalPackets = chunks.length;

    // 3. Send metadata and negotiate starting offset for Resume
    final metadataPayload = utf8.encode(json.encode({
      'relativePath': item.relativePath,
      'fileSize': item.size,
      'sha256': fileSha256,
      'totalPackets': totalPackets,
    }));

    _ackCompleter = Completer<int>();
    _expectedAckIndex = -100; // special code for metadata handshake

    await channel.sendSecurePacket(
      PacketType.fileMetadata,
      Uint8List.fromList(metadataPayload),
      sessionId: sessionId,
    );

    // Wait for receiver to tell us starting packetIndex to resume from
    final int startPacketIndex = await _ackCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => 0, // Fallback to start from beginning
    );

    _log('Sending ${item.relativePath} starting from packet index: $startPacketIndex/$totalPackets');

    final stopwatch = Stopwatch()..start();

    for (int i = startPacketIndex; i < totalPackets; i++) {
      if (!_isTransferring) break;

      final chunk = chunks[i];

      // Throttling
      await bandwidthManager.throttle(chunk.length);

      // Send chunk packet with retry logic
      bool chunkAcked = false;
      int retries = 0;

      while (!chunkAcked && retries < 3) {
        _ackCompleter = Completer<int>();
        _expectedAckIndex = i;

        await channel.sendSecurePacket(
          PacketType.fileData,
          chunk,
          sessionId: sessionId,
          packetIndex: i,
          totalPackets: totalPackets,
        );

        try {
          final ackedIndex = await _ackCompleter!.future.timeout(const Duration(seconds: 5));
          if (ackedIndex == i) {
            chunkAcked = true;
          }
        } catch (_) {
          retries++;
          _log('Packet index $i timed out. Retrying ($retries/3)...');
        }
      }

      if (!chunkAcked) {
        _log('Failed to send packet $i after 3 attempts. Aborting file transfer.');
        break;
      }

      _completedBytes += chunk.length;
      
      final elapsedSecs = stopwatch.elapsed.inMilliseconds / 1000.0;
      final speed = elapsedSecs > 0 ? _completedBytes / elapsedSecs : 0.0;
      final progress = _totalBytes > 0 ? _completedBytes / _totalBytes : 0.0;

      if (onProgress != null) {
        onProgress!(progress, speed, item.relativePath);
      }
    }
  }

  // --- Receiver/Sender Acknowledgment Packet Processing ---

  void handlePacket(TransportPacket packet) {
    if (packet.sessionId != sessionId) return;

    if (isSender) {
      // Sender receives ACKs/NACKs from receiver
      if (packet.type == PacketType.fileAck) {
        if (_expectedAckIndex == -100) {
          // Metadata negotiation start index response
          final payloadStr = utf8.decode(packet.payload);
          final startIdx = int.tryParse(payloadStr) ?? 0;
          _ackCompleter?.complete(startIdx);
        } else if (packet.packetIndex == _expectedAckIndex) {
          _ackCompleter?.complete(packet.packetIndex);
        }
      } else if (packet.type == PacketType.fileNack) {
        _log('NACK received for packet index: ${packet.packetIndex}');
        // Simply let the timeout trigger retry
      }
    } else {
      // Receiver receives session & file chunks
      _handleIncomingPacketAsReceiver(packet);
    }
  }

  Future<void> _handleIncomingPacketAsReceiver(TransportPacket packet) async {
    if (packet.type == PacketType.sessionStart) {
      final jsonMap = json.decode(utf8.decode(packet.payload)) as Map<String, dynamic>;
      _totalBytes = jsonMap['totalBytes'] as int;
      _completedBytes = 0;
      _isTransferring = true;
      _log('Receiver started session $sessionId. Expected bytes: $_totalBytes');
    } else if (packet.type == PacketType.fileMetadata) {
      final jsonMap = json.decode(utf8.decode(packet.payload)) as Map<String, dynamic>;
      final relativePath = jsonMap['relativePath'] as String;
      final fileSize = jsonMap['fileSize'] as int;
      final fileSha256 = jsonMap['sha256'] as String;
      final totalPackets = jsonMap['totalPackets'] as int;

      _log('Metadata received: $relativePath ($fileSize bytes)');

      // Conflict Resolution Logic
      var destFilePath = p.join(baseFolderPath, relativePath);
      final destFile = File(destFilePath);
      int startPacketIndex = 0;
      bool isIdentical = false;

      if (await destFile.exists()) {
        final existingSha = await _calculateFileSha256(destFile);
        if (existingSha == fileSha256) {
          _log('Identical file already exists: $destFilePath. Skipping transfer.');
          startPacketIndex = totalPackets;
          isIdentical = true;
        } else {
          // File modified: create new versioned path
          var version = 2;
          while (true) {
            final dir = p.dirname(destFilePath);
            final baseName = p.basenameWithoutExtension(destFilePath);
            final ext = p.extension(destFilePath);
            final candidatePath = p.join(dir, '${baseName}_v$version$ext');
            final candidateFile = File(candidatePath);
            if (!await candidateFile.exists()) {
              destFilePath = candidatePath;
              _log('Version conflict: Creating new version at $destFilePath');
              break;
            }
            final candidateSha = await _calculateFileSha256(candidateFile);
            if (candidateSha == fileSha256) {
              _log('Identical versioned file already exists: $candidatePath. Skipping.');
              destFilePath = candidatePath;
              startPacketIndex = totalPackets;
              isIdentical = true;
              break;
            }
            version++;
          }
        }
      }

      if (!isIdentical) {
        final partFile = File('$destFilePath.part');
        if (await partFile.exists()) {
          final currentPartSize = await partFile.length();
          startPacketIndex = currentPartSize ~/ PacketManager.chunkSize;
          if (startPacketIndex > 0) {
            final exactSize = startPacketIndex * PacketManager.chunkSize;
            if (currentPartSize != exactSize) {
              final access = await partFile.open(mode: FileMode.write);
              await access.truncate(exactSize);
              await access.close();
            }
          }
          _log('Partial file found. Resuming from packet index $startPacketIndex');
        }
      }

      // Initialize reassembly session
      packetManager.registerSession(
        sessionId,
        p.dirname(destFilePath),
        p.basename(destFilePath),
        p.relative(destFilePath, from: baseFolderPath),
        totalPackets,
        fileSha256,
      );

      // Reply with startPacketIndex
      final replyPayload = utf8.encode(startPacketIndex.toString());
      await channel.sendSecurePacket(
        PacketType.fileAck,
        Uint8List.fromList(replyPayload),
        sessionId: sessionId,
      );
    } else if (packet.type == PacketType.fileData) {
      // Process chunk packet
      await packetManager.processIncomingDataPacket(
        packet,
        onPacketAck: (ackIdx) async {
          await channel.sendSecurePacket(
            PacketType.fileAck,
            Uint8List(0),
            sessionId: sessionId,
            packetIndex: ackIdx,
          );
        },
        onPacketNack: (nackIdx) async {
          await channel.sendSecurePacket(
            PacketType.fileNack,
            Uint8List(0),
            sessionId: sessionId,
            packetIndex: nackIdx,
          );
        },
        onProgress: (progress) {
          // File level progress
        },
        onCompleted: (filePath) {
          _log('File fully reassembled and verified: $filePath');
          _completedFiles++;
        },
        onError: (err) {
          _log('Packet reassembly error: $err');
        },
      );
    } else if (packet.type == PacketType.sessionEnd) {
      _isTransferring = false;
      _log('Receiver finished session $sessionId.');
    }
  }

  void cancel() {
    _isTransferring = false;
    _ackCompleter?.completeError(Exception('Session cancelled.'));
  }

  Future<String> _calculateFileSha256(File file) async {
    try {
      if (!await file.exists()) return '';
      final stream = file.openRead();
      final digest = await sha256.bind(stream).single;
      return digest.toString();
    } catch (_) {
      return '';
    }
  }

  void _log(String msg) {
    if (onLog != null) {
      onLog!(msg);
    }
  }
}

class FileTransferItem {
  final String relativePath;
  final int size;

  FileTransferItem({
    required this.relativePath,
    required this.size,
  });
}
