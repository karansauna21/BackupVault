// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../services/logging_service.dart';

class NetworkScanner {
  static const int broadcastPort = 8323;
  final LoggingService _logger;
  final String _deviceId;
  final String _deviceName;
  final String _platform;
  final String _appVersion;
  final int _transportPort;

  RawDatagramSocket? _socket;
  bool _isListening = false;
  final StreamController<Map<String, dynamic>> _broadcastDeviceController = StreamController.broadcast();
  Timer? _broadcastTimer;

  Stream<Map<String, dynamic>> get onDeviceDiscovered => _broadcastDeviceController.stream;

  NetworkScanner({
    required LoggingService logger,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String appVersion,
    required int transportPort,
  })  : _logger = logger,
        _deviceId = deviceId,
        _deviceName = deviceName,
        _platform = platform,
        _appVersion = appVersion,
        _transportPort = transportPort;

  Future<void> start() async {
    if (_isListening) return;

    try {
      // Bind to any address to receive broadcast packets
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
        reusePort: true,
      );

      _socket!.broadcastEnabled = true;
      _isListening = true;

      _logger.info('NetworkScanner', 'Started UDP Broadcast listener on port $broadcastPort');

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handleBroadcastPacket(datagram.data, datagram.address.address);
          }
        }
      });

      // Start periodic broadcasting
      startBroadcasting();
    } catch (e) {
      _logger.error('NetworkScanner', 'Failed to start UDP Broadcast scanner: $e');
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isListening = false;
    _logger.info('NetworkScanner', 'Stopped UDP Broadcast scanner');
  }

  void startBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      broadcastPresence();
    });
    broadcastPresence(); // Initial broadcast
  }

  Future<void> broadcastPresence() async {
    if (_socket == null) return;

    try {
      final payload = {
        'id': _deviceId,
        'name': _deviceName,
        'platform': _platform,
        'version': _appVersion,
        'port': _transportPort,
        'status': 'Online',
        'capabilities': ['Transport', 'Backup'],
        'type': 'presence'
      };
      
      final data = utf8.encode(json.encode(payload));
      
      // Send to global broadcast address
      _socket!.send(data, InternetAddress('255.255.255.255'), broadcastPort);

      // Also list local network interfaces to target interface broadcast addresses specifically
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ipParts = addr.address.split('.');
          if (ipParts.length == 4) {
            // Estimate subnet broadcast address (e.g. 192.168.1.255)
            final subnetBroadcast = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.255';
            _socket!.send(data, InternetAddress(subnetBroadcast), broadcastPort);
          }
        }
      }
    } catch (e) {
      _logger.warning('NetworkScanner', 'Error sending broadcast ping: $e');
    }
  }

  void _handleBroadcastPacket(Uint8List data, String senderIp) {
    try {
      final decoded = json.decode(utf8.decode(data)) as Map<String, dynamic>;
      if (decoded['id'] == _deviceId) return; // Skip ourselves

      if (decoded['type'] == 'presence') {
        _broadcastDeviceController.add({
          'id': decoded['id'] as String,
          'name': decoded['name'] as String,
          'platform': decoded['platform'] as String,
          'version': decoded['version'] as String? ?? '1.0.0',
          'ip': senderIp,
          'port': decoded['port'] as int? ?? _transportPort,
          'capabilities': List<String>.from(decoded['capabilities'] as List? ?? ['Transport']),
          'status': decoded['status'] as String? ?? 'Online',
        });
      }
    } catch (_) {
      // Ignore malformed broadcast traffic from other applications
    }
  }

  /// Pings a specific IP and port using TCP connection handshake (Manual Entry Check)
  Future<bool> pingAddress(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 1500));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Estimates the current connection type (Wi-Fi, Ethernet, Hotspot, Local Router)
  Future<String> getCurrentConnectionType() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('wi-fi') || name.contains('wifi')) {
          return 'Wi-Fi';
        }
        if (name.contains('eth') || name.contains('ethernet')) {
          return 'Ethernet';
        }
        if (name.contains('ap') || name.contains('hotspot')) {
          return 'Personal Hotspot';
        }
      }
    } catch (_) {}
    return 'Wi-Fi'; // Default fallback
  }
}
