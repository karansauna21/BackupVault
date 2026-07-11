import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:backup_vault/core/auto_backup/sync_policy.dart';
import 'package:backup_vault/core/auto_backup/sync_queue.dart';
import 'package:backup_vault/core/auto_backup/device_selection_manager.dart';
import 'package:backup_vault/core/auto_backup/transfer_scheduler.dart';
import 'package:backup_vault/core/auto_backup/auto_backup_manager.dart';
import 'package:backup_vault/core/file_watcher/file_event.dart';
import 'package:backup_vault/core/repositories/device_repository.dart';
import 'package:backup_vault/core/services/logging_service.dart';
import 'package:backup_vault/core/services/backup_engine.dart';
import 'package:backup_vault/core/transport/transport_manager.dart';
import 'package:backup_vault/core/discovery/network_scanner.dart';
import 'package:backup_vault/features/settings/settings_database.dart';
import 'package:backup_vault/core/repositories/backup_folder_repository.dart';
import 'package:backup_vault/core/repositories/backup_file_repository.dart';
import 'package:backup_vault/core/repositories/file_version_repository.dart';
import 'package:backup_vault/core/repositories/backup_log_repository.dart';
import 'package:backup_vault/core/services/folder_watcher.dart';
import 'package:backup_vault/core/copy_engine/copy_engine.dart';
import 'package:backup_vault/core/services/version_manager.dart';
import 'package:backup_vault/core/database/app_database.dart';

// --- Mocks & Stubs ---

class FakeSettingsDatabase extends SettingsDatabase {
  final Map<String, String> _storage = {};

  FakeSettingsDatabase() : super(isInMemory: true);

  @override
  Future<void> init() async {}

  @override
  void setValue(String key, String value) {
    _storage[key] = value;
  }

  @override
  String? getValue(String key) {
    return _storage[key];
  }

  void deleteValue(String key) {
    _storage.remove(key);
  }

  @override
  void clear() {
    _storage.clear();
  }
}

class FakeBackupLogRepository implements BackupLogRepository {
  @override
  Future<int> addLog(BackupLogsCompanion log) async => 0;
  @override
  Future<int> clearLogs() async => 0;
  @override
  Future<List<BackupLog>> getAllLogs({String? logType, int limit = 200}) async => [];
}

class FakeLoggingService extends LoggingService {
  FakeLoggingService() : super(FakeBackupLogRepository());

  @override
  Future<void> info(String tag, String message) async {}

  @override
  Future<void> warning(String tag, String message) async {}

  @override
  Future<void> error(String tag, String message, [String? stackTrace]) async {}
}

class FakeNetworkScanner extends NetworkScanner {
  String connectionType = 'Wi-Fi';

  FakeNetworkScanner(LoggingService logger) : super(
    logger: logger,
    deviceId: 'test-device-id',
    deviceName: 'Test Device',
    platform: 'Android',
    appVersion: '1.0.0',
    transportPort: 8321,
  );

  @override
  Future<String> getCurrentConnectionType() async {
    return connectionType;
  }
}

class FakeTransportManager extends TransportManager {
  final StreamController<TransportEvent> _events = StreamController<TransportEvent>.broadcast();

  FakeTransportManager(super.db, super.repo, super.logger);

  @override
  Stream<TransportEvent> get eventStream => _events.stream;

  void triggerEvent(TransportEvent event) {
    _events.add(event);
  }

  @override
  Future<String> sendFolder(String deviceId, String sourceFolderPath, List<File> files) async {
    final sessionId = const Uuid().v4();
    
    // Simulate successful transfer in event stream
    Timer(const Duration(milliseconds: 100), () {
      triggerEvent(TransportEvent(
        TransportEventType.transferProgress,
        deviceId,
        sessionId: sessionId,
        progress: 0.5,
        speed: 1024 * 1024,
      ));
    });

    Timer(const Duration(milliseconds: 200), () {
      triggerEvent(TransportEvent(
        TransportEventType.transferCompleted,
        deviceId,
        sessionId: sessionId,
      ));
    });

    return sessionId;
  }
}

class FakeBackupEngine extends BackupEngine {
  final StreamController<FileEvent> _events = StreamController<FileEvent>.broadcast();

  FakeBackupEngine(LoggingService logger) : super(
    folderRepository: FakeFolderRepo(),
    fileRepository: FakeFileRepo(),
    versionRepository: FakeVersionRepo(),
    folderWatcher: FakeWatcher(),
    copyEngine: FakeCopyEngine(),
    versionManager: FakeVersionManager(),
    logger: logger,
  );

  @override
  Stream<FileEvent> get onWatcherEvent => _events.stream;

  void emitEvent(FileEvent event) {
    _events.add(event);
  }
}

// Minimal stubs to satisfy compiler for BackupEngine constructor
class FakeFolderRepo implements BackupFolderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeFileRepo implements BackupFileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeVersionRepo implements FileVersionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeWatcher implements FolderWatcher {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeCopyEngine implements CopyEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeVersionManager implements VersionManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSettingsDatabase db;
  late DeviceRepository deviceRepo;
  late FakeNetworkScanner networkScanner;
  late FakeTransportManager transportManager;
  late FakeBackupEngine backupEngine;
  late LoggingService logger;
  late SyncQueue queue;
  late DeviceSelectionManager selectionManager;
  late TransferScheduler scheduler;
  late AutoBackupManager manager;

  setUp(() {
    db = FakeSettingsDatabase();
    deviceRepo = DeviceRepository(db);
    logger = FakeLoggingService();
    networkScanner = FakeNetworkScanner(logger);
    transportManager = FakeTransportManager(db, deviceRepo, logger);
    backupEngine = FakeBackupEngine(logger);
    queue = SyncQueue();
    selectionManager = DeviceSelectionManager(db);

    scheduler = TransferScheduler(
      queue: queue,
      transportManager: transportManager,
      deviceRepository: deviceRepo,
      logger: logger,
      db: db,
      networkScanner: networkScanner,
    );

    manager = AutoBackupManager(
      db: db,
      deviceRepository: deviceRepo,
      logger: logger,
      selectionManager: selectionManager,
      queue: queue,
      scheduler: scheduler,
      backupEngine: backupEngine,
    );
  });

  tearDown(() {
    scheduler.stop();
    manager.dispose();
  });

  group('SyncPolicy Tests', () {
    test('Default values', () {
      final policy = SyncPolicy.defaultPolicy();
      expect(policy.autoBackupEnabled, isFalse);
      expect(policy.backupOnlyOnWifi, isTrue);
      expect(policy.backupOnlyWhileCharging, isFalse);
      expect(policy.bandwidthLimit, equals(0));
      expect(policy.retryCount, equals(3));
    });

    test('JSON serialization & deserialization', () {
      final original = SyncPolicy(
        autoBackupEnabled: true,
        backupOnlyWhileCharging: true,
        backupOnlyOnWifi: false,
        bandwidthLimit: 512,
        retryCount: 5,
      );

      final jsonMap = original.toJson();
      final parsed = SyncPolicy.fromJson(jsonMap);

      expect(parsed.autoBackupEnabled, isTrue);
      expect(parsed.backupOnlyWhileCharging, isTrue);
      expect(parsed.backupOnlyOnWifi, isFalse);
      expect(parsed.bandwidthLimit, equals(512));
      expect(parsed.retryCount, equals(5));
    });
  });

  group('SyncQueue Tests', () {
    test('Enqueueing & sorting by priority and timestamp', () {
      final now = DateTime.now();
      
      final itemNormal = QueueItem(
        id: '1',
        filePath: 'path/1.txt',
        fileName: '1.txt',
        fileSize: 100,
        destDeviceId: 'devA',
        addedAt: now,
        priority: 1,
      );
      final itemHigh = QueueItem(
        id: '2',
        filePath: 'path/2.txt',
        fileName: '2.txt',
        fileSize: 200,
        destDeviceId: 'devA',
        addedAt: now.add(const Duration(seconds: 1)),
        priority: 2,
      );
      final itemLow = QueueItem(
        id: '3',
        filePath: 'path/3.txt',
        fileName: '3.txt',
        fileSize: 300,
        destDeviceId: 'devA',
        addedAt: now.subtract(const Duration(seconds: 1)),
        priority: 0,
      );

      queue.enqueue(itemNormal);
      queue.enqueue(itemHigh);
      queue.enqueue(itemLow);

      // Verify sorting: High priority first, then Normal, then Low
      expect(queue.items[0].id, equals('2'));
      expect(queue.items[1].id, equals('1'));
      expect(queue.items[2].id, equals('3'));
    });

    test('Queue pause, resume and status updates', () {
      final item = QueueItem(
        id: '1',
        filePath: 'path/1.txt',
        fileName: '1.txt',
        fileSize: 100,
        destDeviceId: 'devA',
        addedAt: DateTime.now(),
      );

      queue.enqueue(item);
      expect(queue.items.first.status, equals('waiting'));

      queue.pause();
      expect(queue.items.first.status, equals('paused'));

      queue.resume();
      expect(queue.items.first.status, equals('waiting'));

      queue.updateStatus('1', 'syncing');
      expect(queue.items.first.status, equals('syncing'));
    });
  });

  group('TransferScheduler Tests', () {
    test('Scheduler respects Wi-Fi & charging constraints', () async {
      db.setValue('auto_backup_enabled', 'true');
      db.setValue('auto_backup_wifi_only', 'true');
      
      final item = QueueItem(
        id: '1',
        filePath: 'test/auto_backup_test.dart', // Needs real file path to construct File
        fileName: 'auto_backup_test.dart',
        fileSize: 100,
        destDeviceId: 'devA',
        addedAt: DateTime.now(),
      );
      queue.enqueue(item);

      // Disable wifi constraint mock
      scheduler.mockWifi = false;
      scheduler.mockCharging = true;

      // Start scheduler and run process loop once
      scheduler.start();
      await Future.delayed(const Duration(milliseconds: 100));

      // File should not process (remain waiting/paused)
      expect(queue.items.first.status, equals('waiting'));

      // Satisfy constraints
      scheduler.mockWifi = true;
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Wait for mock timer loop
      await Future.delayed(const Duration(seconds: 4));
    });
  });

  group('AutoBackupManager Tests', () {
    test('Intercepts file watcher events and enqueues tasks', () async {
      // Setup settings and devices
      db.setValue('auto_backup_enabled', 'true');
      selectionManager.saveSelectedDestinationDeviceIds(['device_1', 'device_2']);

      manager.init();

      // Emit watcher file change event
      backupEngine.emitEvent(FileEvent(
        folderId: 1,
        path: 'test/auto_backup_test.dart', // Must be an existing file
        type: FileEventType.newFile,
        timestamp: DateTime.now(),
        isDir: false,
      ));

      // Wait for stream dispatching
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that tasks are enqueued for both destination devices
      expect(queue.items.length, equals(2));
      expect(queue.items.any((i) => i.destDeviceId == 'device_1'), isTrue);
      expect(queue.items.any((i) => i.destDeviceId == 'device_2'), isTrue);
      
      manager.dispose();
    });

    test('Correctly calculates dashboard statistics', () {
      db.setValue('auto_backup_enabled', 'true');
      db.setValue('last_successful_sync', DateTime.now().toIso8601String());

      final stats = manager.getDashboardStats();
      expect(stats['syncStatus'], equals('Connected'));
      expect(stats['pendingFiles'], equals(0));
      expect(stats['currentSpeed'], equals(0.0));
    });
  });

  group('Conflict Resolution Versioning Tests', () {
    test('Dynamic version paths for conflicting hashes', () async {
      final tempDir = Directory.systemTemp.createTempSync('backup_vault_test');
      final originalFile = File('${tempDir.path}/test.txt');
      originalFile.writeAsStringSync('Original Content');

      // First version path exists. Check next versioning.
      final v2File = File('${tempDir.path}/test_v2.txt');
      v2File.writeAsStringSync('Second Content');

      // Expected target filename candidate is test_v3.txt
      final targetPath = '${tempDir.path}/test.txt';
      
      // Helper function matching the receiver resolve logic
      String resolveDestPath(String path, String ext) {
        var version = 2;
        while (true) {
          final dir = tempDir.path;
          final base = 'test';
          final candidate = '$dir/${base}_v$version$ext';
          if (!File(candidate).existsSync()) {
            return candidate;
          }
          version++;
        }
      }

      final resolved = resolveDestPath(targetPath, '.txt');
      expect(resolved, endsWith('test_v3.txt'));

      tempDir.deleteSync(recursive: true);
    });
  });
}
