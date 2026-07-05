import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logging_service.dart';
import 'security_models.dart';
import 'security_provider.dart';

class SecurityController {
  final Ref ref;

  SecurityController(this.ref);

  /// Change/Setup password protection
  Future<void> changePassword(String newPassword, String hint) async {
    final passwordManager = ref.read(passwordManagerProvider);
    final config = ref.read(securityConfigProvider);
    
    if (!passwordManager.validatePasswordStrength(newPassword, config)) {
      throw Exception('Password does not meet the complexity requirements.');
    }

    final hash = passwordManager.hashPassword(newPassword);
    final updated = config.copyWith(
      passwordProtected: true,
      hashedPassword: hash,
      passwordHint: hint,
    );

    await ref.read(securityConfigProvider.notifier).updateConfig(updated);
    await ref.read(loggingServiceProvider).info('Security', 'Password Changed successfully.');
  }

  /// Remove password protection
  Future<void> removePassword() async {
    final config = ref.read(securityConfigProvider);
    final updated = config.copyWith(
      passwordProtected: false,
      hashedPassword: null,
      passwordHint: null,
    );

    await ref.read(securityConfigProvider.notifier).updateConfig(updated);
    await ref.read(loggingServiceProvider).info('Security', 'Password Changed: Protection Disabled.');
  }

  /// Verify entered password
  bool verifyPassword(String inputPassword) {
    final config = ref.read(securityConfigProvider);
    if (!config.passwordProtected || config.hashedPassword == null) return true;

    final passwordManager = ref.read(passwordManagerProvider);
    return passwordManager.verifyPassword(inputPassword, config.hashedPassword!);
  }

  /// Enable or toggle data encryption
  Future<void> enableEncryption(String keyId) async {
    final config = ref.read(securityConfigProvider);
    final updated = config.copyWith(
      encryptionEnabled: true,
      currentKeyId: keyId,
    );

    await ref.read(securityConfigProvider.notifier).updateConfig(updated);
    await ref.read(loggingServiceProvider).info('Security', 'Encryption Enabled with key: $keyId');
  }

  /// Disable data encryption
  Future<void> disableEncryption() async {
    final config = ref.read(securityConfigProvider);
    final updated = config.copyWith(
      encryptionEnabled: false,
    );

    await ref.read(securityConfigProvider.notifier).updateConfig(updated);
    await ref.read(loggingServiceProvider).info('Security', 'Encryption Disabled.');
  }

  /// Rotate and activate encryption key
  Future<void> rotateKey(String id) async {
    final keyManager = ref.read(keyManagerProvider);
    await keyManager.rotateKey(id);
    ref.read(keysNotifierProvider.notifier).refresh();
    await ref.read(loggingServiceProvider).info('Security', 'Key Rotated: $id');
  }

  /// Generate a new secure encryption key
  Future<EncryptionKey> generateKey(String name) async {
    final keyManager = ref.read(keyManagerProvider);
    final key = await keyManager.generateKey(name);
    ref.read(keysNotifierProvider.notifier).refresh();
    await ref.read(loggingServiceProvider).info('Security', 'Key Created: ${key.name}');
    return key;
  }

  /// Delete a key (requires inactive key warning check)
  Future<void> deleteKey(String id) async {
    final keyManager = ref.read(keyManagerProvider);
    await keyManager.deleteKey(id);
    ref.read(keysNotifierProvider.notifier).refresh();
    await ref.read(loggingServiceProvider).info('Security', 'Key Deleted: $id');
  }

  /// Export keys package JSON
  String exportKeys(List<String> keyIds) {
    final keyManager = ref.read(keyManagerProvider);
    return keyManager.exportKeysPackage(keyIds);
  }

  /// Import keys package JSON
  Future<int> importKeys(String jsonString) async {
    final keyManager = ref.read(keyManagerProvider);
    final imported = await keyManager.importKeysPackage(jsonString);
    if (imported.isNotEmpty) {
      ref.read(keysNotifierProvider.notifier).refresh();
      await ref.read(loggingServiceProvider).info('Security', 'Imported ${imported.length} encryption keys.');
    }
    return imported.length;
  }

  /// Update password protection areas
  Future<void> updateProtectionToggles({
    required bool settings,
    required bool security,
    required bool restore,
    required bool export,
  }) async {
    final config = ref.read(securityConfigProvider);
    final updated = config.copyWith(
      protectSettings: settings,
      protectSecurity: security,
      protectRestore: restore,
      protectExport: export,
    );

    await ref.read(securityConfigProvider.notifier).updateConfig(updated);
  }
}

final securityControllerProvider = Provider<SecurityController>((ref) {
  return SecurityController(ref);
});

class SecurityAuthGuard {
  static Future<bool> verify(BuildContext context, WidgetRef ref, {required bool checkArea}) async {
    final config = ref.read(securityConfigProvider);
    if (!config.passwordProtected || !checkArea) return true;

    final TextEditingController controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.blue),
              SizedBox(width: 12),
              Text('Security Authentication'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This area is password protected. Please enter your password to continue.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (config.passwordHint != null && config.passwordHint!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Hint: ${config.passwordHint}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final input = controller.text;
                final isMatch = ref.read(securityControllerProvider).verifyPassword(input);
                Navigator.pop(context, isMatch);
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
