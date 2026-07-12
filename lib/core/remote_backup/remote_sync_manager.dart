// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../../features/settings/settings_database.dart';
import '../services/logging_service.dart';
import '../services/backup_engine.dart';
import '../file_watcher/file_event.dart';
import 'internet_discovery.dart';
import 'remote_connection_manager.dart';
import 'remote_transfer_queue.dart';
import 'remote_session.dart';

class RemoteSyncManager {
  final SettingsDatabase _db;
  final LoggingService _logger;
  final InternetDiscovery _internetDiscovery;
  final RemoteConnectionManager _connectionManager;
  final RemoteTransferQueue _queue;
  final BackupEngine _backupEngine;

  bool _isStarted = false;
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, RemoteSession> _activeSessions = {};
  final StreamController<Map<String, RemoteSession>> _sessionsController = StreamController.broadcast();

  RemoteSyncManager({
    required SettingsDatabase db,
    required LoggingService logger,
    required InternetDiscovery internetDiscovery,
    required RemoteConnectionManager connectionManager,
    required RemoteTransferQueue queue,
    required BackupEngine backupEngine,
  })  : _db = db,
        _logger = logger,
        _internetDiscovery = internetDiscovery,
        _connectionManager = connectionManager,
        _queue = queue,
        _backupEngine = backupEngine;

  Stream<Map<String, RemoteSession>> get onSessionsChanged => _sessionsController.stream;
  Map<String, RemoteSession> get activeSessions => Map.unmodifiable(_activeSessions);

  void start() {
    if (_isStarted) return;
    _isStarted = true;
    _logger.info('RemoteSyncManager', 'Starting RemoteSyncManager service...');

    // 1. Intercept file watcher events from BackupEngine
    _subscriptions.add(_backupEngine.onWatcherEvent.listen(_handleFileWatcherEvent));

    // 2. Listen to route transitions (Local -> Remote -> Offline)
    _subscriptions.add(_internetDiscovery.onRouteChanged.listen(_handleRouteChanges));

    // 3. Start processing loop for remote queue
    _startQueueProcessingLoop();
  }

  void stop() {
    _isStarted = false;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    for (final session in _activeSessions.values) {
      session.dispose();
    }
    _activeSessions.clear();
  }

  void _handleFileWatcherEvent(FileEvent event) async {
    final remoteEnabled = _db.getValue('remote_backup_enabled') ?? 'true';
    if (remoteEnabled != 'true') return;

    // Check where we should sync this file. Get all paired destination devices.
    final selectedDevicesKey = _db.getValue('selected_destination_devices') ?? '[]';
    
    List<String> selectedIds = [];
    try {
      selectedIds = List<String>.from(json.decode(selectedDevicesKey));
    } catch (_) {}

    for (final deviceId in selectedIds) {
      final route = _internetDiscovery.deviceRoutes[deviceId] ?? DeviceRoute.offline;
      
      if (route == DeviceRoute.local) {
        _logger.info('RemoteSyncManager', 'Device $deviceId is local. Routing to Local Sync.');
        continue;
      }

      if (route == DeviceRoute.remote) {
        _logger.info('RemoteSyncManager', 'Device $deviceId is remote. Enqueuing file to Remote queue: ${event.path}');
        
        final item = RemoteQueueItem(
          id: const Uuid().v4(),
          filePath: event.path,
          fileName: event.path.split('/').last.split('\\').last,
          fileSize: File(event.path).existsSync() ? File(event.path).lengthSync() : 0,
          destDeviceId: deviceId,
          addedAt: DateTime.now(),
        );
        _queue.enqueue(item);
      }
    }
  }

  void _handleRouteChanges(Map<String, DeviceRoute> routes) {
    for (final entry in routes.entries) {
      if (entry.value == DeviceRoute.remote) {
        _logger.info('RemoteSyncManager', 'Device ${entry.key} transitioned to Remote. Triggering transfers.');
      }
    }
  }

  void _startQueueProcessingLoop() {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isStarted) {
        timer.cancel();
        return;
      }
      await _processNextQueueItem();
    });
  }

  Future<void> _processNextQueueItem() async {
    final item = _queue.items.firstWhere(
      (i) => i.status == 'waiting',
      orElse: () => RemoteQueueItem(
        id: '',
        filePath: '',
        fileName: '',
        fileSize: 0,
        destDeviceId: '',
        addedAt: DateTime.now(),
      ),
    );

    if (item.id.isEmpty) return;

    final deviceId = item.destDeviceId;
    final route = _internetDiscovery.deviceRoutes[deviceId] ?? DeviceRoute.offline;

    if (route != DeviceRoute.remote) {
      return;
    }

    _queue.updateStatus(item.id, 'syncing');
    await _logger.info('RemoteSyncManager', 'Upload Started: ${item.fileName} to $deviceId');

    try {
      await _connectionManager.connect(deviceId);

      final session = RemoteSession(
        deviceId: deviceId,
        connectionManager: _connectionManager,
        logger: _logger,
      );

      _activeSessions[deviceId] = session;
      if (!_sessionsController.isClosed) {
        _sessionsController.add(Map.from(_activeSessions));
      }

      final file = File(item.filePath);
      await session.startSync([file]);

      if (session.status == RemoteSessionStatus.completed) {
        _queue.updateStatus(item.id, 'completed');
        await _logger.info('RemoteSyncManager', 'Upload Completed: ${item.fileName}');
      } else {
        throw Exception(session.currentProgress.errorMessage ?? 'Session sync failed.');
      }
    } catch (e) {
      await _logger.error('RemoteSyncManager', 'Upload Failed: ${item.fileName} | Error: $e');
      _queue.markFailed(item.id, e.toString());

      if (item.retries < 3) {
        _queue.incrementRetries(item.id);
        _queue.updateStatus(item.id, 'waiting');
        await _logger.warning('RemoteSyncManager', 'Retry triggered for ${item.fileName} (Attempt ${item.retries + 1}/3)');
      }
    } finally {
      _activeSessions.remove(deviceId);
      if (!_sessionsController.isClosed) {
        _sessionsController.add(Map.from(_activeSessions));
      }
    }
  }

  void dispose() {
    stop();
    _sessionsController.close();
  }
}
