import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/security/security_provider.dart';

class IntegrityVerifier {
  final Ref? ref;

  IntegrityVerifier([this.ref]);

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
            // Decryption failed or file not encrypted; fallback to raw hashing
          }
        }
      }
      final digest = await sha256.bind(file.openRead()).single;
      return digest.toString();
    } catch (_) {
      return '';
    }
  }

  Future<bool> verifyFileIntegrity(File file, String expectedSha256) async {
    final actualSha256 = await calculateSha256(file);
    return actualSha256 == expectedSha256;
  }
}
