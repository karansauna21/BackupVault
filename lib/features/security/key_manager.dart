import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'security_models.dart';
import 'security_repository.dart';

class KeyManager {
  final SecurityRepository repository;

  KeyManager(this.repository);

  /// Generate a new secure encryption key
  Future<EncryptionKey> generateKey(String name) async {
    final rand = Random.secure();
    final bytes = Uint8List.fromList(List<int>.generate(32, (_) => rand.nextInt(256)));
    final keyBytesBase64 = base64.encode(bytes);

    final key = EncryptionKey(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      keyBytesBase64: keyBytesBase64,
      isActive: false, // Must be explicitly set or rotated to active
    );

    await repository.addKey(key);
    return key;
  }

  /// Activate/Rotate keys
  Future<void> rotateKey(String id) async {
    final keyExists = repository.keys.any((k) => k.id == id);
    if (!keyExists) {
      throw Exception('Key ID not found. Cannot rotate.');
    }
    await repository.rotateKeys(id);
    
    // Update active key in config
    final updatedConfig = repository.config.copyWith(currentKeyId: id);
    await repository.saveConfig(updatedConfig);
  }

  /// Validate key format and size (should be 32 bytes for AES-256)
  bool validateKey(EncryptionKey key) {
    try {
      final bytes = base64.decode(key.keyBytesBase64);
      return bytes.length == 32;
    } catch (_) {
      return false;
    }
  }

  /// Export key package to JSON string (optional password protection)
  String exportKeysPackage(List<String> keyIds) {
    final exportKeys = repository.keys.where((k) => keyIds.contains(k.id)).toList();
    if (exportKeys.isEmpty) {
      throw Exception('No valid keys found for export.');
    }

    final Map<String, dynamic> data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'keys': exportKeys.map((k) => k.toJson()).toList(),
    };

    return json.encode(data);
  }

  /// Import keys from JSON package
  Future<List<EncryptionKey>> importKeysPackage(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final keysList = data['keys'] as List;
      final List<EncryptionKey> imported = [];

      for (final item in keysList) {
        if (item is Map<String, dynamic>) {
          final key = EncryptionKey.fromJson(item);
          if (validateKey(key)) {
            // Check if key already exists, otherwise add it
            if (!repository.keys.any((k) => k.id == key.id)) {
              await repository.addKey(key);
              imported.add(key);
            }
          }
        }
      }
      return imported;
    } catch (e) {
      throw Exception('Failed to parse keys package: $e');
    }
  }

  /// Delete key with safety warning check
  Future<void> deleteKey(String id) async {
    final key = repository.keys.firstWhere((k) => k.id == id);
    if (key.isActive) {
      throw Exception('Cannot delete the currently active encryption key. Rotate keys first.');
    }
    await repository.deleteKey(id);
  }
}
