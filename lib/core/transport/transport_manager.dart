import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../features/settings/settings_database.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import '../services/logging_service.dart';
import 'bandwidth_manager.dart';
import 'connection_service.dart';
import 'heartbeat_service.dart';
import 'packet_manager.dart';
import 'reconnect_service.dart';
import 'secure_channel.dart';
import 'transfer_session.dart';
import 'transport_models.dart';
import 'transport_repository.dart';

class TransportManager {
  final SettingsDatabase _db;
  final DeviceRepository _deviceRepository;
  final LoggingService _logger;

  late final TransportRepository _transportRepository;
  late final BandwidthManager _bandwidthManager;
  late final PacketManager _packetManager;
  ConnectionService? _connectionService;

  final Map<String, SecureChannel> _activeChannels = {};
  final Map<String, HeartbeatService> _activeHeartbeats = {};
  final Map<String, ReconnectService> _reconnectServices = {};
  final Map<String, TransferSession> _activeTransfers = {};

  final StreamController<TransportEvent> _eventController = StreamController<TransportEvent>.broadcast();

  TransportManager(this._db, this._deviceRepository, this._logger) {
    _transportRepository = TransportRepository(_db);
    _bandwidthManager = BandwidthManager();
    _packetManager = PacketManager();
  }

  Stream<TransportEvent> get eventStream => _eventController.stream;
  BandwidthManager get bandwidthManager => _bandwidthManager;
  TransportRepository get repository => _transportRepository;

  // --- Server Lifecycle ---

  Future<String?> _resolveTokenForDevice(String remoteDeviceId) async {
    final device = await _deviceRepository.getDeviceById(remoteDeviceId);
    return device?.pairingToken;
  }

  // --- Server Lifecycle ---

  Future<void> startServer([String? selfDevicePairingToken, int port = ConnectionService.defaultPort]) async {
    await _logger.info('TransportManager', 'Starting Secure Transport Server on port $port...');
    
    final selfDeviceId = _db.getValue('self_device_uuid') ?? 'default_self_id';

    _connectionService = ConnectionService(
      selfDeviceId,
      pairingToken: selfDevicePairingToken,
      tokenResolver: selfDevicePairingToken == null ? _resolveTokenForDevice : null,
      onNewSecureChannel: (channel) {
        _handleNewIncomingChannel(channel);
      },
      onLog: (msg) => _logger.info('ConnectionService', msg),
      onPacketReceived: (channel, packet) {
        final deviceId = _activeChannels.entries
            .firstWhere((e) => e.value == channel, orElse: () => MapEntry('', channel))
            .key;
        if (deviceId.isNotEmpty) {
          routePacket(deviceId, packet);
        }
      },
    );
    await _connectionService!.startListening(port: port);
  }

  Future<void> stopServer() async {
    await _connectionService?.stop();
    _connectionService = null;
    
    for (final channel in List.from(_activeChannels.values)) {
      channel.close();
    }
    _activeChannels.clear();

    for (final hb in _activeHeartbeats.values) {
      hb.stop();
    }
    _activeHeartbeats.clear();

    for (final rc in _reconnectServices.values) {
      rc.stop();
    }
    _reconnectServices.clear();
  }

  // --- Client Connection ---

  Future<SecureChannel> connectToDevice(DeviceModel device) async {
    final targetPort = device.port == 8321 ? 8322 : device.port;
    _logger.info('TransportManager', 'Connecting to device: ${device.name} (${device.ipAddress}:$targetPort)...');
    
    final repoDevice = await _deviceRepository.getDeviceById(device.id);
    final pairingToken = repoDevice?.pairingToken ?? device.pairingToken ?? _db.getValue('pairing_token_${device.id}') ?? 'default_token';
    final selfDeviceId = _db.getValue('self_device_uuid') ?? 'default_self_id';

    try {
      final socket = await Socket.connect(device.ipAddress, targetPort, timeout: const Duration(seconds: 10));
      _logger.info('TransportManager', 'Raw socket connected to ${device.ipAddress}:$targetPort. Establishing SecureChannel...');

      late final SecureChannel channel;
      channel = SecureChannel(
        socket,
        pairingToken,
        isClient: true,
        selfDeviceId: selfDeviceId,
        onError: (err) {
          _logger.error('TransportManager', 'Client channel security error: $err');
        },
        onDisconnected: () {
          _logger.info('TransportManager', 'Client channel to ${device.ipAddress} disconnected.');
          _activeChannels.removeWhere((id, c) => c == channel);
          _activeHeartbeats.remove(device.id)?.stop();
        },
        onPacketReceived: (packet) {
          routePacket(device.id, packet);
        },
      );

      // Wait for handshake to finish, then notify
      final completer = Completer<SecureChannel>();
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (channel.isAuthenticated) {
          timer.cancel();
          _logger.info('TransportManager', 'Client channel authenticated successfully.');
          _registerChannel(device.id, channel, device.ipAddress, device.port);
          completer.complete(channel);
        }
        if (timer.tick > 100) { // 10 seconds timeout
          timer.cancel();
          if (!channel.isAuthenticated) {
            _logger.error('TransportManager', 'Client channel authentication timed out.');
            channel.close();
            completer.completeError(TimeoutException('Authentication timed out'));
          }
        }
      });

      return await completer.future;
    } catch (e, stack) {
      await _logger.error('TransportManager', 'Connection to device ${device.name} failed: $e', stack.toString());
      await _recordError(device.id, 'ConnectionFailed', e.toString(), stack.toString());
      rethrow;
    }
  }

  // --- Channel Registration & Packet Processing ---

  void _handleNewIncomingChannel(SecureChannel channel) async {
    try {
      final remoteIp = channel.socket.remoteAddress.address;
      final remotePort = channel.socket.remotePort;
      final devices = await _deviceRepository.getDevices();
      final matchedDevice = devices.firstWhere(
        (d) => d.ipAddress == remoteIp,
        orElse: () => DeviceModel(
          id: 'unknown_device',
          name: 'Remote Device',
          platform: 'Unknown',
          osVersion: '1.0',
          appVersion: '1.0.0',
          deviceModel: 'Generic',
          pairingDate: DateTime.now(),
          lastSeen: DateTime.now(),
          trustStatus: 'Trusted',
          connectionStatus: 'Online',
          ipAddress: remoteIp,
          port: remotePort,
          storageInfo: 'Unknown',
        ),
      );

      _registerChannel(matchedDevice.id, channel, remoteIp, remotePort);
    } catch (_) {}
  }

  bool isDeviceConnected(String deviceId) {
    return _activeChannels.containsKey(deviceId);
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    final channel = _activeChannels[deviceId];
    if (channel == null) return;

    final ip = channel.socket.remoteAddress.address;
    final port = channel.socket.remotePort;

    _logger.info('TransportManager', 'Manually disconnecting device $deviceId');
    
    // Stop reconnect service to prevent infinite loop
    _reconnectServices.remove(deviceId)?.stop();

    _activeChannels.remove(deviceId)?.close();
    _activeHeartbeats.remove(deviceId)?.stop();

    // Log connection history
    final entry = ConnectionHistoryModel(
      id: const Uuid().v4(),
      deviceId: deviceId,
      timestamp: DateTime.now(),
      eventType: ConnectionEventType.disconnected,
      ipAddress: ip,
      port: port,
    );
    await _transportRepository.addConnectionHistoryEntry(entry);
    _eventController.add(TransportEvent(TransportEventType.disconnected, deviceId, message: 'Disconnected manually'));

    // Update device offline status in DeviceRepository
    try {
      final device = await _deviceRepository.getDeviceById(deviceId);
      if (device != null) {
        final updated = device.copyWith(connectionStatus: 'Offline');
        await _deviceRepository.addOrUpdateDevice(updated);
      }
    } catch (_) {}

    // Handle active transfer interruption
    for (final sessionId in _activeTransfers.keys) {
      final transfer = _activeTransfers[sessionId]!;
      if (transfer.channel.socket.remoteAddress.address == ip && transfer.isTransferring) {
        transfer.cancel();
        _logger.warning('TransportManager', 'Transfer session $sessionId interrupted due to disconnect.');
        
        final sessionModel = TransferSessionModel(
          id: sessionId,
          deviceId: deviceId,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: DateTime.now(),
          status: SessionStatus.interrupted,
          totalFiles: transfer.totalFiles,
          completedFiles: transfer.completedFiles,
          totalBytes: transfer.totalBytes,
          completedBytes: transfer.completedBytes,
          bandwidthLimit: _bandwidthManager.limit,
        );
        await _transportRepository.addOrUpdateSession(sessionModel);
        
        _eventController.add(TransportEvent(TransportEventType.transferInterrupted, deviceId, sessionId: sessionId));
      }
    }
  }

  void _registerChannel(String deviceId, SecureChannel channel, String ip, int port) async {
    // Clean old channel if present
    _activeChannels[deviceId]?.close();
    _activeChannels[deviceId] = channel;

    // Log connection history
    final entry = ConnectionHistoryModel(
      id: const Uuid().v4(),
      deviceId: deviceId,
      timestamp: DateTime.now(),
      eventType: ConnectionEventType.connected,
      ipAddress: ip,
      port: port,
    );
    await _transportRepository.addConnectionHistoryEntry(entry);
    _eventController.add(TransportEvent(TransportEventType.connected, deviceId, message: 'Connected to $ip:$port'));

    // Update device online status in DeviceRepository
    try {
      final device = await _deviceRepository.getDeviceById(deviceId);
      if (device != null) {
        final updated = device.copyWith(
          connectionStatus: 'Online',
          ipAddress: ip,
          port: port,
          lastSeen: DateTime.now(),
        );
        await _deviceRepository.addOrUpdateDevice(updated);
      }
    } catch (_) {}

    // Heartbeat
    final heartbeat = HeartbeatService(
      channel,
      onTimeout: () {
        _logger.warning('TransportManager', 'Heartbeat timeout for device: $deviceId');
        _handleDisconnect(deviceId, ip, port);
      },
      onLog: (msg) => _logger.info('HeartbeatService', msg),
    );
    heartbeat.start();
    _activeHeartbeats[deviceId] = heartbeat;

    // Setup packet routing
    channel.socket.done.then((_) => _handleDisconnect(deviceId, ip, port));
  }

  void routePacket(String deviceId, TransportPacket packet) {
    final hb = _activeHeartbeats[deviceId];
    if (packet.type == PacketType.heartbeat && hb != null) {
      hb.handleHeartbeat(packet);
    } else if (packet.type == PacketType.heartbeatAck && hb != null) {
      hb.handleHeartbeatAck();
    } else {
      final transfer = _activeTransfers[packet.sessionId];
      if (transfer != null) {
        transfer.handlePacket(packet);
      }
    }
  }

  void _handleDisconnect(String deviceId, String ip, int port) async {
    if (!_activeChannels.containsKey(deviceId)) return;

    _logger.warning('TransportManager', 'Disconnected from device: $deviceId');
    _activeChannels.remove(deviceId)?.close();
    _activeHeartbeats.remove(deviceId)?.stop();

    // Log connection history
    final entry = ConnectionHistoryModel(
      id: const Uuid().v4(),
      deviceId: deviceId,
      timestamp: DateTime.now(),
      eventType: ConnectionEventType.disconnected,
      ipAddress: ip,
      port: port,
    );
    await _transportRepository.addConnectionHistoryEntry(entry);
    _eventController.add(TransportEvent(TransportEventType.disconnected, deviceId, message: 'Disconnected'));

    // Update device offline status in DeviceRepository
    try {
      final device = await _deviceRepository.getDeviceById(deviceId);
      if (device != null) {
        final updated = device.copyWith(connectionStatus: 'Offline');
        await _deviceRepository.addOrUpdateDevice(updated);
      }
    } catch (_) {}

    // Handle active transfer interruption
    for (final sessionId in _activeTransfers.keys) {
      final transfer = _activeTransfers[sessionId]!;
      if (transfer.channel.socket.remoteAddress.address == ip && transfer.isTransferring) {
        transfer.cancel();
        _logger.warning('TransportManager', 'Transfer session $sessionId interrupted due to disconnect.');
        
        // Log interrupted session in database
        final sessionModel = TransferSessionModel(
          id: sessionId,
          deviceId: deviceId,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: DateTime.now(),
          status: SessionStatus.interrupted,
          totalFiles: transfer.totalFiles,
          completedFiles: transfer.completedFiles,
          totalBytes: transfer.totalBytes,
          completedBytes: transfer.completedBytes,
          bandwidthLimit: _bandwidthManager.limit,
        );
        await _transportRepository.addOrUpdateSession(sessionModel);
        
        _eventController.add(TransportEvent(TransportEventType.transferInterrupted, deviceId, sessionId: sessionId));
      }
    }

    // Start auto reconnection
    _startAutoReconnect(deviceId, ip, port);
  }

  void _startAutoReconnect(String deviceId, String ip, int port) async {
    if (_reconnectServices.containsKey(deviceId)) return;

    final devices = await _deviceRepository.getDevices();
    final index = devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) {
      _logger.warning('TransportManager', 'Device $deviceId not found in paired list. Skipping auto-reconnect.');
      return;
    }
    final matched = devices[index];
    final pairingToken = matched.pairingToken ?? _db.getValue('pairing_token_$deviceId') ?? 'default_token';

    final selfDeviceId = _db.getValue('self_device_uuid') ?? 'default_self_id';

    final reconnect = ReconnectService(
      targetIp: ip,
      port: port,
      pairingToken: pairingToken,
      selfDeviceId: selfDeviceId,
      onLog: (msg) => _logger.info('ReconnectService', msg),
      onReconnected: (newChannel) async {
        _logger.info('TransportManager', 'Reconnection successful for device: $deviceId');
        _reconnectServices.remove(deviceId)?.stop();
        _registerChannel(deviceId, newChannel, ip, port);

        // Resume interrupted transfers
        for (final sessionId in _activeTransfers.keys) {
          final transfer = _activeTransfers[sessionId]!;
          if (!transfer.isTransferring) {
            // Re-establish session over new channel
            final resumedSession = TransferSession(
              sessionId: sessionId,
              channel: newChannel,
              bandwidthManager: _bandwidthManager,
              packetManager: _packetManager,
              isSender: transfer.isSender,
              baseFolderPath: transfer.baseFolderPath,
              onLog: (msg) => _logger.info('TransferSession', msg),
              onProgress: (prog, speed, file) {
                _eventController.add(TransportEvent(
                  TransportEventType.transferProgress,
                  deviceId,
                  sessionId: sessionId,
                  progress: prog,
                  speed: speed,
                  message: file,
                ));
              },
            );

            // Copy queue items
            for (final item in transfer.queue) {
              resumedSession.addToQueue(item.relativePath, item.size);
            }
            
            _activeTransfers[sessionId] = resumedSession;
            
            // Start transfer
            if (resumedSession.isSender) {
              unawaited(resumedSession.startSend());
            }
            
            _eventController.add(TransportEvent(TransportEventType.transferResumed, deviceId, sessionId: sessionId));
          }
        }
      },
      onReconnectFailed: () {
        _logger.error('TransportManager', 'Reconnection failed permanently for device: $deviceId');
        _reconnectServices.remove(deviceId)?.stop();
      },
    );

    _reconnectServices[deviceId] = reconnect;
    reconnect.start();
  }

  // --- Transfer API ---

  Future<String> sendFolder(String deviceId, String sourceFolderPath, List<File> files) async {
    final channel = _activeChannels[deviceId];
    if (channel == null) {
      throw Exception('Device is offline or not connected.');
    }

    final sessionId = const Uuid().v4();
    final session = TransferSession(
      sessionId: sessionId,
      channel: channel,
      bandwidthManager: _bandwidthManager,
      packetManager: _packetManager,
      isSender: true,
      baseFolderPath: sourceFolderPath,
      onLog: (msg) => _logger.info('TransferSession', msg),
      onProgress: (prog, speed, file) {
        _eventController.add(TransportEvent(
          TransportEventType.transferProgress,
          deviceId,
          sessionId: sessionId,
          progress: prog,
          speed: speed,
          message: file,
        ));
      },
    );

    for (final file in files) {
      final relativePath = p.relative(file.path, from: sourceFolderPath);
      final size = await file.length();
      session.addToQueue(relativePath, size);
    }

    _activeTransfers[sessionId] = session;
    
    // Save session in DB
    final sessionModel = TransferSessionModel(
      id: sessionId,
      deviceId: deviceId,
      startTime: DateTime.now(),
      status: SessionStatus.active,
      totalFiles: session.totalFiles,
      completedFiles: 0,
      totalBytes: session.totalBytes,
      completedBytes: 0,
      bandwidthLimit: _bandwidthManager.limit,
    );
    await _transportRepository.addOrUpdateSession(sessionModel);

    // Run async send
    unawaited(session.startSend().then((_) async {
      // Save stats and updates
      final updatedModel = sessionModel.copyWith(
        endTime: DateTime.now(),
        status: SessionStatus.completed,
        completedFiles: session.completedFiles,
        completedBytes: session.completedBytes,
      );
      await _transportRepository.addOrUpdateSession(updatedModel);
      await _transportRepository.updateStatistics(session.completedBytes, 0, session.completedFiles, 0, 0);

      // Save transfer history entries
      for (final item in session.queue) {
        final history = TransferHistoryModel(
          id: const Uuid().v4(),
          sessionId: sessionId,
          fileName: p.basename(item.relativePath),
          relativePath: item.relativePath,
          fileSize: item.size,
          bytesTransferred: item.size,
          status: TransferStatus.completed,
          durationMs: 1000,
          timestamp: DateTime.now(),
        );
        await _transportRepository.addTransferHistoryEntry(history);
      }

      _eventController.add(TransportEvent(TransportEventType.transferCompleted, deviceId, sessionId: sessionId));
    }).catchError((err, stack) async {
      final failedModel = sessionModel.copyWith(
        endTime: DateTime.now(),
        status: SessionStatus.failed,
      );
      await _transportRepository.addOrUpdateSession(failedModel);
      await _recordError(deviceId, 'TransferFailed', err.toString(), stack.toString());

      _eventController.add(TransportEvent(TransportEventType.transferFailed, deviceId, sessionId: sessionId, message: err.toString()));
    }));

    return sessionId;
  }

  void registerIncomingTransferSession(String sessionId, String deviceId, String destFolderPath) {
    final channel = _activeChannels[deviceId];
    if (channel == null) return;

    final session = TransferSession(
      sessionId: sessionId,
      channel: channel,
      bandwidthManager: _bandwidthManager,
      packetManager: _packetManager,
      isSender: false,
      baseFolderPath: destFolderPath,
      onLog: (msg) => _logger.info('TransferSession', msg),
    );

    _activeTransfers[sessionId] = session;
  }

  // --- Database Logger Helpers ---

  Future<void> _recordError(String deviceId, String type, String msg, String stack) async {
    final err = TransportErrorModel(
      id: const Uuid().v4(),
      deviceId: deviceId,
      timestamp: DateTime.now(),
      errorType: type,
      errorMessage: msg,
      stackTrace: stack,
    );
    await _transportRepository.addErrorEntry(err);
  }
}

enum TransportEventType {
  connected,
  disconnected,
  transferProgress,
  transferCompleted,
  transferFailed,
  transferInterrupted,
  transferResumed
}

class TransportEvent {
  final TransportEventType type;
  final String deviceId;
  final String? sessionId;
  final double progress;
  final double speed;
  final String? message;

  TransportEvent(
    this.type,
    this.deviceId, {
    this.sessionId,
    this.progress = 0.0,
    this.speed = 0.0,
    this.message,
  });
}
