import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';

import 'package:backup_vault/features/configuration/configuration_models.dart';
import 'package:backup_vault/features/configuration/backup_validator.dart';
import 'package:backup_vault/features/configuration/migration_manager.dart';
import 'package:backup_vault/features/configuration/configuration_screen.dart';

void main() {
  group('Configuration Models & Serialization Tests', () {
    test('ConfigMetadata serialization fromJson/toJson works', () {
      final metadata = ConfigMetadata(
        appVersion: '1.0.0',
        databaseVersion: 4,
        exportDate: DateTime(2026, 7, 5),
        exportDevice: 'TestDevice',
        platform: 'windows',
        checksum: 'abc123hash',
      );

      final json = metadata.toJson();
      expect(json['appVersion'], equals('1.0.0'));
      expect(json['databaseVersion'], equals(4));
      expect(json['checksum'], equals('abc123hash'));

      final restored = ConfigMetadata.fromJson(json);
      expect(restored.appVersion, equals('1.0.0'));
      expect(restored.databaseVersion, equals(4));
      expect(restored.checksum, equals('abc123hash'));
    });

    test('ValidationResult serialization works', () {
      final val = ValidationResult(
        isValid: false,
        errors: ['Missing settings', 'Invalid checksum'],
        warnings: ['Old app version'],
        appVersion: '1.0.0',
        databaseVersion: 4,
      );

      final json = val.toJson();
      expect(json['isValid'], isFalse);
      expect(json['errors'], contains('Missing settings'));

      final restored = ValidationResult.fromJson(json);
      expect(restored.isValid, isFalse);
      expect(restored.errors, contains('Invalid checksum'));
    });
  });

  group('BackupValidator & Checksum Tests', () {
    final validator = BackupValidator();

    test('Passes validation when package is fully formatted and checksum matches', () {
      final content = {
        'settings': {'theme': 'dark'},
        'folders': [],
        'schedules': [],
      };
      
      final contentString = json.encode(content);
      final bytes = utf8.encode(contentString);
      final hash = sha256.convert(bytes).toString();

      final package = ConfigurationPackage(
        metadata: ConfigMetadata(
          appVersion: '1.0.0',
          databaseVersion: 4,
          exportDate: DateTime.now(),
          exportDevice: 'Windows',
          platform: 'windows',
          checksum: hash,
        ),
        content: content,
      );

      final result = validator.validatePackage(package);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Fails validation when checksum mismatch occurs', () {
      final content = {
        'settings': {'theme': 'dark'},
        'folders': [],
        'schedules': [],
      };

      final package = ConfigurationPackage(
        metadata: ConfigMetadata(
          appVersion: '1.0.0',
          databaseVersion: 4,
          exportDate: DateTime.now(),
          exportDevice: 'Windows',
          platform: 'windows',
          checksum: 'wrong_checksum',
        ),
        content: content,
      );

      final result = validator.validatePackage(package);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Checksum verification failed. Backup package may be corrupted or modified.'));
    });
  });

  group('MigrationManager Tests', () {
    final migrationManager = MigrationManager();

    test('Performs migration and upgrades database version and adds missing prompt rules', () {
      final oldPackage = ConfigurationPackage(
        metadata: ConfigMetadata(
          appVersion: '0.9.0',
          databaseVersion: 3, // older DB version
          exportDate: DateTime.now(),
          exportDevice: 'Device',
          platform: 'windows',
          checksum: '',
        ),
        content: {
          'settings': {},
          'folders': [],
          'schedules': [
            {
              'id': '1',
              'name': 'Daily Backup',
              'rules': {
                'pauseWhenCpuUsageIsHigh': true,
              }
            }
          ],
        },
      );

      final migrated = migrationManager.migrate(oldPackage);
      expect(migrated.metadata.databaseVersion, equals(4));
      
      final schedules = migrated.content['schedules'] as List;
      final schedule = schedules.first as Map;
      final rules = schedule['rules'] as Map;
      
      // Verifying injected Prompt 17 properties
      expect(rules['backupOnlyWhileCharging'], isFalse);
      expect(rules['pauseOnBattery'], isFalse);
      expect(rules['retryDelayMinutes'], equals(5));
    });
  });

  group('Widget Tests - ConfigurationScreen', () {
    testWidgets('ConfigurationScreen renders tabs and fields correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConfigurationScreen(),
          ),
        ),
      );

      // Verify Tab titles exist
      expect(find.text('Export Wizard'), findsOneWidget);
      expect(find.text('Import Wizard'), findsOneWidget);
      expect(find.text('History & Logs'), findsOneWidget);

      // Verify export path exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Generate Configuration Package'), findsOneWidget);

      // Tap on Import Wizard tab
      await tester.tap(find.text('Import Wizard'));
      await tester.pumpAndSettle();

      expect(find.text('Validate & Preview Package'), findsOneWidget);
    });
  });
}
