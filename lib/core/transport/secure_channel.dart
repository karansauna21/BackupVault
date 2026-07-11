import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';
import 'transport_models.dart';

class SecureChannel {
  final Socket _socket;
  final String _pairingToken;
  final bool isClient;
  final void Function(TransportPacket packet)? onPacketReceived;
  final void Function(String error)? onError;
  final void Function()? onDisconnected;

  bool _isAuthenticated = false;
  enc.Key? _sessionKey;
  int _lastRxPacketIndex = -1;
  int _lastRxTimestamp = 0;

  DateTime? _connectionTime;
  DateTime _lastActivityTime = DateTime.now();

  static const int sessionTimeoutSeconds = 60; // 1 minute inactivity timeout
  static const int connectionExpirationSeconds = 3600; // 1 hour connection life

  // Socket stream buffer
  final BytesBuilder _readBuffer = BytesBuilder();
  int _expectedPacketLength = -1;

  StreamSubscription? _socketSub;
  Timer? _securityTimer;

  String? _clientChallenge;
  String? _serverChallenge;

  SecureChannel(
    this._socket,
    this._pairingToken, {
    required this.isClient,
    this.onPacketReceived,
    this.onError,
    this.onDisconnected,
  }) {
    _connectionTime = DateTime.now();
    _socketSub = _socket.listen(
      _onData,
      onError: _onSocketError,
      onDone: _onSocketDone,
    );

    // Run security watchdog timer every 5 seconds
    _securityTimer = Timer.periodic(const Duration(seconds: 5), _checkSecurityRules);

    if (isClient) {
      _initiateHandshake();
    }
  }

  bool get isAuthenticated => _isAuthenticated;
  Socket get socket => _socket;

  // --- Handshake Implementation ---

  void _initiateHandshake() {
    _clientChallenge = const Uuid().v4();
    final packet = TransportPacket(
      sessionId: 'handshake',
      type: PacketType.handshakeChallenge,
      packetIndex: 0,
      totalPackets: 1,
      payloadLength: _clientChallenge!.length,
      payload: Uint8List.fromList(utf8.encode(_clientChallenge!)),
      checksum: sha256.convert(utf8.encode(_clientChallenge!)).toString(),
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    _sendPacketDirect(packet);
  }

  void _handleHandshakeChallenge(TransportPacket packet) {
    if (isClient) return;

    _clientChallenge = utf8.decode(packet.payload);
    _serverChallenge = const Uuid().v4();

    // Derive Session Key: sha256(pairingToken + clientChallenge + serverChallenge)
    final keyBytes = sha256.convert(utf8.encode(_pairingToken + _clientChallenge! + _serverChallenge!)).bytes;
    _sessionKey = enc.Key(Uint8List.fromList(keyBytes));

    // Sign client challenge to prove server knows pairing token
    final signature = sha256.convert(utf8.encode(_pairingToken + _clientChallenge!)).toString();
    final responsePayload = '$_serverChallenge|$signature';

    final responsePacket = TransportPacket(
      sessionId: 'handshake',
      type: PacketType.handshakeResponse,
      packetIndex: 0,
      totalPackets: 1,
      payloadLength: responsePayload.length,
      payload: Uint8List.fromList(utf8.encode(responsePayload)),
      checksum: sha256.convert(utf8.encode(responsePayload)).toString(),
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );

    _sendPacketDirect(responsePacket);
  }

  void _handleHandshakeResponse(TransportPacket packet) {
    if (!isClient) return;

    final parts = utf8.decode(packet.payload).split('|');
    if (parts.length != 2) {
      _failConnection('Malformed handshake response');
      return;
    }

    _serverChallenge = parts[0];
    final serverSignature = parts[1];

    // Verify server identity
    final expectedSignature = sha256.convert(utf8.encode(_pairingToken + _clientChallenge!)).toString();
    if (serverSignature != expectedSignature) {
      _failConnection('Server authentication failed (Signature Mismatch)');
      return;
    }

    // Derive Session Key
    final keyBytes = sha256.convert(utf8.encode(_pairingToken + _clientChallenge! + _serverChallenge!)).bytes;
    _sessionKey = enc.Key(Uint8List.fromList(keyBytes));

    // Sign server challenge to prove client knows pairing token
    final clientSignature = sha256.convert(utf8.encode(_pairingToken + _serverChallenge!)).toString();

    final verifyPacket = TransportPacket(
      sessionId: 'handshake',
      type: PacketType.authVerify,
      packetIndex: 0,
      totalPackets: 1,
      payloadLength: clientSignature.length,
      payload: Uint8List.fromList(utf8.encode(clientSignature)),
      checksum: sha256.convert(utf8.encode(clientSignature)).toString(),
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );

    _sendPacketDirect(verifyPacket);
    _isAuthenticated = true;
  }

  void _handleAuthVerify(TransportPacket packet) {
    if (isClient) return;

    final clientSignature = utf8.decode(packet.payload);
    final expectedSignature = sha256.convert(utf8.encode(_pairingToken + _serverChallenge!)).toString();

    if (clientSignature != expectedSignature) {
      _failConnection('Client authentication failed (Signature Mismatch)');
      return;
    }

    _isAuthenticated = true;
  }

  // --- Encryption/Decryption ---

  Uint8List _encrypt(Uint8List plainBytes) {
    if (_sessionKey == null) return plainBytes;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_sessionKey!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);
    
    // Packet ciphertext = IV (16 bytes) + ciphertext bytes
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.takeBytes();
  }

  Uint8List _decrypt(Uint8List cipherBytes) {
    if (_sessionKey == null) return cipherBytes;
    if (cipherBytes.length < 16) throw Exception('Ciphertext too short');
    
    final ivBytes = cipherBytes.sublist(0, 16);
    final encryptedBytes = cipherBytes.sublist(16);
    
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(_sessionKey!, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
    
    return Uint8List.fromList(decrypted);
  }

  // --- Packet Transmission ---

  Future<void> sendSecurePacket(PacketType type, Uint8List payload, {String sessionId = 'session', int packetIndex = 0, int totalPackets = 1}) async {
    if (!_isAuthenticated) {
      throw Exception('Channel not authenticated');
    }

    // 1. Calculate payload SHA-256 for integrity
    final checksum = sha256.convert(payload).toString();

    // 2. Encrypt payload
    final encryptedPayload = _encrypt(payload);

    // 3. Build Packet
    final packet = TransportPacket(
      sessionId: sessionId,
      type: type,
      packetIndex: packetIndex,
      totalPackets: totalPackets,
      payloadLength: encryptedPayload.length,
      payload: encryptedPayload,
      checksum: checksum,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );

    _sendPacketDirect(packet);
  }

  void _sendPacketDirect(TransportPacket packet) {
    try {
      final jsonMap = packet.toJson();
      final jsonString = json.encode(jsonMap);
      final jsonBytes = utf8.encode(jsonString);

      // Prepend packet frame size (4 bytes, Big Endian)
      final lengthBytes = ByteData(4)..setInt32(0, jsonBytes.length, Endian.big);
      _socket.add(lengthBytes.buffer.asUint8List());
      _socket.add(jsonBytes);
      
      _lastActivityTime = DateTime.now();
    } catch (e) {
      _failConnection('Socket write error: $e');
    }
  }

  // --- Socket Stream Receiver & Packet Framing ---

  void _onData(Uint8List data) {
    _readBuffer.add(data);
    _processReadBuffer();
  }

  void _processReadBuffer() {
    while (true) {
      final bytes = _readBuffer.toBytes();
      if (_expectedPacketLength == -1) {
        if (bytes.length < 4) return;
        final sizeBytes = bytes.sublist(0, 4);
        final byteData = ByteData.sublistView(Uint8List.fromList(sizeBytes));
        _expectedPacketLength = byteData.getInt32(0, Endian.big);
        // Remove length bytes from buffer
        final remaining = bytes.sublist(4);
        _readBuffer.clear();
        _readBuffer.add(remaining);
      }

      final bytes2 = _readBuffer.toBytes();
      if (bytes2.length < _expectedPacketLength) return;

      final packetBytes = bytes2.sublist(0, _expectedPacketLength);
      // Remove packet bytes from buffer
      final remaining = bytes2.sublist(_expectedPacketLength);
      _readBuffer.clear();
      _readBuffer.add(remaining);
      _expectedPacketLength = -1;

      try {
        final jsonString = utf8.decode(packetBytes);
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final packet = TransportPacket.fromJson(jsonMap);
        _handleIncomingPacket(packet);
      } catch (e) {
        _failConnection('Packet decoding failed: $e');
        return;
      }
    }
  }

  void _handleIncomingPacket(TransportPacket packet) {
    _lastActivityTime = DateTime.now();

    // 1. Replay attack protection (indexes & timestamps must increase for data/payload packets)
    if (_isAuthenticated && packet.type != PacketType.heartbeat && packet.type != PacketType.heartbeatAck) {
      if (packet.packetIndex <= _lastRxPacketIndex && packet.timestampMs <= _lastRxTimestamp) {
        _failConnection('Replay attack detected: packet index or timestamp is stale');
        return;
      }
      _lastRxPacketIndex = packet.packetIndex;
      _lastRxTimestamp = packet.timestampMs;
    }

    // 2. Handshake handling
    if (packet.type == PacketType.handshakeChallenge) {
      _handleHandshakeChallenge(packet);
      return;
    } else if (packet.type == PacketType.handshakeResponse) {
      _handleHandshakeResponse(packet);
      return;
    } else if (packet.type == PacketType.authVerify) {
      _handleAuthVerify(packet);
      return;
    }

    // 3. Normal packet processing (needs decryption)
    if (!_isAuthenticated) {
      _failConnection('Received secure packet before authentication');
      return;
    }

    try {
      final decryptedPayload = _decrypt(packet.payload);
      
      // Verify integrity checksum
      final calcChecksum = sha256.convert(decryptedPayload).toString();
      if (calcChecksum != packet.checksum) {
        _failConnection('Integrity mismatch: Payload checksum verification failed');
        return;
      }

      final decryptedPacket = TransportPacket(
        sessionId: packet.sessionId,
        type: packet.type,
        packetIndex: packet.packetIndex,
        totalPackets: packet.totalPackets,
        payloadLength: decryptedPayload.length,
        payload: decryptedPayload,
        checksum: packet.checksum,
        timestampMs: packet.timestampMs,
      );

      if (onPacketReceived != null) {
        onPacketReceived!(decryptedPacket);
      }
    } catch (e) {
      _failConnection('Decryption / Verification failed: $e');
    }
  }

  // --- Security Rules & Watchdogs ---

  void _checkSecurityRules(Timer timer) {
    final now = DateTime.now();

    // 1. Inactivity timeout
    if (now.difference(_lastActivityTime).inSeconds > sessionTimeoutSeconds) {
      _failConnection('Session timeout due to inactivity');
      return;
    }

    // 2. Connection life expiration
    if (_connectionTime != null && now.difference(_connectionTime!).inSeconds > connectionExpirationSeconds) {
      _failConnection('Connection expired (Max lifetime 1 hour reached)');
      return;
    }
  }

  // --- Connection Termination ---

  void _failConnection(String reason) {
    if (onError != null) {
      onError!(reason);
    }
    close();
  }

  void _onSocketError(Object error) {
    _failConnection('Socket error: $error');
  }

  void _onSocketDone() {
    close();
    if (onDisconnected != null) {
      onDisconnected!();
    }
  }

  void close() {
    _securityTimer?.cancel();
    _socketSub?.cancel();
    try {
      _socket.destroy();
    } catch (_) {}
  }
}
