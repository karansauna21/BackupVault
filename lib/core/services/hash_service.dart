import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/security/security_provider.dart';

class HashService {
  final Ref? ref;

  HashService([this.ref]);

  Future<String> calculateSha256(File file) async {
    if (!await file.exists()) return '';
    try {
      final bytes = await file.readAsBytes();
      if (ref != null) {
        final encManager = ref!.read(encryptionManagerProvider);
        if (encManager.isEncryptionActive) {
          try {
            final decrypted = encManager.decryptBytes(bytes);
            final digest = sha256.convert(decrypted);
            return digest.toString();
          } catch (_) {
            // Decryption failed: either not encrypted or corrupted. Fallback to raw bytes.
          }
        }
      }
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (_) {
      return '';
    }
  }
}

final hashServiceProvider = Provider<HashService>((ref) {
  return HashService(ref);
});
