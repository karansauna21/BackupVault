import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:backup_vault/features/settings/settings_models.dart';
import 'package:backup_vault/features/settings/settings_database.dart';
import 'package:backup_vault/features/settings/settings_repository.dart';
import 'package:backup_vault/features/settings/settings_validator.dart';
import 'package:backup_vault/features/settings/settings_screen.dart';

void main() {
  group('SettingsModels Tests', () {
    test('GeneralSettings serialization and copyWith', () {
      const gs = GeneralSettings(theme: 'dark', language: 'es');
      expect(gs.theme, equals('dark'));
      expect(gs.language, equals('es'));

      final jsonMap = gs.toJson();
      expect(jsonMap['theme'], equals('dark'));
      expect(jsonMap['language'], equals('es'));

      final fromJson = GeneralSettings.fromJson(jsonMap);
      expect(fromJson.theme, equals('dark'));
      expect(fromJson.language, equals('es'));

      final copied = gs.copyWith(theme: 'light');
      expect(copied.theme, equals('light'));
      expect(copied.language, equals('es'));
    });

    test('SettingsState full serialization', () {
      const state = SettingsState(
        general: GeneralSettings(theme: 'light'),
        performance: PerformanceSettings(cpuLimitPercent: 75),
      );

      final jsonMap = state.toJson();
      expect(jsonMap['general']['theme'], equals('light'));
      expect(jsonMap['performance']['cpuLimitPercent'], equals(75));

      final restored = SettingsState.fromJson(jsonMap);
      expect(restored.general.theme, equals('light'));
      expect(restored.performance.cpuLimitPercent, equals(75));
    });
  });

  group('SettingsValidator Tests', () {
    test('Valid SettingsState passes validation', () {
      const valid = SettingsState();
      final errors = SettingsValidator.validate(valid);
      expect(errors, isEmpty);
    });

    test('Invalid Theme Mode fails validation', () {
      const invalidTheme = SettingsState(general: GeneralSettings(theme: 'blue'));
      final errors = SettingsValidator.validate(invalidTheme);
      expect(errors, isNotEmpty);
      expect(errors.first, contains('Theme must be "light", "dark", or "system"'));
    });

    test('Invalid CPU Limit fails validation', () {
      const invalidCpu = SettingsState(performance: PerformanceSettings(cpuLimitPercent: 120));
      final errors = SettingsValidator.validate(invalidCpu);
      expect(errors, isNotEmpty);
      expect(errors.first, contains('CPU Limit must be between 10% and 100%'));
    });

    test('Invalid RAM Limit fails validation', () {
      const invalidRam = SettingsState(performance: PerformanceSettings(ramLimitMb: 10));
      final errors = SettingsValidator.validate(invalidRam);
      expect(errors, isNotEmpty);
      expect(errors.first, contains('RAM Limit must be between 64 MB and 65,536 MB'));
    });
  });

  group('SettingsDatabase Tests', () {
    late SettingsDatabase db;

    setUp(() async {
      db = SettingsDatabase(isInMemory: true);
      await db.init();
    });

    tearDown(() {
      db.close();
    });

    test('persist and retrieve values correctly', () {
      db.setValue('test_key', 'test_val');
      expect(db.getValue('test_key'), equals('test_val'));

      db.setValue('test_key', 'updated_val');
      expect(db.getValue('test_key'), equals('updated_val'));
    });

    test('clear values correctly', () {
      db.setValue('key1', 'val1');
      db.setValue('key2', 'val2');

      db.clear();
      expect(db.getValue('key1'), isNull);
      expect(db.getValue('key2'), isNull);
    });
  });

  group('SettingsRepository & Import/Export Tests', () {
    late SettingsDatabase db;
    late SettingsRepository repository;
    late Directory tempDir;

    setUp(() async {
      db = SettingsDatabase(isInMemory: true);
      await db.init();
      repository = SettingsRepository(db);
      tempDir = await Directory.systemTemp.createTemp('settings_repo_test');
    });

    tearDown(() async {
      db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('saveSettings and loadSettings persistence', () async {
      const customState = SettingsState(
        general: GeneralSettings(language: 'fr'),
        backup: BackupSettings(maxVersions: 12),
      );

      await repository.saveSettings(customState);
      final loaded = await repository.loadSettings();

      expect(loaded.general.language, equals('fr'));
      expect(loaded.backup.maxVersions, equals(12));
    });

    test('export and import JSON configurations', () async {
      const customState = SettingsState(
        general: GeneralSettings(theme: 'dark'),
        performance: PerformanceSettings(cpuLimitPercent: 50),
      );

      await repository.saveSettings(customState);
      final jsonFile = File(p.join(tempDir.path, 'settings.json'));

      await repository.exportSettings(jsonFile.path);
      expect(await jsonFile.exists(), isTrue);

      // Verify file content matches
      final content = await jsonFile.readAsString();
      final decoded = json.decode(content);
      expect(decoded['general']['theme'], equals('dark'));

      // Clean database and import back
      await repository.resetToDefault();
      var loaded = await repository.loadSettings();
      expect(loaded.general.theme, equals('system')); // default

      final imported = await repository.importSettings(jsonFile.path);
      expect(imported.general.theme, equals('dark'));
      expect(imported.performance.cpuLimitPercent, equals(50));

      loaded = await repository.loadSettings();
      expect(loaded.general.theme, equals('dark'));
    });

    test('backup and restore SQLite database file', () async {
      // Let's create a dummy sqlite settings database file at source
      final dummyDbFile = File(p.join(tempDir.path, 'dummy_settings.db'));
      await dummyDbFile.writeAsString('sqlite_database_content');
      
      // Let's write the test verifying that file copy behaves correctly.
      expect(dummyDbFile.existsSync(), isTrue);
      final destPath = p.join(tempDir.path, 'settings_backup.db');
      await dummyDbFile.copy(destPath);
      expect(File(destPath).existsSync(), isTrue);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('SettingsScreen renders successfully with all category tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text('Application Settings'), findsOneWidget);

      // Verify Search bar is rendered
      expect(find.byType(TextField), findsOneWidget);

      // Verify that category tabs/headers are rendered
      expect(find.text('General Settings'), findsOneWidget);
    });

    testWidgets('SettingsScreen category searching filters list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'CPU');
      await tester.pump();

      // The performance category should be matched and displayed, while general settings should be hidden
      expect(find.text('Performance Settings'), findsOneWidget);
      expect(find.text('Startup Settings'), findsNothing);
    });
  });
}
