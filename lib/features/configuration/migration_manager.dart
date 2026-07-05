import 'configuration_models.dart';

class MigrationManager {
  /// Migrate backup package from older schema to current schema (version 4)
  ConfigurationPackage migrate(ConfigurationPackage package) {
    final metadata = package.metadata;
    final content = Map<String, dynamic>.from(package.content);

    if (metadata.databaseVersion < 4) {
      // Perform structural transformations
      if (content.containsKey('schedules')) {
        final List schedulesList = content['schedules'] as List;
        final migratedSchedules = schedulesList.map((s) {
          if (s is! Map) return s;
          final sMap = Map<String, dynamic>.from(s);
          if (sMap.containsKey('rules')) {
            final rules = sMap['rules'];
            if (rules is Map) {
              final rulesMap = Map<String, dynamic>.from(rules);
              // Inject default fields for Prompt 17 if missing
              rulesMap.putIfAbsent('backupOnlyWhileCharging', () => false);
              rulesMap.putIfAbsent('pauseOnBattery', () => false);
              rulesMap.putIfAbsent('resumeOnCharging', () => true);
              rulesMap.putIfAbsent('backupOnlyOnWifi', () => false);
              rulesMap.putIfAbsent('backupOnlyWhenIdle', () => false);
              rulesMap.putIfAbsent('pauseDuringFullScreenApps', () => false);
              rulesMap.putIfAbsent('weekendOnly', () => false);
              rulesMap.putIfAbsent('weekdaysOnly', () => false);
              rulesMap.putIfAbsent('holidaySupport', () => false);
              rulesMap.putIfAbsent('randomDelayMinutes', () => 0);
              rulesMap.putIfAbsent('maxRuntimeMinutes', () => 0);
              rulesMap.putIfAbsent('retryDelayMinutes', () => 5);
              sMap['rules'] = rulesMap;
            }
          }
          return sMap;
        }).toList();
        content['schedules'] = migratedSchedules;
      }
    }

    final newMetadata = ConfigMetadata(
      appVersion: '1.0.0', // Target app version
      databaseVersion: 4,  // Current database version
      exportDate: metadata.exportDate,
      exportDevice: metadata.exportDevice,
      platform: metadata.platform,
      checksum: metadata.checksum,
    );

    return ConfigurationPackage(
      metadata: newMetadata,
      content: content,
    );
  }
}
