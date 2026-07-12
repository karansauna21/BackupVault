// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'secure_channel.dart';
import 'transport_models.dart';

class ConnectionService {
  final String? _pairingToken;
  final FutureOr<String?> Function(String remoteDeviceId)? _tokenResolver;
  final String _selfDeviceId;
  Function(SecureChannel channel)? onNewSecureChannel;
  final Function(String message)? onLog;
  final void Function(SecureChannel channel, TransportPacket packet)? onPacketReceived;

  ServerSocket? _serverSocket;
  final List<SecureChannel> _activeChannels = [];
  bool _isListening = false;

  static const int defaultPort = 8322;

  ConnectionService(
    this._selfDeviceId, {
    String? pairingToken,
    FutureOr<String?> Function(String remoteDeviceId)? tokenResolver,
    this.onNewSecureChannel,
    this.onLog,
    this.onPacketReceived,
  })  : _pairingToken = pairingToken,
        _tokenResolver = tokenResolver;

  bool get isListening => _isListening;
  List<SecureChannel> get activeChannels => List.unmodifiable(_activeChannels);

  Future<void> startListening({int port = defaultPort}) async {
    if (_isListening) return;

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _isListening = true;
      _log('Connection Server listening on port $port');

      _serverSocket!.listen((socket) {
        final remoteIp = socket.remoteAddress.address;
        _log('Accepted raw connection from $remoteIp:${socket.remotePort}');
        
        late final SecureChannel channel;
        channel = SecureChannel(
          socket,
          _pairingToken,
          isClient: false,
          selfDeviceId: _selfDeviceId,
          tokenResolver: _tokenResolver,
          onError: (err) {
            _log('Server channel security error: $err');
          },
          onDisconnected: () {
            _log('Server channel from $remoteIp disconnected.');
            _activeChannels.removeWhere((c) => c.socket == socket);
          },
          onPacketReceived: (packet) {
            onPacketReceived?.call(channel, packet);
          },
        );

        _activeChannels.add(channel);

        // Wait for handshake to finish, then notify
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (channel.isAuthenticated) {
            timer.cancel();
            _log('Server channel authenticated successfully.');
            if (onNewSecureChannel != null) {
              onNewSecureChannel!(channel);
            }
          }
          if (timer.tick > 100) { // 10 seconds timeout
            timer.cancel();
            if (!channel.isAuthenticated) {
              _log('Server channel authentication timed out. Closing.');
              channel.close();
              _activeChannels.remove(channel);
            }
          }
        });
      });
    } catch (e) {
      _log('Failed to start connection server: $e');
      rethrow;
    }
  }

  Future<SecureChannel> connectToDevice(String targetIp, {int port = defaultPort}) async {
    _log('Connecting client socket to $targetIp:$port...');
    final socket = await Socket.connect(targetIp, port, timeout: const Duration(seconds: 10));
    _log('Raw socket connected to $targetIp:$port. Establishing SecureChannel...');

    late final SecureChannel channel;
    channel = SecureChannel(
      socket,
      _pairingToken,
      isClient: true,
      selfDeviceId: _selfDeviceId,
      onError: (err) {
        _log('Client channel security error: $err');
      },
      onDisconnected: () {
        _log('Client channel to $targetIp disconnected.');
        _activeChannels.removeWhere((c) => c.socket == socket);
      },
      onPacketReceived: (packet) {
        onPacketReceived?.call(channel, packet);
      },
    );

    _activeChannels.add(channel);

    // Wait for handshake to complete
    int elapsed = 0;
    while (!channel.isAuthenticated && elapsed < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      elapsed++;
    }

    if (channel.isAuthenticated) {
      _log('Client channel authenticated successfully to $targetIp');
      return channel;
    } else {
      channel.close();
      _activeChannels.remove(channel);
      throw Exception('Secure handshake verification timed out.');
    }
  }

  Future<void> stop() async {
    _isListening = false;
    await _serverSocket?.close();
    _serverSocket = null;
    
    for (final channel in List.from(_activeChannels)) {
      channel.close();
    }
    _activeChannels.clear();
    _log('Connection Server stopped.');
  }

  void _log(String msg) {
    if (onLog != null) {
      onLog!(msg);
    }
  }
}
