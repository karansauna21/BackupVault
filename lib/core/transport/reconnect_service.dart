import 'dart:async';
import 'dart:io';
import 'secure_channel.dart';

class ReconnectService {
  final String targetIp;
  final int port;
  final String pairingToken;
  final String selfDeviceId;
  final Function(SecureChannel newChannel) onReconnected;
  final Function() onReconnectFailed;
  final Function(String message)? onLog;

  int _retryCount = 0;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  static const int maxRetries = 6;
  static const List<int> delays = [2, 4, 8, 16, 30, 30];

  ReconnectService({
    required this.targetIp,
    required this.port,
    required this.pairingToken,
    required this.selfDeviceId,
    required this.onReconnected,
    required this.onReconnectFailed,
    this.onLog,
  });

  bool get isReconnecting => _isReconnecting;

  void start() {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _retryCount = 0;
    _scheduleNextAttempt();
  }

  void stop() {
    _isReconnecting = false;
    _reconnectTimer?.cancel();
  }

  void _scheduleNextAttempt() {
    if (!_isReconnecting) return;

    if (_retryCount >= maxRetries) {
      _log('Max reconnection attempts reached. Failing connection.');
      _isReconnecting = false;
      onReconnectFailed();
      return;
    }

    final delay = delays[_retryCount];
    _log('Scheduling reconnect attempt ${_retryCount + 1}/$maxRetries in $delay seconds...');
    
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _attemptReconnect();
    });
  }

  Future<void> _attemptReconnect() async {
    if (!_isReconnecting) return;
    _log('Attempting reconnect to $targetIp:$port...');

    try {
      final socket = await Socket.connect(targetIp, port, timeout: const Duration(seconds: 5));
      _log('Socket reconnected. Establishing secure handshake...');

      // Setup secure channel
      final channel = SecureChannel(
        socket,
        pairingToken,
        isClient: true,
        selfDeviceId: selfDeviceId,
        onError: (err) {
          _log('Handshake error during reconnect: $err');
        },
      );

      // Wait up to 10 seconds for authentication to complete
      int elapsed = 0;
      while (!channel.isAuthenticated && elapsed < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        elapsed++;
      }

      if (channel.isAuthenticated) {
        _log('Reconnection & Handshake successful!');
        _isReconnecting = false;
        onReconnected(channel);
      } else {
        channel.close();
        _retryCount++;
        _scheduleNextAttempt();
      }
    } catch (e) {
      _log('Reconnection attempt failed: $e');
      _retryCount++;
      _scheduleNextAttempt();
    }
  }

  void _log(String msg) {
    if (onLog != null) {
      onLog!(msg);
    }
  }
}
