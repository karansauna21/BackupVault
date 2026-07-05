import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'configuration_provider.dart';
import 'configuration_models.dart';

class ConfigurationController {
  final Ref ref;

  ConfigurationController(this.ref);

  Future<void> exportConfig({
    required String destinationPath,
    required bool includeLogs,
    required String appVersion,
    required String platformName,
  }) async {
    await ref.read(exportStateProvider.notifier).exportConfig(
      destinationPath: destinationPath,
      includeLogs: includeLogs,
      appVersion: appVersion,
      platformName: platformName,
    );
  }

  Future<ValidationResult> validateBackupFile(String zipPath) async {
    return await ref.read(validationStateProvider.notifier).validatePackage(zipPath);
  }

  Future<void> importConfig({
    required String zipPath,
    required bool restoreSettings,
    required bool restoreFolders,
    required bool restoreSchedules,
    required bool restoreLogs,
    required String appVersion,
    required String platformName,
  }) async {
    await ref.read(importStateProvider.notifier).importConfig(
      zipPath: zipPath,
      restoreSettings: restoreSettings,
      restoreFolders: restoreFolders,
      restoreSchedules: restoreSchedules,
      restoreLogs: restoreLogs,
      appVersion: appVersion,
      platformName: platformName,
    );
  }

  Future<void> clearHistory() async {
    await ref.read(configurationHistoryProvider.notifier).clearHistory();
  }
}

final configurationControllerProvider = Provider<ConfigurationController>((ref) {
  return ConfigurationController(ref);
});
