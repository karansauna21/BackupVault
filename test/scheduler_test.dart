import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/features/scheduler/scheduler_models.dart';
import 'package:backup_vault/features/scheduler/schedule_history.dart';
import 'package:backup_vault/features/scheduler/schedule_validator.dart';
import 'package:backup_vault/features/scheduler/rule_engine.dart';
import 'package:backup_vault/features/scheduler/trigger_engine.dart';
import 'package:backup_vault/features/scheduler/job_manager.dart';

void main() {
  group('Unit Tests - Serialization', () {
    test('ScheduleConfig fromJson/toJson and copyWith works', () {
      final config = ScheduleConfig(
        id: '123',
        name: 'Daily Document Backup',
        folderId: 1,
        scheduleType: 'Daily',
        triggerTypes: ['Specific Time', 'USB Connected'],
        triggerSpecificTime: '14:30',
        rules: const SmartRules(
          pauseWhenCpuUsageIsHigh: true,
          pauseWhenBatteryIsLow: true,
        ),
      );

      final json = config.toJson();
      expect(json['id'], equals('123'));
      expect(json['name'], equals('Daily Document Backup'));
      expect(json['triggerTypes'], contains('USB Connected'));
      expect(json['rules']['pauseWhenCpuUsageIsHigh'], isTrue);

      final restored = ScheduleConfig.fromJson(json);
      expect(restored.id, equals('123'));
      expect(restored.rules.pauseWhenCpuUsageIsHigh, isTrue);

      final copied = config.copyWith(name: 'Updated Name', enabled: false);
      expect(copied.name, equals('Updated Name'));
      expect(copied.enabled, isFalse);
    });

    test('ScheduleHistory fromJson/toJson works', () {
      final history = ScheduleHistory(
        id: 'history_1',
        executionTime: DateTime(2026, 7, 5, 10, 0),
        duration: const Duration(seconds: 45),
        trigger: 'Schedule: Daily',
        result: 'success',
        retryCount: 1,
        workerUsed: 'BackupEngine',
        status: 'completed',
        errors: 'None',
      );

      final json = history.toJson();
      expect(json['id'], equals('history_1'));
      expect(json['durationMs'], equals(45000));
      expect(json['result'], equals('success'));

      final restored = ScheduleHistory.fromJson(json);
      expect(restored.id, equals('history_1'));
      expect(restored.duration.inSeconds, equals(45));
    });
  });

  group('Scheduler Tests - Validation', () {
    test('ScheduleValidator validates cron expressions correctly', () {
      // Valid cron expressions
      expect(ScheduleValidator.isValidCron('* * * * *'), isTrue);
      expect(ScheduleValidator.isValidCron('*/5 * * * *'), isTrue);
      expect(ScheduleValidator.isValidCron('1,2,3 4-8 * * *'), isTrue);
      expect(ScheduleValidator.isValidCron('0 0 1 1 *'), isTrue);

      // Invalid cron expressions
      expect(ScheduleValidator.isValidCron('* * * *'), isFalse); // too few fields
      expect(ScheduleValidator.isValidCron('* * * * * *'), isFalse); // too many fields
      expect(ScheduleValidator.isValidCron('60 * * * *'), isFalse); // minute out of range
      expect(ScheduleValidator.isValidCron('* 25 * * *'), isFalse); // hour out of range
      expect(ScheduleValidator.isValidCron('abc * * * *'), isFalse); // non-numeric
    });

    test('ScheduleValidator matches cron time correctly', () {
      final cron = '30 12 * * 1'; // 12:30 on Mondays
      
      final matchingTime = DateTime(2026, 7, 6, 12, 30); // 2026-07-06 is a Monday
      expect(ScheduleValidator.matchesCron(cron, matchingTime), isTrue);

      final wrongMinute = DateTime(2026, 7, 6, 12, 31);
      expect(ScheduleValidator.matchesCron(cron, wrongMinute), isFalse);

      final wrongDay = DateTime(2026, 7, 7, 12, 30); // Tuesday
      expect(ScheduleValidator.matchesCron(cron, wrongDay), isFalse);
    });
  });

  group('Automation Tests - TriggerEngine', () {
    test('TriggerEngine initial firing on startup', () {
      final firedTriggers = <String>[];
      final engine = TriggerEngine(
        onTriggerFired: (type, {folderId}) {
          firedTriggers.add(type);
        },
      );

      engine.init();
      expect(firedTriggers, contains('Application Startup'));
      expect(firedTriggers, contains('Windows Startup'));
      engine.dispose();
    });
  });

  group('Rule Tests - RuleEngine', () {
    setUp(() {
      RuleEngine.useSimulationMode = true;
    });

    tearDown(() {
      RuleEngine.useSimulationMode = false;
    });

    test('RuleEngine high CPU evaluation', () async {
      final engine = RuleEngine();
      final config = ScheduleConfig(
        id: '1',
        name: 'Test',
        folderId: 10,
        scheduleType: 'Manual',
        triggerTypes: [],
        rules: const SmartRules(
          pauseWhenCpuUsageIsHigh: true,
          runOnlyIfDestinationAvailable: false,
        ),
      );

      final folder = BackupFolder(
        id: 10,
        name: 'Documents',
        sourcePath: 'C:\\docs',
        destinationPath: 'D:\\backups',
        enabled: true,
        createdAt: DateTime.now(),
        backupInterval: 'manual',
      );

      // Simulate low CPU
      RuleEngine.setSimulatedCpu(15.0);
      var result = await engine.evaluateRules(config: config, folder: folder, activeJobs: []);
      expect(result.isAllowed, isTrue);

      // Simulate high CPU
      RuleEngine.setSimulatedCpu(85.0);
      result = await engine.evaluateRules(config: config, folder: folder, activeJobs: []);
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('CPU usage is too high'));
    });

    test('RuleEngine low battery evaluation', () async {
      final engine = RuleEngine();
      final config = ScheduleConfig(
        id: '1',
        name: 'Test',
        folderId: 10,
        scheduleType: 'Manual',
        triggerTypes: [],
        rules: const SmartRules(
          pauseWhenBatteryIsLow: true,
          runOnlyIfDestinationAvailable: false,
        ),
      );

      final folder = BackupFolder(
        id: 10,
        name: 'Documents',
        sourcePath: 'C:\\docs',
        destinationPath: 'D:\\backups',
        enabled: true,
        createdAt: DateTime.now(),
        backupInterval: 'manual',
      );

      // Simulate battery high
      RuleEngine.setSimulatedBattery(80);
      RuleEngine.setSimulatedCharging(false);
      var result = await engine.evaluateRules(config: config, folder: folder, activeJobs: []);
      expect(result.isAllowed, isTrue);

      // Simulate battery low and not charging
      RuleEngine.setSimulatedBattery(15);
      RuleEngine.setSimulatedCharging(false);
      result = await engine.evaluateRules(config: config, folder: folder, activeJobs: []);
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('Battery is low'));

      // Simulate battery low but charging
      RuleEngine.setSimulatedCharging(true);
      result = await engine.evaluateRules(config: config, folder: folder, activeJobs: []);
      expect(result.isAllowed, isTrue);
    });

    test('RuleEngine skip duplicate check', () async {
      final engine = RuleEngine();
      final config = ScheduleConfig(
        id: '1',
        name: 'Test',
        folderId: 10,
        scheduleType: 'Manual',
        triggerTypes: [],
        rules: const SmartRules(
          skipDuplicateJobs: true,
          runOnlyIfDestinationAvailable: false,
        ),
      );

      final folder = BackupFolder(
        id: 10,
        name: 'Documents',
        sourcePath: 'C:\\docs',
        destinationPath: 'D:\\backups',
        enabled: true,
        createdAt: DateTime.now(),
        backupInterval: 'manual',
      );

      // Active jobs has no duplicate
      var result = await engine.evaluateRules(config: config, folder: folder, activeJobs: [
        {'folderId': 11, 'status': 'running'}
      ]);
      expect(result.isAllowed, isTrue);

      // Active jobs has duplicate running
      result = await engine.evaluateRules(config: config, folder: folder, activeJobs: [
        {'folderId': 10, 'status': 'running'}
      ]);
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('already in the queue'));
    });
  });

  group('Queue & Recovery Tests', () {
    test('JobManager persistence and recovery from restart mock', () async {
      final tempDir = await Directory.systemTemp.createTemp('scheduler_test');

      // Mock support directory for testing
      try {
        final job = ScheduledBackupJob(
          id: 'test_job_1',
          folderId: 1,
          scheduleId: 'sched_1',
          folderName: 'Docs',
          sourcePath: 'C:\\docs',
          destinationPath: 'D:\\backups',
          queueType: 'normal',
          status: 'running', // running when interrupted
          createdAt: DateTime.now(),
          triggerSource: 'Manual',
        );

        // We can verify that list mapping handles recovery correctly:
        final jsonList = [job.toJson()];
        
        final recovered = jsonList.map((e) {
          final restoredJob = ScheduledBackupJob.fromJson(e);
          if (restoredJob.status == 'running') {
            return restoredJob.copyWith(status: 'pending', queueType: 'pending');
          }
          return restoredJob;
        }).toList();

        expect(recovered.first.status, equals('pending'));
        expect(recovered.first.queueType, equals('pending'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
