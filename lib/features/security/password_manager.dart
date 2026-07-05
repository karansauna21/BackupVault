import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'security_models.dart';

class PasswordManager {
  static const int defaultIterations = 10000;
  static const int saltBytesLength = 16;
  static const int keyBytesLength = 32;

  /// Generate a PBKDF2 derived hash for the password
  String hashPassword(String password) {
    final rand = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(saltBytesLength, (_) => rand.nextInt(256)));
    final derived = _pbkdf2(password, salt, defaultIterations, keyBytesLength);
    
    final saltBase64 = base64.encode(salt);
    final derivedBase64 = base64.encode(derived);

    return '$saltBase64:$defaultIterations:$derivedBase64';
  }

  /// Verify a candidate password against a PBKDF2 hash
  bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 3) return false;

      final salt = base64.decode(parts[0]);
      final iterations = int.parse(parts[1]);
      final storedKey = base64.decode(parts[2]);

      final derived = _pbkdf2(password, salt, iterations, keyBytesLength);

      if (derived.length != storedKey.length) return false;
      
      // Constant-time comparison
      int result = 0;
      for (int i = 0; i < derived.length; i++) {
        result |= derived[i] ^ storedKey[i];
      }
      return result == 0;
    } catch (_) {
      return false;
    }
  }

  /// Check password strength against the policy
  bool validatePasswordStrength(String password, SecurityConfig config) {
    if (password.length < config.passwordPolicyMinLength) return false;

    if (config.passwordPolicyRequireSpecialChar) {
      final specialCharRegex = RegExp(r'[!@#\$&*~%^()_\+=\-\[\]{}|;:",./<>?`]');
      if (!specialCharRegex.hasMatch(password)) return false;
    }

    if (config.passwordPolicyRequireNumber) {
      final numberRegex = RegExp(r'[0-9]');
      if (!numberRegex.hasMatch(password)) return false;
    }

    return true;
  }

  /// Pure Dart PBKDF2 implementation
  Uint8List _pbkdf2(String password, Uint8List salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final key = Uint8List(keyLength);
    final block = Uint8List(salt.length + 4);
    block.setRange(0, salt.length, salt);

    int offset = 0;
    int blockIndex = 1;

    while (offset < keyLength) {
      block[salt.length] = (blockIndex >> 24) & 0xff;
      block[salt.length + 1] = (blockIndex >> 16) & 0xff;
      block[salt.length + 2] = (blockIndex >> 8) & 0xff;
      block[salt.length + 3] = blockIndex & 0xff;

      var u = hmac.convert(block).bytes;
      var xorSum = List<int>.from(u);

      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < xorSum.length; j++) {
          xorSum[j] ^= u[j];
        }
      }

      final chunkLength = min(keyLength - offset, xorSum.length);
      key.setRange(offset, offset + chunkLength, xorSum.sublist(0, chunkLength));
      offset += chunkLength;
      blockIndex++;
    }

    return key;
  }
}
