import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:backup_vault/features/security/security_models.dart';
import 'package:backup_vault/features/security/security_repository.dart';
import 'package:backup_vault/features/security/password_manager.dart';
import 'package:backup_vault/features/security/key_manager.dart';
import 'package:backup_vault/features/security/encryption_manager.dart';
import 'package:backup_vault/features/security/integrity_manager.dart';
import 'package:backup_vault/features/security/security_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late SecurityRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('security_test_');
    repository = SecurityRepository(storagePath: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('PasswordManager Tests', () {
    final passwordManager = PasswordManager();

    test('should hash and verify passwords successfully', () {
      const password = 'SuperSecurePassword123!';
      final hash = passwordManager.hashPassword(password);
      
      expect(hash, isNotEmpty);
      expect(hash.contains(':'), isTrue);
      
      final verified = passwordManager.verifyPassword(password, hash);
      expect(verified, isTrue);

      final incorrectVerified = passwordManager.verifyPassword('WrongPassword', hash);
      expect(incorrectVerified, isFalse);
    });

    test('should validate password complexity correctly', () {
      const config = SecurityConfig(
        passwordPolicyMinLength: 8,
        passwordPolicyRequireSpecialChar: true,
        passwordPolicyRequireNumber: true,
      );

      expect(passwordManager.validatePasswordStrength('Short1!', config), isFalse);
      expect(passwordManager.validatePasswordStrength('LongPasswordWithoutSpecialOrNumber', config), isFalse);
      expect(passwordManager.validatePasswordStrength('LongPasswordWithNumber1', config), isFalse);
      expect(passwordManager.validatePasswordStrength('LongPasswordWithSpecial!', config), isFalse);
      expect(passwordManager.validatePasswordStrength('ValidPassword1!', config), isTrue);
    });
  });

  group('SecurityValidator Tests', () {
    final validator = SecurityValidator();

    test('should detect security risks for insecure configs', () {
      const insecureConfig = SecurityConfig(
        encryptionEnabled: false,
        passwordProtected: false,
      );

      final risks = validator.scanConfigurationRisks(insecureConfig);
      expect(risks, contains(contains('encryption is disabled')));
      expect(risks, contains(contains('password protection is disabled')));
    });

    test('should clear risks when encryption and passwords are set', () {
      const secureConfig = SecurityConfig(
        encryptionEnabled: true,
        currentKeyId: 'some-key-id',
        passwordProtected: true,
        protectSettings: true,
        protectRestore: true,
        protectExport: true,
      );

      final risks = validator.scanConfigurationRisks(secureConfig);
      expect(risks.isEmpty, isTrue);
    });
  });

  group('KeyManager & Encryption Tests', () {
    test('should generate, rotate, export, and import keys', () async {
      final keyManager = KeyManager(repository);
      await repository.init(); // Initialize empty structures

      // Generate
      final key = await keyManager.generateKey('TestKey');
      expect(key.name, equals('TestKey'));
      expect(keyManager.validateKey(key), isTrue);

      // Rotate
      await keyManager.rotateKey(key.id);
      expect(repository.config.currentKeyId, equals(key.id));

      // Export
      final exportedJson = keyManager.exportKeysPackage([key.id]);
      expect(exportedJson, isNotEmpty);
      expect(exportedJson.contains('TestKey'), isTrue);

      // Import into a new repository
      final newRepository = SecurityRepository(storagePath: p.join(tempDir.path, 'secondary'));
      await newRepository.init();
      final newKeyManager = KeyManager(newRepository);

      final imported = await newKeyManager.importKeysPackage(exportedJson);
      expect(imported.length, equals(1));
      expect(imported.first.id, equals(key.id));
      expect(imported.first.name, equals('TestKey'));
    });

    test('should encrypt and decrypt files successfully using AES-256-GCM', () async {
      await repository.init();
      final keyManager = KeyManager(repository);
      final key = await keyManager.generateKey('CryptoKey');
      await keyManager.rotateKey(key.id);
      await repository.saveConfig(repository.config.copyWith(encryptionEnabled: true));

      final encManager = EncryptionManager(repository);
      expect(encManager.isEncryptionActive, isTrue);

      // Setup raw test file
      final sourceFile = File(p.join(tempDir.path, 'source.txt'));
      const originalText = 'Enterprise security encryption test payload.';
      await sourceFile.writeAsString(originalText);

      final destFile = File(p.join(tempDir.path, 'encrypted.bin'));
      final decryptedFile = File(p.join(tempDir.path, 'decrypted.txt'));

      // Encrypt
      await encManager.encryptFile(sourceFile.path, destFile.path);
      expect(await destFile.exists(), isTrue);
      
      final encryptedBytes = await destFile.readAsBytes();
      expect(utf8.decode(encryptedBytes, allowMalformed: true), isNot(equals(originalText)));

      // Decrypt
      await encManager.decryptFile(destFile.path, decryptedFile.path);
      expect(await decryptedFile.exists(), isTrue);

      final decryptedText = await decryptedFile.readAsString();
      expect(decryptedText, equals(originalText));
    });
  });

  group('IntegrityManager Tests', () {
    final integrityManager = IntegrityManager();

    test('should calculate and verify file SHA-256 hashes', () async {
      final file = File(p.join(tempDir.path, 'integrity.txt'));
      await file.writeAsString('Integrity validation check contents.');

      final hash = await integrityManager.calculateFileHash(file.path);
      expect(hash, isNotEmpty);

      final isValid = await integrityManager.verifyFileIntegrity(file.path, hash);
      expect(isValid, isTrue);

      final isInvalid = await integrityManager.verifyFileIntegrity(file.path, 'incorrect_hash_signature');
      expect(isInvalid, isFalse);
    });
  });
}
