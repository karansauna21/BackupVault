import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../discovery/network_scanner.dart';
import '../repositories/device_repository.dart';
import '../services/logging_service.dart';
import '../transport/transport_manager.dart';
import '../../features/settings/settings_database.dart';
import 'sync_policy.dart';
import 'sync_queue.dart';
import 'sync_session.dart';
import 'transfer_history.dart';

class TransferScheduler {
  final SyncQueue queue;
  final TransportManager transportManager;
  final DeviceRepository deviceRepository;
  final LoggingService logger;
  final SettingsDatabase db;
  final NetworkScanner networkScanner;

  final Map<String, SyncSession> _activeSyncSessions = {};
  final StreamController<Map<String, SyncSession>> _sessionsController = StreamController.broadcast();

  bool _isProcessing = false;
  bool _shouldStop = false;
  Timer? _scheduleTimer;

  // Mock overrides for validation & testing constraints
  bool mockCharging = true;
  bool mockWifi = true;

  Stream<Map<String, SyncSession>> get onSessionsChanged => _sessionsController.stream;
  Map<String, SyncSession> get activeSessions => Map.unmodifiable(_activeSyncSessions);

  TransferScheduler({
    required this.queue,
    required this.transportManager,
    required this.deviceRepository,
    required this.logger,
    required this.db,
    required this.networkScanner,
  });

  void start() {
    _shouldStop = false;
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _processQueue();
    });
    _processQueue(); // Initial trigger
  }

  void stop() {
    _shouldStop = true;
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
  }

  SyncSession? getSession(String deviceId) => _activeSyncSessions[deviceId];

  List<SyncSession> getSessionsList() => _activeSyncSessions.values.toList();

  SyncPolicy getSyncPolicy() {
    final enabled = db.getValue('auto_backup_enabled') == 'true';
    final charging = db.getValue('auto_backup_charging_only') == 'true';
    final wifi = db.getValue('auto_backup_wifi_only') == 'true';
    final limit = int.tryParse(db.getValue('auto_backup_bandwidth_limit') ?? '0') ?? 0;
    final retry = int.tryParse(db.getValue('auto_backup_retry_count') ?? '3') ?? 3;

    return SyncPolicy(
      autoBackupEnabled: enabled,
      backupOnlyWhileCharging: charging,
      backupOnlyOnWifi: wifi,
      bandwidthLimit: limit,
      retryCount: retry,
    );
  }

  Future<bool> _checkWifiConstraint() async {
    if (!mockWifi) return false;
    // Check if network connection type is Wi-Fi or Ethernet
    final connectionType = await networkScanner.getCurrentConnectionType();
    return connectionType == 'Wi-Fi' || connectionType == 'Ethernet';
  }

  Future<bool> _checkChargingConstraint() async {
    return mockCharging;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _shouldStop) return;
    _isProcessing = true;

    try {
      final policy = getSyncPolicy();
      if (!policy.autoBackupEnabled) {
        _isProcessing = false;
        return;
      }

      // Check Wi-Fi constraint
      final isWifi = await _checkWifiConstraint();
      if (policy.backupOnlyOnWifi && !isWifi) {
        logger.warning('TransferScheduler', 'Sync policy: Wi-Fi required but connection is not Wi-Fi. Postponing sync.');
        _isProcessing = false;
        return;
      }

      // Check Charging constraint
      final isCharging = await _checkChargingConstraint();
      if (policy.backupOnlyWhileCharging && !isCharging) {
        logger.warning('TransferScheduler', 'Sync policy: Charging required but device is on battery. Postponing sync.');
        _isProcessing = false;
        return;
      }

      // Find first item in queue that is waiting
      final nextItemIndex = queue.items.indexWhere((i) => i.status == 'waiting');
      if (nextItemIndex == -1) {
        _isProcessing = false;
        return;
      }

      final item = queue.items[nextItemIndex];

      // Exclude processing if device is already active in another transfer
      final destDeviceId = item.destDeviceId;
      final isDeviceSyncing = _activeSyncSessions[destDeviceId]?.status == 'Syncing';
      if (isDeviceSyncing) {
        _isProcessing = false;
        return;
      }

      // Load device from DB
      final device = await deviceRepository.getDeviceById(destDeviceId);
      if (device == null) {
        queue.updateStatus(item.id, 'failed', errorMessage: 'Device not found in database');
        _isProcessing = false;
        return;
      }

      // Mark item as syncing
      queue.updateStatus(item.id, 'syncing');

      // Set bandwidth limit on transport manager if configured
      if (policy.bandwidthLimit > 0) {
        transportManager.bandwidthManager.setLimit(policy.bandwidthLimit * 1024);
      } else {
        transportManager.bandwidthManager.setLimit(0); // Unlimited
      }

      // Initialize or update SyncSession
      var session = _activeSyncSessions[destDeviceId] ?? SyncSession(
        id: const Uuid().v4(),
        sourceDeviceId: 'local_device',
        destDeviceId: destDeviceId,
        status: 'Waiting',
        startedAt: DateTime.now(),
        totalFiles: 0,
        completedFiles: 0,
        totalBytes: 0,
        completedBytes: 0,
        currentSpeed: 0,
        etaSeconds: 0,
      );

      session = session.copyWith(
        status: 'Syncing',
        totalFiles: session.totalFiles + 1,
        totalBytes: session.totalBytes + item.fileSize,
        currentFile: item.fileName,
      );
      _activeSyncSessions[destDeviceId] = session;
      _sessionsController.add(Map.from(_activeSyncSessions));
      _saveSessionsToDb();

      logger.info('TransferScheduler', 'Auto backup started: ${item.fileName} -> ${device.name}');

      // Run transmission
      final file = File(item.filePath);
      final sourceFolder = file.parent.path;

      final stopwatch = Stopwatch()..start();
      
      try {
        final sessionId = await transportManager.sendFolder(destDeviceId, sourceFolder, [file]);

        // Monitor transmission progress
        final progressCompleter = Completer<bool>();
        final progressSubscription = transportManager.eventStream.listen((event) {
          if (event.sessionId == sessionId) {
            if (event.type == TransportEventType.transferProgress) {
              final updatedSession = _activeSyncSessions[destDeviceId]?.copyWith(
                completedBytes: (event.progress * item.fileSize).toInt(),
                currentSpeed: event.speed,
                etaSeconds: event.speed > 0 ? ((item.fileSize - (event.progress * item.fileSize)) / event.speed).toInt() : 0,
              );
              if (updatedSession != null) {
                _activeSyncSessions[destDeviceId] = updatedSession;
                _sessionsController.add(Map.from(_activeSyncSessions));
              }
            } else if (event.type == TransportEventType.transferCompleted) {
              progressCompleter.complete(true);
            } else if (event.type == TransportEventType.transferFailed || event.type == TransportEventType.transferInterrupted) {
              progressCompleter.complete(false);
            }
          }
        });

        final success = await progressCompleter.future.timeout(
          const Duration(minutes: 5),
          onTimeout: () => false,
        );
        progressSubscription.cancel();
        stopwatch.stop();

        if (success) {
          queue.updateStatus(item.id, 'completed');
          
          final finalSession = _activeSyncSessions[destDeviceId]?.copyWith(
            status: 'Connected',
            completedFiles: (_activeSyncSessions[destDeviceId]?.completedFiles ?? 0) + 1,
            completedBytes: _activeSyncSessions[destDeviceId]?.totalBytes,
            currentSpeed: 0,
            etaSeconds: 0,
            currentFile: null,
            completedAt: DateTime.now(),
          );
          if (finalSession != null) {
            _activeSyncSessions[destDeviceId] = finalSession;
            _sessionsController.add(Map.from(_activeSyncSessions));
          }

          logger.info('TransferScheduler', 'Transfer completed: ${item.fileName} successfully synced.');
          
          // Save successful sync metadata
          db.setValue('last_synced_file', item.fileName);
          db.setValue('last_successful_sync', DateTime.now().toIso8601String());

          await _recordHistory(
            item: item,
            status: 'Success',
            speed: item.fileSize / (stopwatch.elapsedMilliseconds / 1000.0),
            durationMs: stopwatch.elapsedMilliseconds,
          );
        } else {
          throw Exception('File transmission failed on transport layer.');
        }
      } catch (e) {
        stopwatch.stop();
        logger.error('TransferScheduler', 'Transfer failed for ${item.fileName}: $e');
        
        db.setValue('failed_sync', DateTime.now().toIso8601String());

        final retries = item.retryCount;
        if (retries >= policy.retryCount) {
          queue.updateStatus(item.id, 'failed', errorMessage: e.toString());
          
          final finalSession = _activeSyncSessions[destDeviceId]?.copyWith(
            status: 'Failed',
            currentSpeed: 0,
            etaSeconds: 0,
            currentFile: null,
          );
          if (finalSession != null) {
            _activeSyncSessions[destDeviceId] = finalSession;
            _sessionsController.add(Map.from(_activeSyncSessions));
          }
        } else {
          queue.incrementRetry(item.id);
          queue.updateStatus(item.id, 'waiting', errorMessage: 'Transfer failed. Retrying... (${retries + 1}/${policy.retryCount})');
          
          final finalSession = _activeSyncSessions[destDeviceId]?.copyWith(
            status: 'Waiting',
            currentSpeed: 0,
            etaSeconds: 0,
            currentFile: null,
          );
          if (finalSession != null) {
            _activeSyncSessions[destDeviceId] = finalSession;
            _sessionsController.add(Map.from(_activeSyncSessions));
          }
        }

        await _recordHistory(
          item: item,
          status: 'Failed',
          speed: 0,
          durationMs: stopwatch.elapsedMilliseconds,
          error: e.toString(),
        );
      }

      _saveSessionsToDb();
    } catch (e) {
      logger.error('TransferScheduler', 'Unhandled error in queue processor loop: $e');
    } finally {
      _isProcessing = false;
      // Trigger next item immediately
      _processQueue();
    }
  }

  Future<void> _recordHistory({
    required QueueItem item,
    required String status,
    required double speed,
    required int durationMs,
    String? error,
  }) async {
    final entry = TransferHistoryEntry(
      id: const Uuid().v4(),
      fileId: item.id,
      fileName: item.fileName,
      fileSize: item.fileSize,
      sourceDevice: 'local_device',
      destDevice: item.destDeviceId,
      status: status,
      timestamp: DateTime.now(),
      sha256: '', // Optional verification hash
      errorMessage: error,
      speedBytesPerSec: speed,
      durationMs: durationMs,
    );

    // Save to settings DB
    final List<TransferHistoryEntry> history = await getTransferHistory();
    history.insert(0, entry);
    if (history.length > 500) {
      history.removeRange(500, history.length); // Cap logs
    }
    db.setValue('auto_backup_transfer_history', json.encode(history.map((e) => e.toJson()).toList()));
  }

  Future<List<TransferHistoryEntry>> getTransferHistory() async {
    final str = db.getValue('auto_backup_transfer_history');
    if (str != null) {
      try {
        final decoded = json.decode(str) as List<dynamic>;
        return decoded.map((e) => TransferHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }
    return [];
  }

  void _saveSessionsToDb() {
    final list = _activeSyncSessions.values.map((s) => s.toJson()).toList();
    db.setValue('auto_backup_sync_sessions', json.encode(list));
  }

  Future<List<SyncSession>> getSavedSyncSessions() async {
    final str = db.getValue('auto_backup_sync_sessions');
    if (str != null) {
      try {
        final decoded = json.decode(str) as List<dynamic>;
        return decoded.map((e) => SyncSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {}
    }
    return [];
  }
}
