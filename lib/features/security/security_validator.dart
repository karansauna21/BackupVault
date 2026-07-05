import 'security_models.dart';

class SecurityValidator {
  /// Scan security configurations for security risks and warnings
  List<String> scanConfigurationRisks(SecurityConfig config) {
    final List<String> risks = [];

    if (!config.encryptionEnabled) {
      risks.add('Data encryption is disabled. Backed up files are stored in plaintext.');
    }

    if (config.encryptionEnabled && config.currentKeyId == null) {
      risks.add('Encryption is enabled but no active key is selected.');
    }

    if (!config.passwordProtected) {
      risks.add('Application password protection is disabled. Settings and files are unprotected.');
    }

    if (config.passwordProtected) {
      if (!config.protectSettings) {
        risks.add('Application Settings are not password protected.');
      }
      if (!config.protectRestore) {
        risks.add('Restore operations are not password protected. Unauthorised restores possible.');
      }
      if (!config.protectExport) {
        risks.add('Configuration exports are not password protected.');
      }
    }

    return risks;
  }

  /// Scan general warnings
  List<String> generateWarnings(SecurityConfig config, int keysCount) {
    final List<String> warnings = [];
    
    if (config.encryptionEnabled && keysCount == 0) {
      warnings.add('No keys available for encryption.');
    }

    if (config.passwordProtected && (config.passwordHint == null || config.passwordHint!.trim().isEmpty)) {
      warnings.add('No password hint is set. If you forget your password, you may lose access.');
    }

    return warnings;
  }
}
