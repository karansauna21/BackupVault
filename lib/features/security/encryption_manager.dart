import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'security_repository.dart';

class EncryptionManager {
  final SecurityRepository repository;

  EncryptionManager(this.repository);

  /// Check if encryption is active and a key is available
  bool get isEncryptionActive {
    return repository.config.encryptionEnabled && repository.config.currentKeyId != null;
  }

  /// Get the active key bytes
  Uint8List? _getActiveKeyBytes() {
    final keyId = repository.config.currentKeyId;
    if (keyId == null) return null;
    try {
      final keyRecord = repository.keys.firstWhere((k) => k.id == keyId);
      final keyStr = keyRecord.keyBytesBase64;
      final enc.Key key = enc.Key.fromBase64(keyStr);
      return key.bytes;
    } catch (_) {
      return null;
    }
  }

  /// Encrypt byte array using AES-256-GCM
  Uint8List encryptBytes(Uint8List plainBytes) {
    final keyBytes = _getActiveKeyBytes();
    if (keyBytes == null) {
      throw Exception('No active encryption key found.');
    }

    final key = enc.Key(keyBytes);
    // Generate secure random 12-byte IV for GCM
    final iv = enc.IV.fromSecureRandom(12);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    // Concat: IV (12 bytes) + Ciphertext
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  /// Decrypt byte array using AES-256-GCM
  Uint8List decryptBytes(Uint8List encryptedBytes) {
    final keyBytes = _getActiveKeyBytes();
    if (keyBytes == null) {
      throw Exception('No active encryption key found.');
    }

    if (encryptedBytes.length < 12) {
      throw Exception('Corrupted or invalid encrypted file structure.');
    }

    // Split IV (first 12 bytes) and ciphertext
    final ivBytes = encryptedBytes.sublist(0, 12);
    final ciphertextBytes = encryptedBytes.sublist(12);

    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final decryptedList = encrypter.decryptBytes(enc.Encrypted(ciphertextBytes), iv: iv);
    return Uint8List.fromList(decryptedList);
  }

  /// Encrypt a file from source path to destination path
  Future<void> encryptFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file for encryption does not exist: $sourcePath');
    }

    final plainBytes = await sourceFile.readAsBytes();
    final encryptedBytes = encryptBytes(plainBytes);

    final destFile = File(destPath);
    await destFile.parent.create(recursive: true);
    await destFile.writeAsBytes(encryptedBytes);
  }

  /// Decrypt a file from source path to destination path
  Future<void> decryptFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Encrypted file does not exist: $sourcePath');
    }

    final encryptedBytes = await sourceFile.readAsBytes();
    final decryptedBytes = decryptBytes(encryptedBytes);

    final destFile = File(destPath);
    await destFile.parent.create(recursive: true);
    await destFile.writeAsBytes(decryptedBytes);
  }
}
