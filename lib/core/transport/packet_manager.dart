import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'transport_models.dart';

class PacketManager {
  static const int chunkSize = 16384; // 16 KB packet chunks

  // Tracks active reassembly sessions
  // Map key: sessionId
  final Map<String, _ReassemblySession> _activeSessions = {};

  // --- Sender Side: Chunking ---

  Future<List<Uint8List>> chunkFile(File file) async {
    final List<Uint8List> chunks = [];
    final stream = file.openRead();
    
    await for (final chunk in stream) {
      chunks.add(Uint8List.fromList(chunk));
    }

    // Re-chunk to exact chunkSize if stream chunks are irregular
    final List<Uint8List> exactChunks = [];
    BytesBuilder currentBuilder = BytesBuilder();
    
    for (final rawChunk in chunks) {
      currentBuilder.add(rawChunk);
      while (currentBuilder.length >= chunkSize) {
        final fullData = currentBuilder.takeBytes();
        exactChunks.add(fullData.sublist(0, chunkSize));
        if (fullData.length > chunkSize) {
          currentBuilder.add(fullData.sublist(chunkSize));
        }
      }
    }
    if (currentBuilder.length > 0) {
      exactChunks.add(currentBuilder.takeBytes());
    }

    return exactChunks;
  }

  // --- Receiver Side: Reassembly ---

  void registerSession(String sessionId, String destFolderPath, String fileName, String relativePath, int totalPackets, String expectedSha256) {
    final destFilePath = p.join(destFolderPath, relativePath);
    final tempFilePath = '$destFilePath.part';
    
    int startIdx = 0;
    try {
      final file = File(tempFilePath);
      if (file.existsSync()) {
        startIdx = file.lengthSync() ~/ chunkSize;
      }
    } catch (_) {}

    _activeSessions[sessionId] = _ReassemblySession(
      sessionId: sessionId,
      destFilePath: destFilePath,
      tempFilePath: tempFilePath,
      totalPackets: totalPackets,
      expectedSha256: expectedSha256,
      nextExpectedIndex: startIdx,
    );
  }

  Future<void> cleanSession(String sessionId) async {
    final session = _activeSessions.remove(sessionId);
    if (session != null) {
      try {
        final file = File(session.tempFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<bool> processIncomingDataPacket(
    TransportPacket packet, {
    required Function(int ackIndex) onPacketAck,
    required Function(int nackIndex) onPacketNack,
    required Function(double progress) onProgress,
    required Function(String filePath) onCompleted,
    required Function(String error) onError,
  }) async {
    final session = _activeSessions[packet.sessionId];
    if (session == null) {
      onError('No active reassembly session for ID: ${packet.sessionId}');
      return false;
    }

    // 1. Verify packet checksum
    final calcChecksum = sha256.convert(packet.payload).toString();
    if (calcChecksum != packet.checksum) {
      onPacketNack(packet.packetIndex);
      return false;
    }

    // 2. Buffer out-of-order packets
    session.bufferedPackets[packet.packetIndex] = packet.payload;
    onPacketAck(packet.packetIndex);

    // 3. Write sequential buffered chunks to part file
    try {
      final file = File(session.tempFilePath);
      if (!await file.exists()) {
        await file.parent.create(recursive: true);
      }
      
      final accessFile = await file.open(mode: FileMode.writeOnlyAppend);

      while (session.bufferedPackets.containsKey(session.nextExpectedIndex)) {
        final payload = session.bufferedPackets.remove(session.nextExpectedIndex)!;
        await accessFile.writeFrom(payload);
        session.nextExpectedIndex++;
      }

      await accessFile.close();

      // Progress reporting
      final progress = session.nextExpectedIndex / session.totalPackets;
      onProgress(progress);

      // Check if reassembly completed
      if (session.nextExpectedIndex >= session.totalPackets) {
        _activeSessions.remove(packet.sessionId);
        
        // Verify final file hash
        final finalFile = File(session.tempFilePath);
        final stream = finalFile.openRead();
        final digest = await sha256.bind(stream).single;
        final actualSha256 = digest.toString();

        if (actualSha256 != session.expectedSha256) {
          try {
            await finalFile.delete();
          } catch (_) {}
          onError('File hash verification failed for: ${session.destFilePath}');
          return false;
        }

        // Rename part file to final file
        final destFile = File(session.destFilePath);
        if (await destFile.exists()) {
          await destFile.delete();
        }
        await finalFile.rename(session.destFilePath);

        onCompleted(session.destFilePath);
        return true;
      }
    } catch (e) {
      onError('File write error during packet reassembly: $e');
    }
    return false;
  }
}

class _ReassemblySession {
  final String sessionId;
  final String destFilePath;
  final String tempFilePath;
  final int totalPackets;
  final String expectedSha256;
  
  int nextExpectedIndex;
  final Map<int, Uint8List> bufferedPackets = {};

  _ReassemblySession({
    required this.sessionId,
    required this.destFilePath,
    required this.tempFilePath,
    required this.totalPackets,
    required this.expectedSha256,
    this.nextExpectedIndex = 0,
  });
}
