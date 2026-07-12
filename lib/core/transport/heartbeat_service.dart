// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';
import 'secure_channel.dart';
import 'transport_models.dart';

class HeartbeatService {
  final SecureChannel _channel;
  final Function() _onTimeout;
  final Function(String message)? _onLog;

  Timer? _pingTimer;
  int _missedAcks = 0;
  bool _isRunning = false;

  static const int pingIntervalSeconds = 5;
  static const int maxMissedPings = 3;

  // ignore: use_initializing_formals
  HeartbeatService(
    this._channel, {
    required void Function() onTimeout,
    void Function(String message)? onLog,
  })  : _onTimeout = onTimeout,
        _onLog = onLog;

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _missedAcks = 0;

    _pingTimer = Timer.periodic(const Duration(seconds: pingIntervalSeconds), (timer) {
      _sendPing();
    });
  }

  void stop() {
    _isRunning = false;
    _pingTimer?.cancel();
  }

  Future<void> _sendPing() async {
    if (!_isRunning) return;

    if (_missedAcks >= maxMissedPings) {
      _log('Heartbeat timeout: missed $_missedAcks pings.');
      stop();
      _onTimeout();
      return;
    }

    try {
      _missedAcks++;
      await _channel.sendSecurePacket(
        PacketType.heartbeat,
        Uint8List.fromList([0]),
        sessionId: 'heartbeat',
      );
    } catch (e) {
      _log('Failed to send heartbeat ping: $e');
      stop();
      _onTimeout();
    }
  }

  Future<void> handleHeartbeat(TransportPacket packet) async {
    if (!_isRunning) return;
    // Reply with ack
    try {
      await _channel.sendSecurePacket(
        PacketType.heartbeatAck,
        Uint8List.fromList([0]),
        sessionId: 'heartbeat',
        packetIndex: packet.packetIndex,
      );
    } catch (_) {}
  }

  void handleHeartbeatAck() {
    if (!_isRunning) return;
    _missedAcks = 0; // Reset counter on successful ack
  }

  void _log(String msg) {
    if (_onLog != null) {
      _onLog(msg);
    }
  }
}
