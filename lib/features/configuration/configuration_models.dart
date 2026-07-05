class ConfigMetadata {
  final String appVersion;
  final int databaseVersion;
  final DateTime exportDate;
  final String exportDevice;
  final String platform;
  final String checksum;

  ConfigMetadata({
    required this.appVersion,
    required this.databaseVersion,
    required this.exportDate,
    required this.exportDevice,
    required this.platform,
    required this.checksum,
  });

  Map<String, dynamic> toJson() {
    return {
      'appVersion': appVersion,
      'databaseVersion': databaseVersion,
      'exportDate': exportDate.toIso8601String(),
      'exportDevice': exportDevice,
      'platform': platform,
      'checksum': checksum,
    };
  }

  factory ConfigMetadata.fromJson(Map<String, dynamic> json) {
    return ConfigMetadata(
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      databaseVersion: json['databaseVersion'] as int? ?? 4,
      exportDate: json['exportDate'] != null ? DateTime.parse(json['exportDate'] as String) : DateTime.now(),
      exportDevice: json['exportDevice'] as String? ?? 'Unknown',
      platform: json['platform'] as String? ?? 'unknown',
      checksum: json['checksum'] as String? ?? '',
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String appVersion;
  final int databaseVersion;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.appVersion,
    required this.databaseVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'errors': errors,
      'warnings': warnings,
      'appVersion': appVersion,
      'databaseVersion': databaseVersion,
    };
  }

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValid: json['isValid'] as bool? ?? false,
      errors: List<String>.from(json['errors'] as List? ?? []),
      warnings: List<String>.from(json['warnings'] as List? ?? []),
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      databaseVersion: json['databaseVersion'] as int? ?? 4,
    );
  }
}

class HistoryRecord {
  final String id;
  final String actionType; // 'export' | 'import' | 'migration' | 'restore'
  final DateTime timestamp;
  final String status; // 'success' | 'failed'
  final String details;
  final String? filePath;
  final String? errorMessage;
  final Map<String, dynamic>? validationResults;

  HistoryRecord({
    required this.id,
    required this.actionType,
    required this.timestamp,
    required this.status,
    required this.details,
    this.filePath,
    this.errorMessage,
    this.validationResults,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'details': details,
      'filePath': filePath,
      'errorMessage': errorMessage,
      'validationResults': validationResults,
    };
  }

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'] as String,
      actionType: json['actionType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      details: json['details'] as String,
      filePath: json['filePath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      validationResults: json['validationResults'] as Map<String, dynamic>?,
    );
  }
}

class ConfigurationPackage {
  final ConfigMetadata metadata;
  final Map<String, dynamic> content;

  ConfigurationPackage({
    required this.metadata,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'content': content,
    };
  }

  factory ConfigurationPackage.fromJson(Map<String, dynamic> json) {
    return ConfigurationPackage(
      metadata: ConfigMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      content: json['content'] as Map<String, dynamic>? ?? {},
    );
  }
}
