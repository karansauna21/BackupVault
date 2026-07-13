import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/device_model.dart';
import 'logging_service.dart';

class ConnectionManager {
  final LoggingService _logger;
  
  // Real sockets
  RawDatagramSocket? _udpSendSocket;
  RawDatagramSocket? _udpReceiveSocket;
  ServerSocket? _tcpServer;
  
  // Active listeners
  StreamSubscription<RawSocketEvent>? _udpSubscription;
  final List<Socket> _activeTcpConnections = [];
  
  // Callbacks
  void Function(DeviceModel device)? onDeviceDiscovered;
  void Function(Map<String, dynamic> requestJson, Socket socket)? onPairingRequestReceived;
  
  // Port configuration
  static const int udpPort = 8320;
  static const int tcpPort = 8321;
  
  // Simulation flag for testing
  bool isSimulationMode = false;
  final StreamController<DeviceModel> _simulatedDiscoveryController = StreamController<DeviceModel>.broadcast();

  ConnectionManager(this._logger);

  Future<void> startDiscovery(DeviceModel selfDevice) async {
    if (isSimulationMode) {
      _simulatedDiscoveryController.stream.listen((device) {
        if (onDeviceDiscovered != null) {
          onDeviceDiscovered!(device);
        }
      });
      return;
    }

    try {
      // 1. Setup UDP socket for broadcasting
      _udpSendSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSendSocket?.broadcastEnabled = true;

      // Start periodic UDP broadcast timer
      Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_udpSendSocket == null) {
          timer.cancel();
          return;
        }
        _broadcastPresence(selfDevice);
      });

      // 2. Setup UDP socket for listening
      _udpReceiveSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort, reuseAddress: true);
      _udpReceiveSocket?.broadcastEnabled = true;
      
      _udpSubscription = _udpReceiveSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpReceiveSocket?.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            _handleDiscoveryMessage(message, datagram.address.address);
          }
        }
      });
      
      await _logger.info('DeviceManager', 'LAN Discovery started successfully on port $udpPort');
    } catch (e) {
      await _logger.warning('DeviceManager', 'LAN Discovery failed to start: $e');
    }
  }

  Future<void> startServer() async {
    if (isSimulationMode) {
      return;
    }

    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      _tcpServer?.listen((socket) {
        _activeTcpConnections.add(socket);
        socket.listen((data) {
          try {
            final message = utf8.decode(data);
            final jsonMap = json.decode(message) as Map<String, dynamic>;
            if (onPairingRequestReceived != null) {
              onPairingRequestReceived!(jsonMap, socket);
            }
          } catch (e) {
            _logger.error('DeviceManager', 'Error decoding TCP message: $e');
            socket.close();
          }
        }, onError: (err) {
          _activeTcpConnections.remove(socket);
          socket.close();
        }, onDone: () {
          _activeTcpConnections.remove(socket);
          socket.close();
        });
      });
      await _logger.info('DeviceManager', 'Pairing Server listening on TCP port $tcpPort');
    } catch (e) {
      await _logger.error('DeviceManager', 'Pairing Server failed to start: $e');
    }
  }

  void _broadcastPresence(DeviceModel selfDevice) {
    try {
      final payload = {
        'type': 'presence',
        'device': selfDevice.toJson(),
      };
      final data = utf8.encode(json.encode(payload));
      _udpSendSocket?.send(data, InternetAddress('255.255.255.255'), udpPort);
    } catch (_) {}
  }

  void _handleDiscoveryMessage(String message, String senderIp) {
    try {
      final payload = json.decode(message) as Map<String, dynamic>;
      if (payload['type'] == 'presence') {
        final deviceMap = payload['device'] as Map<String, dynamic>;
        deviceMap['ipAddress'] = senderIp; // Map the actual sender IP address
        
        final device = DeviceModel.fromJson(deviceMap);
        if (onDeviceDiscovered != null) {
          onDeviceDiscovered!(device);
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> sendPairingRequest(String targetIp, Map<String, dynamic> requestJson, {int? port}) async {
    if (isSimulationMode) {
      // Return simulated success response
      return {
        'type': 'pairing_response',
        'status': 'approved',
        'pairingToken': 'simulated_secure_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    Socket? socket;
    try {
      final targetPort = port ?? tcpPort;
      socket = await Socket.connect(targetIp, targetPort, timeout: const Duration(seconds: 10));
      final payload = json.encode(requestJson);
      socket.write(payload);
      await socket.flush();
      
      final completer = Completer<Map<String, dynamic>?>();
      socket.listen((data) {
        try {
          final message = utf8.decode(data);
          final response = json.decode(message) as Map<String, dynamic>;
          completer.complete(response);
        } catch (e) {
          completer.complete(null);
        }
      }, onError: (_) => completer.complete(null), onDone: () => completer.complete(null));

      return await completer.future.timeout(const Duration(seconds: 30), onTimeout: () => null);
    } catch (e) {
      await _logger.error('DeviceManager', 'Failed to connect/send pairing request to $targetIp: $e');
      return null;
    } finally {
      socket?.close();
    }
  }

  Future<void> respondToRequest(Socket socket, Map<String, dynamic> responseJson) async {
    try {
      socket.write(json.encode(responseJson));
      await socket.flush();
    } catch (e) {
      _logger.error('DeviceManager', 'Failed to send pairing response: $e');
    } finally {
      await socket.close();
    }
  }

  void stop() {
    _udpSubscription?.cancel();
    _udpReceiveSocket?.close();
    _udpSendSocket?.close();
    _tcpServer?.close();
    for (final conn in _activeTcpConnections) {
      conn.close();
    }
    _activeTcpConnections.clear();
  }

  // Simulation helpers for testing
  void simulateDiscovery(DeviceModel device) {
    _simulatedDiscoveryController.add(device);
  }
}
