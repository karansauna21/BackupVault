import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntegrityVerifier {
  Future<String> calculateSha256(File file) async {
    if (!await file.exists()) return '';
    try {
      final stream = file.openRead();
      final digest = await sha256.bind(stream).single;
      return digest.toString();
    } catch (_) {
      return '';
    }
  }

  Future<bool> verifyIntegrity(File source, File destination) async {
    final sourceHash = await calculateSha256(source);
    if (sourceHash.isEmpty) return false;

    final destHash = await calculateSha256(destination);
    return sourceHash == destHash;
  }
}

final integrityVerifierProvider = Provider<IntegrityVerifier>((ref) {
  return IntegrityVerifier();
});
