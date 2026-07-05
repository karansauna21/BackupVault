import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'security_models.dart';
import 'security_repository.dart';
import 'password_manager.dart';
import 'key_manager.dart';
import 'encryption_manager.dart';
import 'integrity_manager.dart';
import 'database_protection.dart';
import 'security_validator.dart';

// Repository
final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  final repo = SecurityRepository();
  return repo;
});

// Managers & Helpers
final passwordManagerProvider = Provider<PasswordManager>((ref) {
  return PasswordManager();
});

final keyManagerProvider = Provider<KeyManager>((ref) {
  final repo = ref.watch(securityRepositoryProvider);
  return KeyManager(repo);
});

final encryptionManagerProvider = Provider<EncryptionManager>((ref) {
  final repo = ref.watch(securityRepositoryProvider);
  return EncryptionManager(repo);
});

final integrityManagerProvider = Provider<IntegrityManager>((ref) {
  return IntegrityManager();
});

final databaseProtectionProvider = Provider<DatabaseProtection>((ref) {
  final integrity = ref.watch(integrityManagerProvider);
  return DatabaseProtection(integrity);
});

final securityValidatorProvider = Provider<SecurityValidator>((ref) {
  return SecurityValidator();
});

// Security Configuration Notifier
class SecurityConfigNotifier extends Notifier<SecurityConfig> {
  late final SecurityRepository _repo;

  @override
  SecurityConfig build() {
    _repo = ref.watch(securityRepositoryProvider);
    bool disposed = false;
    ref.onDispose(() => disposed = true);
    _repo.init().then((_) {
      if (!disposed) {
        state = _repo.config;
        ref.read(keysNotifierProvider.notifier).refresh();
        ref.read(auditsNotifierProvider.notifier).refresh();
      }
    });
    return const SecurityConfig();
  }

  Future<void> updateConfig(SecurityConfig config) async {
    await _repo.saveConfig(config);
    state = config;
  }
}

final securityConfigProvider = NotifierProvider<SecurityConfigNotifier, SecurityConfig>(() {
  return SecurityConfigNotifier();
});

// Keys list notifier
class KeysNotifier extends Notifier<List<EncryptionKey>> {
  late final SecurityRepository _repo;

  @override
  List<EncryptionKey> build() {
    _repo = ref.watch(securityRepositoryProvider);
    return [];
  }

  void refresh() {
    state = List<EncryptionKey>.from(_repo.keys);
  }

  Future<void> addKey(EncryptionKey key) async {
    await _repo.addKey(key);
    refresh();
  }

  Future<void> deleteKey(String id) async {
    await _repo.deleteKey(id);
    refresh();
  }
}

final keysNotifierProvider = NotifierProvider<KeysNotifier, List<EncryptionKey>>(() {
  return KeysNotifier();
});

// Audits list notifier
class AuditsNotifier extends Notifier<List<AuditReport>> {
  late final SecurityRepository _repo;

  @override
  List<AuditReport> build() {
    _repo = ref.watch(securityRepositoryProvider);
    return [];
  }

  void refresh() {
    state = List<AuditReport>.from(_repo.audits);
  }

  Future<void> runAudit(int totalFiles, int encryptedFiles, int unencryptedFiles) async {
    final config = ref.read(securityConfigProvider);
    final validator = ref.read(securityValidatorProvider);
    final risks = validator.scanConfigurationRisks(config);
    final warnings = validator.generateWarnings(config, _repo.keys.length);

    final report = AuditReport(
      generatedAt: DateTime.now(),
      totalFiles: totalFiles,
      encryptedFiles: encryptedFiles,
      unencryptedFiles: unencryptedFiles,
      verificationSuccessCount: totalFiles - unencryptedFiles,
      verificationFailedCount: 0,
      tamperedCount: 0,
      warnings: warnings,
      risks: risks,
    );

    await _repo.addAuditReport(report);
    refresh();
  }

  Future<void> clearAudits() async {
    await _repo.clearAudits();
    refresh();
  }
}

final auditsNotifierProvider = NotifierProvider<AuditsNotifier, List<AuditReport>>(() {
  return AuditsNotifier();
});
