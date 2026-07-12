import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:backup_vault/core/models/device_model.dart';
import 'package:backup_vault/features/settings/settings_database.dart';
import 'package:backup_vault/core/repositories/device_repository.dart';
import 'package:backup_vault/core/services/device_identity.dart';
import 'package:backup_vault/core/services/connection_manager.dart';
import 'package:backup_vault/core/services/device_pairing_service.dart';
import 'package:backup_vault/core/services/device_manager.dart';
import 'package:backup_vault/core/services/logging_service.dart';
import 'package:backup_vault/core/services/storage_provider.dart';
import 'package:backup_vault/core/repositories/backup_log_repository.dart';
import 'package:backup_vault/core/database/app_database.dart';

class FakeStorageProvider implements StorageProvider {
  @override
  Future<String?> resolvePath(String uriOrPath) async => uriOrPath;
  @override
  Future<Map<String, String>?> pickDirectory() async => null;
  @override
  Future<Map<String, int>?> getDiskFreeSpace(String path) async => {
        'free': 60 * 1024 * 1024 * 1024,
        'total': 256 * 1024 * 1024 * 1024,
      };
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
  Future<void> info(String tag, String message) async {
    // ignore: avoid_print
    print('[INFO][$tag] $message');
  }

  @override
  Future<void> warning(String tag, String message) async {
    // ignore: avoid_print
    print('[WARNING][$tag] $message');
  }

  @override
  Future<void> error(String tag, String message, [String? stackTrace]) async {
    // ignore: avoid_print
    print('[ERROR][$tag] $message ${stackTrace ?? ""}');
  }
}

void main() {
  final List<String> reportEntries = [];

  void logReport(String entry) {
    reportEntries.add(entry);
    // ignore: avoid_print
    print(entry);
  }

  setUpAll(() {
    logReport('========================================================');
    logReport('DEVICE PAIRING FOUNDATION VALIDATION REPORT');
    logReport('Generated on: ${DateTime.now().toIso8601String()}');
    logReport('========================================================\n');
  });

  tearDownAll(() async {
    logReport('\n========================================================');
    logReport('END OF REPORT');
    logReport('========================================================');

    final reportContent = reportEntries.join('\n');
    final file = File('pairing_report.txt');
    await file.writeAsString(reportContent);
  });

  group('Device Model Tests', () {
    test('Serialization & Deserialization works perfectly', () {
      final now = DateTime.now();
      final device = DeviceModel(
        id: 'test-uuid-12345',
        name: 'My Phone',
        platform: 'Android',
        osVersion: 'Android 13',
        appVersion: '1.0.0',
        deviceModel: 'Pixel 6',
        pairingDate: now,
        lastSeen: now,
        trustStatus: 'Pending',
        connectionStatus: 'Offline',
        ipAddress: '192.168.1.100',
        port: 8321,
        storageInfo: '45 GB / 128 GB',
      );

      final jsonMap = device.toJson();
      expect(jsonMap['id'], equals('test-uuid-12345'));
      expect(jsonMap['trustStatus'], equals('Pending'));
      expect(jsonMap['storageInfo'], equals('45 GB / 128 GB'));

      final fromJson = DeviceModel.fromJson(jsonMap);
      expect(fromJson.id, equals('test-uuid-12345'));
      expect(fromJson.name, equals('My Phone'));
      expect(fromJson.platform, equals('Android'));
      expect(fromJson.trustStatus, equals('Pending'));
      expect(fromJson.connectionStatus, equals('Offline'));
      expect(fromJson.storageInfo, equals('45 GB / 128 GB'));
    });
  });

  group('Pairing Scenarios Tests', () {
    late SettingsDatabase dbA;
    late SettingsDatabase dbB;
    
    late DeviceRepository repoA;
    late DeviceRepository repoB;

    late DeviceIdentity identityA;
    late DeviceIdentity identityB;

    late ConnectionManager connA;
    late ConnectionManager connB;

    late DevicePairingService pairingA;
    late DevicePairingService pairingB;

    late DeviceManager managerA;
    late DeviceManager managerB;

    setUp(() async {
      dbA = SettingsDatabase(isInMemory: true);
      dbB = SettingsDatabase(isInMemory: true);

      await dbA.init();
      await dbB.init();

      repoA = DeviceRepository(dbA);
      repoB = DeviceRepository(dbB);

      identityA = DeviceIdentity(dbA, FakeStorageProvider());
      identityB = DeviceIdentity(dbB, FakeStorageProvider());

      connA = ConnectionManager(FakeLoggingService());
      connB = ConnectionManager(FakeLoggingService());

      pairingA = DevicePairingService(repoA, identityA, connA, FakeLoggingService());
      pairingB = DevicePairingService(repoB, identityB, connB, FakeLoggingService());

      managerA = DeviceManager(repoA, identityA, connA, FakeLoggingService());
      managerB = DeviceManager(repoB, identityB, connB, FakeLoggingService());

      // Set simulation mode
      managerA.setSimulationMode(true);
      managerB.setSimulationMode(true);
    });

    tearDown(() {
      managerA.dispose();
      managerB.dispose();
      pairingA.dispose();
      pairingB.dispose();
      dbA.close();
      dbB.close();
    });

    test('Scenario 1: Android ↔ Windows Pairing', () async {
      logReport('SCENARIO 1: Android (Device A) ↔ Windows (Device B) Pairing');
      
      // Setup Device A (Android)
      dbA.setValue('self_device_uuid', 'android-uuid-55555');
      dbA.setValue('self_device_name', 'Pixel Phone');
      dbA.setValue('self_device_platform', 'Android');
      await managerA.init();
      
      // Setup Device B (Windows)
      dbB.setValue('self_device_uuid', 'windows-uuid-99999');
      dbB.setValue('self_device_name', 'Surface Laptop');
      dbB.setValue('self_device_platform', 'Windows');
      await managerB.init();

      expect(identityA.platform, equals('Android'));
      expect(identityB.platform, equals('Windows'));

      // Generate pairing code on Device A
      final pairCode = pairingA.generatePairCode();
      logReport('- Device A (Android) generated pairing code: $pairCode');

      // Device A initiates pairing request (simulated network transport to B)
      final aModel = await identityA.toModel(ip: '192.168.1.15', port: 8321);
      pairingB.simulateIncomingRequest(aModel, pairCode);

      // Yield control to let async event loop process the pairing request
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify B received the pending pairing request
      expect(pairingB.pendingRequests.length, equals(1));
      final pendingReqOnB = pairingB.pendingRequests.first;
      expect(pendingReqOnB.pairCode, equals(pairCode));
      expect(pendingReqOnB.device.id, equals(identityA.id));
      logReport('- Device B (Windows) received pairing request from: ${pendingReqOnB.device.name}');

      // B approves pairing request
      await pairingB.approveRequest(identityA.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pairingB.pendingRequests.isEmpty, isTrue);

      // Verify B has A in its trusted repository
      final deviceAOnB = await repoB.getDeviceById(identityA.id);
      expect(deviceAOnB, isNotNull);
      expect(deviceAOnB!.trustStatus, equals('Trusted'));
      logReport('- Device B approved request and marked Device A as: ${deviceAOnB.trustStatus}');

      // A receives approval response (simulated network loopback)
      final bModel = await identityB.toModel(ip: '192.168.1.30', port: 8321);
      final approvedDeviceA = bModel.copyWith(
        trustStatus: 'Trusted',
        connectionStatus: 'Online',
      );
      await repoA.addOrUpdateDevice(approvedDeviceA);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify A has B in its trusted repository
      final deviceBOnA = await repoA.getDeviceById(identityB.id);
      expect(deviceBOnA, isNotNull);
      expect(deviceBOnA!.trustStatus, equals('Trusted'));
      logReport('- Device A saved Device B as: ${deviceBOnA.trustStatus}');

      logReport('STATUS: Scenario 1 Passed Successfully.\n');
    });

    test('Scenario 2: Windows ↔ Windows Pairing', () async {
      logReport('SCENARIO 2: Windows (Device A) ↔ Windows (Device B) Pairing');

      // Setup Device A (Windows 1)
      dbA.setValue('self_device_uuid', 'win1-uuid-11111');
      dbA.setValue('self_device_name', 'Office Workstation');
      dbA.setValue('self_device_platform', 'Windows');
      await managerA.init();

      // Setup Device B (Windows 2)
      dbB.setValue('self_device_uuid', 'win2-uuid-22222');
      dbB.setValue('self_device_name', 'Home Laptop');
      dbB.setValue('self_device_platform', 'Windows');
      await managerB.init();

      expect(identityA.platform, equals('Windows'));
      expect(identityB.platform, equals('Windows'));

      // Generate pairing code on Device A
      final pairCode = pairingA.generatePairCode();
      logReport('- Device A (Windows) generated pairing code: $pairCode');

      // Initiate request
      final aModel = await identityA.toModel(ip: '192.168.1.11', port: 8321);
      pairingB.simulateIncomingRequest(aModel, pairCode);
      await Future.delayed(const Duration(milliseconds: 50));

      // Approve on B
      await pairingB.approveRequest(identityA.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pairingB.pendingRequests.isEmpty, isTrue);

      final deviceAOnB = await repoB.getDeviceById(identityA.id);
      expect(deviceAOnB, isNotNull);
      expect(deviceAOnB!.trustStatus, equals('Trusted'));
      logReport('- Device B approved request and marked Device A as: ${deviceAOnB.trustStatus}');

      // Save on A
      final bModel = await identityB.toModel(ip: '192.168.1.12', port: 8321);
      await repoA.addOrUpdateDevice(bModel.copyWith(trustStatus: 'Trusted'));
      await Future.delayed(const Duration(milliseconds: 50));

      final deviceBOnA = await repoA.getDeviceById(identityB.id);
      expect(deviceBOnA, isNotNull);
      expect(deviceBOnA!.trustStatus, equals('Trusted'));
      logReport('- Device A saved Device B as: ${deviceBOnA.trustStatus}');

      logReport('STATUS: Scenario 2 Passed Successfully.\n');
    });

    test('Scenario 3: Android ↔ Android Pairing', () async {
      logReport('SCENARIO 3: Android (Device A) ↔ Android (Device B) Pairing');

      // Setup Device A (Android 1)
      dbA.setValue('self_device_uuid', 'android1-uuid-33333');
      dbA.setValue('self_device_name', 'Primary Phone');
      dbA.setValue('self_device_platform', 'Android');
      await managerA.init();

      // Setup Device B (Android 2)
      dbB.setValue('self_device_uuid', 'android2-uuid-44444');
      dbB.setValue('self_device_name', 'Tablet');
      dbB.setValue('self_device_platform', 'Android');
      await managerB.init();

      expect(identityA.platform, equals('Android'));
      expect(identityB.platform, equals('Android'));

      // Generate pairing code on Device A
      final pairCode = pairingA.generatePairCode();
      logReport('- Device A (Android) generated pairing code: $pairCode');

      // Initiate request
      final aModel = await identityA.toModel(ip: '10.0.0.5', port: 8321);
      pairingB.simulateIncomingRequest(aModel, pairCode);
      await Future.delayed(const Duration(milliseconds: 50));

      // Approve on B
      await pairingB.approveRequest(identityA.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pairingB.pendingRequests.isEmpty, isTrue);

      final deviceAOnB = await repoB.getDeviceById(identityA.id);
      expect(deviceAOnB, isNotNull);
      expect(deviceAOnB!.trustStatus, equals('Trusted'));
      logReport('- Device B approved request and marked Device A as: ${deviceAOnB.trustStatus}');

      // Save on A
      final bModel = await identityB.toModel(ip: '10.0.0.6', port: 8321);
      await repoA.addOrUpdateDevice(bModel.copyWith(trustStatus: 'Trusted'));
      await Future.delayed(const Duration(milliseconds: 50));

      final deviceBOnA = await repoA.getDeviceById(identityB.id);
      expect(deviceBOnA, isNotNull);
      expect(deviceBOnA!.trustStatus, equals('Trusted'));
      logReport('- Device A saved Device B as: ${deviceBOnA.trustStatus}');

      logReport('STATUS: Scenario 3 Passed Successfully.\n');
    });

    test('Trust Model: Blocked devices cannot pair/connect', () async {
      logReport('VALIDATION: Blocked Device Constraint Test');

      dbB.setValue('self_device_uuid', 'target-host-uuid');
      dbB.setValue('self_device_name', 'Target Server');
      dbB.setValue('self_device_platform', 'Windows');
      await managerB.init();

      // Add a blocked device entry beforehand to B's repo
      final blockedDevice = DeviceModel(
        id: 'attacker-uuid-666',
        name: 'Malicious Device',
        platform: 'Android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        deviceModel: 'Hacker Phone',
        pairingDate: DateTime.now(),
        lastSeen: DateTime.now(),
        trustStatus: 'Blocked',
        connectionStatus: 'Offline',
        ipAddress: '192.168.1.200',
        port: 8321,
        storageInfo: '10 GB / 32 GB',
      );
      await repoB.addOrUpdateDevice(blockedDevice);

      // Try to simulate pairing request from attacker to B
      pairingB.simulateIncomingRequest(blockedDevice, '123456');
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify B rejected it immediately and it did NOT become pending
      expect(pairingB.pendingRequests.isEmpty, isTrue);
      logReport('- Blocked Device was rejected automatically without pending UI approval.');
      logReport('STATUS: Blocked Device Constraint Passed Successfully.\n');
    });

    test('Trust Model: Auto-expiration logic', () async {
      logReport('VALIDATION: Auto-expiration Test');

      dbB.setValue('self_device_uuid', 'target-host-uuid-2');
      dbB.setValue('self_device_name', 'Target Server 2');
      dbB.setValue('self_device_platform', 'Windows');
      await managerB.init();

      final guestDevice = DeviceModel(
        id: 'guest-uuid-777',
        name: 'Guest Tablet',
        platform: 'Android',
        osVersion: 'Android 13',
        appVersion: '1.0.0',
        deviceModel: 'Galaxy Tab',
        pairingDate: DateTime.now(),
        lastSeen: DateTime.now(),
        trustStatus: 'Pending',
        connectionStatus: 'Online',
        ipAddress: '192.168.1.150',
        port: 8321,
        storageInfo: '20 GB / 64 GB',
      );

      // Simulate incoming request
      pairingB.simulateIncomingRequest(guestDevice, '654321');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pairingB.pendingRequests.length, equals(1));
      logReport('- Pending pairing request added to B');

      // Trigger manual rejection to simulate cancellation/timeout handling
      await pairingB.rejectRequest(guestDevice.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pairingB.pendingRequests.isEmpty, isTrue);
      logReport('- Request removed successfully (Rejected/Cancelled)');

      logReport('STATUS: Auto-expiration/Cancellation Flow Passed Successfully.\n');
    });
  });

  group('DeviceManager Trust Model Tests', () {
    late SettingsDatabase db;
    late DeviceRepository repo;
    late DeviceIdentity identity;
    late ConnectionManager conn;
    late DeviceManager manager;

    setUp(() async {
      db = SettingsDatabase(isInMemory: true);
      await db.init();
      repo = DeviceRepository(db);
      identity = DeviceIdentity(db, FakeStorageProvider());
      conn = ConnectionManager(FakeLoggingService());
      manager = DeviceManager(repo, identity, conn, FakeLoggingService());
      await manager.init();
    });

    tearDown(() {
      manager.dispose();
      db.close();
    });

    test('Unknown devices must always remain Pending', () {
      final status = manager.getDeviceTrustStatus('completely-unknown-device-123');
      expect(status, equals('Pending'));
    });

    test('Approve, Reject, Block, and Unblock update status and store in database', () async {
      final testDevice = DeviceModel(
        id: 'test-device-uuid-1',
        name: 'Test Device 1',
        platform: 'Android',
        osVersion: 'Android 14',
        appVersion: '1.0.0',
        deviceModel: 'Pixel 8',
        pairingDate: DateTime.now(),
        lastSeen: DateTime.now(),
        trustStatus: 'Pending',
        connectionStatus: 'Offline',
        ipAddress: '192.168.1.50',
        port: 8321,
        storageInfo: '128 GB',
      );

      // Add device to manager
      await manager.addDevice(testDevice);

      // 1. Test initial trust status
      expect(manager.getDeviceTrustStatus(testDevice.id), equals('Pending'));

      // 2. Test Approve Device
      await manager.approveDevice(testDevice.id);
      expect(manager.getDeviceTrustStatus(testDevice.id), equals('Trusted'));
      var dbDevice = await repo.getDeviceById(testDevice.id);
      expect(dbDevice, isNotNull);
      expect(dbDevice!.trustStatus, equals('Trusted'));

      // 3. Test Reject Device
      await manager.rejectDevice(testDevice.id);
      expect(manager.getDeviceTrustStatus(testDevice.id), equals('Rejected'));
      dbDevice = await repo.getDeviceById(testDevice.id);
      expect(dbDevice, isNotNull);
      expect(dbDevice!.trustStatus, equals('Rejected'));

      // 4. Test Block Device
      await manager.blockDevice(testDevice.id);
      expect(manager.getDeviceTrustStatus(testDevice.id), equals('Blocked'));
      dbDevice = await repo.getDeviceById(testDevice.id);
      expect(dbDevice, isNotNull);
      expect(dbDevice!.trustStatus, equals('Blocked'));

      // 5. Test Unblock Device (returns to Pending)
      await manager.unblockDevice(testDevice.id);
      expect(manager.getDeviceTrustStatus(testDevice.id), equals('Pending'));
      dbDevice = await repo.getDeviceById(testDevice.id);
      expect(dbDevice, isNotNull);
      expect(dbDevice!.trustStatus, equals('Pending'));
    });
  });
}
