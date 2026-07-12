// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../features/settings/settings_database.dart';
import '../../features/security/encryption_manager.dart';
import '../repositories/device_repository.dart';
import '../services/logging_service.dart';
import '../models/device_model.dart';
import 'remote_connection_provider.dart';
import 'internet_discovery.dart';

class RemoteConnectionManager {
  final SettingsDatabase _db;
  final DeviceRepository _deviceRepository;
  final LoggingService _logger;
  final InternetDiscovery _internetDiscovery;
  final EncryptionManager? _encryptionManager;

  RemoteConnectionProvider _currentProvider;
  final Map<String, StreamSubscription> _subscriptions = {};

  final StreamController<RemoteTransferEvent> _eventController = StreamController<RemoteTransferEvent>.broadcast();

  RemoteConnectionManager({
    required SettingsDatabase db,
    required DeviceRepository deviceRepository,
    required LoggingService logger,
    required InternetDiscovery internetDiscovery,
    EncryptionManager? encryptionManager,
    RemoteConnectionProvider? initialProvider,
  })  : _db = db,
        _deviceRepository = deviceRepository,
        _logger = logger,
        _internetDiscovery = internetDiscovery,
        _encryptionManager = encryptionManager,
        _currentProvider = initialProvider ?? SimulatedRemoteConnectionProvider();

  Stream<RemoteTransferEvent> get eventStream => _eventController.stream;
  RemoteConnectionProvider get currentProvider => _currentProvider;

  void setProvider(RemoteConnectionProvider provider) {
    _logger.info('RemoteConnectionManager', 'Switching to connection provider: ${provider.providerId}');
    _currentProvider.dispose();
    _currentProvider = provider;
  }

  Future<void> connect(String deviceId) async {
    // 1. Security Check: Only allow paired trusted devices
    final devices = await _deviceRepository.getDevices();
    DeviceModel? device;
    for (final d in devices) {
      if (d.id == deviceId) {
        device = d;
        break;
      }
    }
    if (device == null) {
      _logger.error('RemoteConnectionManager', 'Connection rejected: unknown device $deviceId');
      throw Exception('Device is unknown. Connection disallowed.');
    }
    if (device.trustStatus != 'Trusted') {
      _logger.error('RemoteConnectionManager', 'Connection rejected: untrusted status "${device.trustStatus}" for device $deviceId');
      throw Exception('Device is not trusted.');
    }

    // 2. Setting Check: Is remote backup enabled?
    final remoteEnabled = _db.getValue('remote_backup_enabled') ?? 'true';
    if (remoteEnabled != 'true') {
      throw Exception('Remote backup is disabled in settings.');
    }

    // 3. Network Restrictions check
    final wifiOnly = _db.getValue('remote_backup_wifi_only') ?? 'false';
    final connType = await _internetDiscovery.getConnectionType();
    
    if (wifiOnly == 'true' && connType != 'Wi-Fi' && connType != 'Ethernet') {
      throw Exception('Remote backup restricted to Wi-Fi only.');
    }

    final allowMobile = _db.getValue('remote_backup_allow_mobile') ?? 'true';
    if (allowMobile != 'true' && connType == 'Mobile Data') {
      throw Exception('Remote backup on Mobile Data is disabled.');
    }

    // Check Data Limits
    final maxMobileDataStr = _db.getValue('remote_backup_max_mobile_data') ?? '0'; // in MB
    final maxMobileData = int.tryParse(maxMobileDataStr) ?? 0;
    if (maxMobileData > 0 && connType == 'Mobile Data') {
      final currentMonthUsedStr = _db.getValue('remote_backup_mobile_data_used_this_month') ?? '0';
      final currentMonthUsed = double.tryParse(currentMonthUsedStr) ?? 0.0;
      if (currentMonthUsed >= maxMobileData) {
        throw Exception('Monthly mobile data limit reached for remote backup.');
      }
    }

    _logger.info('RemoteConnectionManager', 'Establishing remote connection to ${device.name} via ${_currentProvider.providerId}');
    
    await _currentProvider.connect(deviceId);

    _subscriptions[deviceId]?.cancel();
    _subscriptions[deviceId] = _currentProvider.dataStream(deviceId).listen(
      (data) => _handleIncomingData(deviceId, data),
      onError: (err) => _logger.error('RemoteConnectionManager', 'Error on data stream for $deviceId: $err'),
    );

    await _logger.info('RemoteConnectionManager', 'Remote Connected: ${device.name}');
    if (!_eventController.isClosed) {
      _eventController.add(RemoteTransferEvent(
        type: RemoteTransferEventType.connected,
        deviceId: deviceId,
      ));
    }
  }

  Future<void> disconnect(String deviceId) async {
    await _currentProvider.disconnect(deviceId);
    _subscriptions[deviceId]?.cancel();
    _subscriptions.remove(deviceId);
    
    _logger.info('RemoteConnectionManager', 'Remote Disconnected: $deviceId');
    if (!_eventController.isClosed) {
      _eventController.add(RemoteTransferEvent(
        type: RemoteTransferEventType.disconnected,
        deviceId: deviceId,
      ));
    }
  }

  Future<void> sendPayload(String deviceId, Map<String, dynamic> payload) async {
    final payloadJson = json.encode(payload);
    final rawBytes = utf8.encode(payloadJson);
    
    Uint8List finalBytes;
    bool isEncrypted = false;
    if (_encryptionManager != null && _encryptionManager.isEncryptionActive) {
      finalBytes = _encryptionManager.encryptBytes(Uint8List.fromList(rawBytes));
      isEncrypted = true;
    } else {
      finalBytes = Uint8List.fromList(rawBytes);
    }

    final packet = {
      'encrypted': isEncrypted,
      'data': base64.encode(finalBytes),
    };

    final packetBytes = utf8.encode(json.encode(packet));

    final connType = await _internetDiscovery.getConnectionType();
    if (connType == 'Mobile Data') {
      final currentMonthUsedStr = _db.getValue('remote_backup_mobile_data_used_this_month') ?? '0';
      final currentMonthUsed = double.tryParse(currentMonthUsedStr) ?? 0.0;
      final newUsed = currentMonthUsed + (packetBytes.length / (1024.0 * 1024.0)); // MB
      _db.setValue('remote_backup_mobile_data_used_this_month', newUsed.toStringAsFixed(2));
    }

    await _currentProvider.sendData(deviceId, packetBytes);
  }

  void _handleIncomingData(String deviceId, List<int> rawPacket) {
    try {
      final packetJson = json.decode(utf8.decode(rawPacket)) as Map<String, dynamic>;
      final bool isEncrypted = packetJson['encrypted'] ?? false;
      final encryptedBytes = base64.decode(packetJson['data'] as String);

      Uint8List plainBytes;
      if (isEncrypted && _encryptionManager != null) {
        plainBytes = _encryptionManager.decryptBytes(encryptedBytes);
      } else {
        plainBytes = encryptedBytes;
      }

      final payload = json.decode(utf8.decode(plainBytes)) as Map<String, dynamic>;
      
      if (!_eventController.isClosed) {
        _eventController.add(RemoteTransferEvent(
          type: RemoteTransferEventType.payloadReceived,
          deviceId: deviceId,
          payload: payload,
        ));
      }
    } catch (e, stack) {
      _logger.error('RemoteConnectionManager', 'Failed to handle incoming packet: $e', stack.toString());
    }
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _currentProvider.dispose();
    _eventController.close();
  }
}

enum RemoteTransferEventType {
  connected,
  disconnected,
  payloadReceived
}

class RemoteTransferEvent {
  final RemoteTransferEventType type;
  final String deviceId;
  final Map<String, dynamic>? payload;

  RemoteTransferEvent({
    required this.type,
    required this.deviceId,
    this.payload,
  });
}
