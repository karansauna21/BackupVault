class SecurityConfig {
  final bool encryptionEnabled;
  final String encryptionAlgorithm; // 'AES-256-GCM', 'ChaCha20-Poly1305'
  final String? currentKeyId;
  final bool passwordProtected;
  final String? hashedPassword;
  final String? passwordHint;
  final int passwordPolicyMinLength;
  final bool passwordPolicyRequireSpecialChar;
  final bool passwordPolicyRequireNumber;
  final bool protectSettings;
  final bool protectSecurity;
  final bool protectRestore;
  final bool protectExport;

  const SecurityConfig({
    this.encryptionEnabled = false,
    this.encryptionAlgorithm = 'AES-256-GCM',
    this.currentKeyId,
    this.passwordProtected = false,
    this.hashedPassword,
    this.passwordHint,
    this.passwordPolicyMinLength = 8,
    this.passwordPolicyRequireSpecialChar = true,
    this.passwordPolicyRequireNumber = true,
    this.protectSettings = false,
    this.protectSecurity = true,
    this.protectRestore = true,
    this.protectExport = true,
  });

  SecurityConfig copyWith({
    bool? encryptionEnabled,
    String? encryptionAlgorithm,
    String? currentKeyId,
    bool? passwordProtected,
    String? hashedPassword,
    String? passwordHint,
    int? passwordPolicyMinLength,
    bool? passwordPolicyRequireSpecialChar,
    bool? passwordPolicyRequireNumber,
    bool? protectSettings,
    bool? protectSecurity,
    bool? protectRestore,
    bool? protectExport,
  }) {
    return SecurityConfig(
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      encryptionAlgorithm: encryptionAlgorithm ?? this.encryptionAlgorithm,
      currentKeyId: currentKeyId ?? this.currentKeyId,
      passwordProtected: passwordProtected ?? this.passwordProtected,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      passwordHint: passwordHint ?? this.passwordHint,
      passwordPolicyMinLength: passwordPolicyMinLength ?? this.passwordPolicyMinLength,
      passwordPolicyRequireSpecialChar: passwordPolicyRequireSpecialChar ?? this.passwordPolicyRequireSpecialChar,
      passwordPolicyRequireNumber: passwordPolicyRequireNumber ?? this.passwordPolicyRequireNumber,
      protectSettings: protectSettings ?? this.protectSettings,
      protectSecurity: protectSecurity ?? this.protectSecurity,
      protectRestore: protectRestore ?? this.protectRestore,
      protectExport: protectExport ?? this.protectExport,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encryptionEnabled': encryptionEnabled,
      'encryptionAlgorithm': encryptionAlgorithm,
      'currentKeyId': currentKeyId,
      'passwordProtected': passwordProtected,
      'hashedPassword': hashedPassword,
      'passwordHint': passwordHint,
      'passwordPolicyMinLength': passwordPolicyMinLength,
      'passwordPolicyRequireSpecialChar': passwordPolicyRequireSpecialChar,
      'passwordPolicyRequireNumber': passwordPolicyRequireNumber,
      'protectSettings': protectSettings,
      'protectSecurity': protectSecurity,
      'protectRestore': protectRestore,
      'protectExport': protectExport,
    };
  }

  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      encryptionEnabled: json['encryptionEnabled'] as bool? ?? false,
      encryptionAlgorithm: json['encryptionAlgorithm'] as String? ?? 'AES-256-GCM',
      currentKeyId: json['currentKeyId'] as String?,
      passwordProtected: json['passwordProtected'] as bool? ?? false,
      hashedPassword: json['hashedPassword'] as String?,
      passwordHint: json['passwordHint'] as String?,
      passwordPolicyMinLength: json['passwordPolicyMinLength'] as int? ?? 8,
      passwordPolicyRequireSpecialChar: json['passwordPolicyRequireSpecialChar'] as bool? ?? true,
      passwordPolicyRequireNumber: json['passwordPolicyRequireNumber'] as bool? ?? true,
      protectSettings: json['protectSettings'] as bool? ?? false,
      protectSecurity: json['protectSecurity'] as bool? ?? true,
      protectRestore: json['protectRestore'] as bool? ?? true,
      protectExport: json['protectExport'] as bool? ?? true,
    );
  }
}

class EncryptionKey {
  final String id;
  final String name;
  final DateTime createdAt;
  final String keyBytesBase64;
  final bool isActive;

  const EncryptionKey({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.keyBytesBase64,
    this.isActive = true,
  });

  EncryptionKey copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? keyBytesBase64,
    bool? isActive,
  }) {
    return EncryptionKey(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      keyBytesBase64: keyBytesBase64 ?? this.keyBytesBase64,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'keyBytesBase64': keyBytesBase64,
      'isActive': isActive,
    };
  }

  factory EncryptionKey.fromJson(Map<String, dynamic> json) {
    return EncryptionKey(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      keyBytesBase64: json['keyBytesBase64'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AuditReport {
  final DateTime generatedAt;
  final int totalFiles;
  final int encryptedFiles;
  final int unencryptedFiles;
  final int verificationSuccessCount;
  final int verificationFailedCount;
  final int tamperedCount;
  final List<String> warnings;
  final List<String> risks;

  const AuditReport({
    required this.generatedAt,
    required this.totalFiles,
    required this.encryptedFiles,
    required this.unencryptedFiles,
    required this.verificationSuccessCount,
    required this.verificationFailedCount,
    required this.tamperedCount,
    required this.warnings,
    required this.risks,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'totalFiles': totalFiles,
      'encryptedFiles': encryptedFiles,
      'unencryptedFiles': unencryptedFiles,
      'verificationSuccessCount': verificationSuccessCount,
      'verificationFailedCount': verificationFailedCount,
      'tamperedCount': tamperedCount,
      'warnings': warnings,
      'risks': risks,
    };
  }

  factory AuditReport.fromJson(Map<String, dynamic> json) {
    return AuditReport(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      totalFiles: json['totalFiles'] as int? ?? 0,
      encryptedFiles: json['encryptedFiles'] as int? ?? 0,
      unencryptedFiles: json['unencryptedFiles'] as int? ?? 0,
      verificationSuccessCount: json['verificationSuccessCount'] as int? ?? 0,
      verificationFailedCount: json['verificationFailedCount'] as int? ?? 0,
      tamperedCount: json['tamperedCount'] as int? ?? 0,
      warnings: List<String>.from(json['warnings'] as List? ?? []),
      risks: List<String>.from(json['risks'] as List? ?? []),
    );
  }
}
