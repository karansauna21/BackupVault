import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'configuration_models.dart';

class BackupValidator {
  ValidationResult validatePackage(ConfigurationPackage package) {
    final List<String> errors = [];
    final List<String> warnings = [];

    // 1. Check Missing Fields
    if (package.metadata.appVersion.isEmpty) {
      errors.add('Missing metadata field: appVersion');
    }
    if (package.metadata.checksum.isEmpty) {
      errors.add('Missing metadata field: checksum');
    }

    // 2. Validate Checksum
    final contentString = json.encode(package.content);
    final bytes = utf8.encode(contentString);
    final computedHash = sha256.convert(bytes).toString();

    if (package.metadata.checksum.isNotEmpty && package.metadata.checksum != computedHash) {
      errors.add('Checksum verification failed. Backup package may be corrupted or modified.');
    }

    // 3. Database & Version Compatibility checks
    final backupDbVersion = package.metadata.databaseVersion;
    if (backupDbVersion > 4) {
      errors.add('Backup database version ($backupDbVersion) is newer than the currently supported version (4).');
    } else if (backupDbVersion < 4) {
      warnings.add('Backup database version ($backupDbVersion) is older. Schema migration will run automatically.');
    }

    // 4. Schema/structure validation
    if (!package.content.containsKey('settings')) {
      errors.add('Missing config section: settings');
    }
    if (!package.content.containsKey('folders')) {
      errors.add('Missing config section: folders');
    }
    if (!package.content.containsKey('schedules')) {
      errors.add('Missing config section: schedules');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      appVersion: package.metadata.appVersion,
      databaseVersion: package.metadata.databaseVersion,
    );
  }
}
