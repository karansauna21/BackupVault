// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BackupFoldersTable extends BackupFolders
    with TableInfo<$BackupFoldersTable, BackupFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationPathMeta = const VerificationMeta(
    'destinationPath',
  );
  @override
  late final GeneratedColumn<String> destinationPath = GeneratedColumn<String>(
    'destination_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _backupIntervalMeta = const VerificationMeta(
    'backupInterval',
  );
  @override
  late final GeneratedColumn<String> backupInterval = GeneratedColumn<String>(
    'backup_interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _lastBackupAtMeta = const VerificationMeta(
    'lastBackupAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastBackupAt = GeneratedColumn<DateTime>(
    'last_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextBackupAtMeta = const VerificationMeta(
    'nextBackupAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextBackupAt = GeneratedColumn<DateTime>(
    'next_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationTypeMeta = const VerificationMeta(
    'destinationType',
  );
  @override
  late final GeneratedColumn<String> destinationType = GeneratedColumn<String>(
    'destination_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceUuidMeta = const VerificationMeta(
    'deviceUuid',
  );
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
    'device_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteFolderIdMeta = const VerificationMeta(
    'remoteFolderId',
  );
  @override
  late final GeneratedColumn<String> remoteFolderId = GeneratedColumn<String>(
    'remote_folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteFolderPathMeta = const VerificationMeta(
    'remoteFolderPath',
  );
  @override
  late final GeneratedColumn<String> remoteFolderPath = GeneratedColumn<String>(
    'remote_folder_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastVerifiedMeta = const VerificationMeta(
    'lastVerified',
  );
  @override
  late final GeneratedColumn<DateTime> lastVerified = GeneratedColumn<DateTime>(
    'last_verified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourcePath,
    destinationPath,
    enabled,
    createdAt,
    backupInterval,
    lastBackupAt,
    nextBackupAt,
    destinationType,
    deviceUuid,
    deviceName,
    remoteFolderId,
    remoteFolderPath,
    lastVerified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    if (data.containsKey('destination_path')) {
      context.handle(
        _destinationPathMeta,
        destinationPath.isAcceptableOrUnknown(
          data['destination_path']!,
          _destinationPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationPathMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('backup_interval')) {
      context.handle(
        _backupIntervalMeta,
        backupInterval.isAcceptableOrUnknown(
          data['backup_interval']!,
          _backupIntervalMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
        _lastBackupAtMeta,
        lastBackupAt.isAcceptableOrUnknown(
          data['last_backup_at']!,
          _lastBackupAtMeta,
        ),
      );
    }
    if (data.containsKey('next_backup_at')) {
      context.handle(
        _nextBackupAtMeta,
        nextBackupAt.isAcceptableOrUnknown(
          data['next_backup_at']!,
          _nextBackupAtMeta,
        ),
      );
    }
    if (data.containsKey('destination_type')) {
      context.handle(
        _destinationTypeMeta,
        destinationType.isAcceptableOrUnknown(
          data['destination_type']!,
          _destinationTypeMeta,
        ),
      );
    }
    if (data.containsKey('device_uuid')) {
      context.handle(
        _deviceUuidMeta,
        deviceUuid.isAcceptableOrUnknown(data['device_uuid']!, _deviceUuidMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('remote_folder_id')) {
      context.handle(
        _remoteFolderIdMeta,
        remoteFolderId.isAcceptableOrUnknown(
          data['remote_folder_id']!,
          _remoteFolderIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_folder_path')) {
      context.handle(
        _remoteFolderPathMeta,
        remoteFolderPath.isAcceptableOrUnknown(
          data['remote_folder_path']!,
          _remoteFolderPathMeta,
        ),
      );
    }
    if (data.containsKey('last_verified')) {
      context.handle(
        _lastVerifiedMeta,
        lastVerified.isAcceptableOrUnknown(
          data['last_verified']!,
          _lastVerifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
      destinationPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_path'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      backupInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_interval'],
      )!,
      lastBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_backup_at'],
      ),
      nextBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_backup_at'],
      ),
      destinationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_type'],
      ),
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      remoteFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_folder_id'],
      ),
      remoteFolderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_folder_path'],
      ),
      lastVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_verified'],
      ),
    );
  }

  @override
  $BackupFoldersTable createAlias(String alias) {
    return $BackupFoldersTable(attachedDatabase, alias);
  }
}

class BackupFolder extends DataClass implements Insertable<BackupFolder> {
  final int id;
  final String name;
  final String sourcePath;
  final String destinationPath;
  final bool enabled;
  final DateTime createdAt;
  final String backupInterval;
  final DateTime? lastBackupAt;
  final DateTime? nextBackupAt;
  final String? destinationType;
  final String? deviceUuid;
  final String? deviceName;
  final String? remoteFolderId;
  final String? remoteFolderPath;
  final DateTime? lastVerified;
  const BackupFolder({
    required this.id,
    required this.name,
    required this.sourcePath,
    required this.destinationPath,
    required this.enabled,
    required this.createdAt,
    required this.backupInterval,
    this.lastBackupAt,
    this.nextBackupAt,
    this.destinationType,
    this.deviceUuid,
    this.deviceName,
    this.remoteFolderId,
    this.remoteFolderPath,
    this.lastVerified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source_path'] = Variable<String>(sourcePath);
    map['destination_path'] = Variable<String>(destinationPath);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['backup_interval'] = Variable<String>(backupInterval);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt);
    }
    if (!nullToAbsent || nextBackupAt != null) {
      map['next_backup_at'] = Variable<DateTime>(nextBackupAt);
    }
    if (!nullToAbsent || destinationType != null) {
      map['destination_type'] = Variable<String>(destinationType);
    }
    if (!nullToAbsent || deviceUuid != null) {
      map['device_uuid'] = Variable<String>(deviceUuid);
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    if (!nullToAbsent || remoteFolderId != null) {
      map['remote_folder_id'] = Variable<String>(remoteFolderId);
    }
    if (!nullToAbsent || remoteFolderPath != null) {
      map['remote_folder_path'] = Variable<String>(remoteFolderPath);
    }
    if (!nullToAbsent || lastVerified != null) {
      map['last_verified'] = Variable<DateTime>(lastVerified);
    }
    return map;
  }

  BackupFoldersCompanion toCompanion(bool nullToAbsent) {
    return BackupFoldersCompanion(
      id: Value(id),
      name: Value(name),
      sourcePath: Value(sourcePath),
      destinationPath: Value(destinationPath),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      backupInterval: Value(backupInterval),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
      nextBackupAt: nextBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextBackupAt),
      destinationType: destinationType == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationType),
      deviceUuid: deviceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceUuid),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      remoteFolderId: remoteFolderId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteFolderId),
      remoteFolderPath: remoteFolderPath == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteFolderPath),
      lastVerified: lastVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerified),
    );
  }

  factory BackupFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupFolder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
      destinationPath: serializer.fromJson<String>(json['destinationPath']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      backupInterval: serializer.fromJson<String>(json['backupInterval']),
      lastBackupAt: serializer.fromJson<DateTime?>(json['lastBackupAt']),
      nextBackupAt: serializer.fromJson<DateTime?>(json['nextBackupAt']),
      destinationType: serializer.fromJson<String?>(json['destinationType']),
      deviceUuid: serializer.fromJson<String?>(json['deviceUuid']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      remoteFolderId: serializer.fromJson<String?>(json['remoteFolderId']),
      remoteFolderPath: serializer.fromJson<String?>(json['remoteFolderPath']),
      lastVerified: serializer.fromJson<DateTime?>(json['lastVerified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sourcePath': serializer.toJson<String>(sourcePath),
      'destinationPath': serializer.toJson<String>(destinationPath),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'backupInterval': serializer.toJson<String>(backupInterval),
      'lastBackupAt': serializer.toJson<DateTime?>(lastBackupAt),
      'nextBackupAt': serializer.toJson<DateTime?>(nextBackupAt),
      'destinationType': serializer.toJson<String?>(destinationType),
      'deviceUuid': serializer.toJson<String?>(deviceUuid),
      'deviceName': serializer.toJson<String?>(deviceName),
      'remoteFolderId': serializer.toJson<String?>(remoteFolderId),
      'remoteFolderPath': serializer.toJson<String?>(remoteFolderPath),
      'lastVerified': serializer.toJson<DateTime?>(lastVerified),
    };
  }

  BackupFolder copyWith({
    int? id,
    String? name,
    String? sourcePath,
    String? destinationPath,
    bool? enabled,
    DateTime? createdAt,
    String? backupInterval,
    Value<DateTime?> lastBackupAt = const Value.absent(),
    Value<DateTime?> nextBackupAt = const Value.absent(),
    Value<String?> destinationType = const Value.absent(),
    Value<String?> deviceUuid = const Value.absent(),
    Value<String?> deviceName = const Value.absent(),
    Value<String?> remoteFolderId = const Value.absent(),
    Value<String?> remoteFolderPath = const Value.absent(),
    Value<DateTime?> lastVerified = const Value.absent(),
  }) => BackupFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    sourcePath: sourcePath ?? this.sourcePath,
    destinationPath: destinationPath ?? this.destinationPath,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
    backupInterval: backupInterval ?? this.backupInterval,
    lastBackupAt: lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
    nextBackupAt: nextBackupAt.present ? nextBackupAt.value : this.nextBackupAt,
    destinationType: destinationType.present
        ? destinationType.value
        : this.destinationType,
    deviceUuid: deviceUuid.present ? deviceUuid.value : this.deviceUuid,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    remoteFolderId: remoteFolderId.present
        ? remoteFolderId.value
        : this.remoteFolderId,
    remoteFolderPath: remoteFolderPath.present
        ? remoteFolderPath.value
        : this.remoteFolderPath,
    lastVerified: lastVerified.present ? lastVerified.value : this.lastVerified,
  );
  BackupFolder copyWithCompanion(BackupFoldersCompanion data) {
    return BackupFolder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      destinationPath: data.destinationPath.present
          ? data.destinationPath.value
          : this.destinationPath,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      backupInterval: data.backupInterval.present
          ? data.backupInterval.value
          : this.backupInterval,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
      nextBackupAt: data.nextBackupAt.present
          ? data.nextBackupAt.value
          : this.nextBackupAt,
      destinationType: data.destinationType.present
          ? data.destinationType.value
          : this.destinationType,
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      remoteFolderId: data.remoteFolderId.present
          ? data.remoteFolderId.value
          : this.remoteFolderId,
      remoteFolderPath: data.remoteFolderPath.present
          ? data.remoteFolderPath.value
          : this.remoteFolderPath,
      lastVerified: data.lastVerified.present
          ? data.lastVerified.value
          : this.lastVerified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupFolder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('destinationPath: $destinationPath, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('backupInterval: $backupInterval, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('nextBackupAt: $nextBackupAt, ')
          ..write('destinationType: $destinationType, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('remoteFolderId: $remoteFolderId, ')
          ..write('remoteFolderPath: $remoteFolderPath, ')
          ..write('lastVerified: $lastVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourcePath,
    destinationPath,
    enabled,
    createdAt,
    backupInterval,
    lastBackupAt,
    nextBackupAt,
    destinationType,
    deviceUuid,
    deviceName,
    remoteFolderId,
    remoteFolderPath,
    lastVerified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupFolder &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourcePath == this.sourcePath &&
          other.destinationPath == this.destinationPath &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.backupInterval == this.backupInterval &&
          other.lastBackupAt == this.lastBackupAt &&
          other.nextBackupAt == this.nextBackupAt &&
          other.destinationType == this.destinationType &&
          other.deviceUuid == this.deviceUuid &&
          other.deviceName == this.deviceName &&
          other.remoteFolderId == this.remoteFolderId &&
          other.remoteFolderPath == this.remoteFolderPath &&
          other.lastVerified == this.lastVerified);
}

class BackupFoldersCompanion extends UpdateCompanion<BackupFolder> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> sourcePath;
  final Value<String> destinationPath;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<String> backupInterval;
  final Value<DateTime?> lastBackupAt;
  final Value<DateTime?> nextBackupAt;
  final Value<String?> destinationType;
  final Value<String?> deviceUuid;
  final Value<String?> deviceName;
  final Value<String?> remoteFolderId;
  final Value<String?> remoteFolderPath;
  final Value<DateTime?> lastVerified;
  const BackupFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.destinationPath = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.backupInterval = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.nextBackupAt = const Value.absent(),
    this.destinationType = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.remoteFolderId = const Value.absent(),
    this.remoteFolderPath = const Value.absent(),
    this.lastVerified = const Value.absent(),
  });
  BackupFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String sourcePath,
    required String destinationPath,
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.backupInterval = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.nextBackupAt = const Value.absent(),
    this.destinationType = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.remoteFolderId = const Value.absent(),
    this.remoteFolderPath = const Value.absent(),
    this.lastVerified = const Value.absent(),
  }) : name = Value(name),
       sourcePath = Value(sourcePath),
       destinationPath = Value(destinationPath);
  static Insertable<BackupFolder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sourcePath,
    Expression<String>? destinationPath,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<String>? backupInterval,
    Expression<DateTime>? lastBackupAt,
    Expression<DateTime>? nextBackupAt,
    Expression<String>? destinationType,
    Expression<String>? deviceUuid,
    Expression<String>? deviceName,
    Expression<String>? remoteFolderId,
    Expression<String>? remoteFolderPath,
    Expression<DateTime>? lastVerified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourcePath != null) 'source_path': sourcePath,
      if (destinationPath != null) 'destination_path': destinationPath,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (backupInterval != null) 'backup_interval': backupInterval,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (nextBackupAt != null) 'next_backup_at': nextBackupAt,
      if (destinationType != null) 'destination_type': destinationType,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (deviceName != null) 'device_name': deviceName,
      if (remoteFolderId != null) 'remote_folder_id': remoteFolderId,
      if (remoteFolderPath != null) 'remote_folder_path': remoteFolderPath,
      if (lastVerified != null) 'last_verified': lastVerified,
    });
  }

  BackupFoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? sourcePath,
    Value<String>? destinationPath,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
    Value<String>? backupInterval,
    Value<DateTime?>? lastBackupAt,
    Value<DateTime?>? nextBackupAt,
    Value<String?>? destinationType,
    Value<String?>? deviceUuid,
    Value<String?>? deviceName,
    Value<String?>? remoteFolderId,
    Value<String?>? remoteFolderPath,
    Value<DateTime?>? lastVerified,
  }) {
    return BackupFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourcePath: sourcePath ?? this.sourcePath,
      destinationPath: destinationPath ?? this.destinationPath,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      backupInterval: backupInterval ?? this.backupInterval,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      nextBackupAt: nextBackupAt ?? this.nextBackupAt,
      destinationType: destinationType ?? this.destinationType,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      remoteFolderId: remoteFolderId ?? this.remoteFolderId,
      remoteFolderPath: remoteFolderPath ?? this.remoteFolderPath,
      lastVerified: lastVerified ?? this.lastVerified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (destinationPath.present) {
      map['destination_path'] = Variable<String>(destinationPath.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (backupInterval.present) {
      map['backup_interval'] = Variable<String>(backupInterval.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt.value);
    }
    if (nextBackupAt.present) {
      map['next_backup_at'] = Variable<DateTime>(nextBackupAt.value);
    }
    if (destinationType.present) {
      map['destination_type'] = Variable<String>(destinationType.value);
    }
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (remoteFolderId.present) {
      map['remote_folder_id'] = Variable<String>(remoteFolderId.value);
    }
    if (remoteFolderPath.present) {
      map['remote_folder_path'] = Variable<String>(remoteFolderPath.value);
    }
    if (lastVerified.present) {
      map['last_verified'] = Variable<DateTime>(lastVerified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('destinationPath: $destinationPath, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('backupInterval: $backupInterval, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('nextBackupAt: $nextBackupAt, ')
          ..write('destinationType: $destinationType, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('remoteFolderId: $remoteFolderId, ')
          ..write('remoteFolderPath: $remoteFolderPath, ')
          ..write('lastVerified: $lastVerified')
          ..write(')'))
        .toString();
  }
}

class $BackupFilesTable extends BackupFiles
    with TableInfo<$BackupFilesTable, BackupFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES backup_folders (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extensionMeta = const VerificationMeta(
    'extension',
  );
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
    'extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backupPathMeta = const VerificationMeta(
    'backupPath',
  );
  @override
  late final GeneratedColumn<String> backupPath = GeneratedColumn<String>(
    'backup_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backupStatusMeta = const VerificationMeta(
    'backupStatus',
  );
  @override
  late final GeneratedColumn<String> backupStatus = GeneratedColumn<String>(
    'backup_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    fileName,
    extension,
    originalPath,
    backupPath,
    fileSize,
    sha256,
    createdAt,
    modifiedAt,
    backupStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(
        _extensionMeta,
        extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta),
      );
    } else if (isInserting) {
      context.missing(_extensionMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('backup_path')) {
      context.handle(
        _backupPathMeta,
        backupPath.isAcceptableOrUnknown(data['backup_path']!, _backupPathMeta),
      );
    } else if (isInserting) {
      context.missing(_backupPathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('backup_status')) {
      context.handle(
        _backupStatusMeta,
        backupStatus.isAcceptableOrUnknown(
          data['backup_status']!,
          _backupStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_backupStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      extension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      )!,
      backupPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      backupStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_status'],
      )!,
    );
  }

  @override
  $BackupFilesTable createAlias(String alias) {
    return $BackupFilesTable(attachedDatabase, alias);
  }
}

class BackupFile extends DataClass implements Insertable<BackupFile> {
  final int id;
  final int folderId;
  final String fileName;
  final String extension;
  final String originalPath;
  final String backupPath;
  final int fileSize;
  final String sha256;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String backupStatus;
  const BackupFile({
    required this.id,
    required this.folderId,
    required this.fileName,
    required this.extension,
    required this.originalPath,
    required this.backupPath,
    required this.fileSize,
    required this.sha256,
    required this.createdAt,
    required this.modifiedAt,
    required this.backupStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['folder_id'] = Variable<int>(folderId);
    map['file_name'] = Variable<String>(fileName);
    map['extension'] = Variable<String>(extension);
    map['original_path'] = Variable<String>(originalPath);
    map['backup_path'] = Variable<String>(backupPath);
    map['file_size'] = Variable<int>(fileSize);
    map['sha256'] = Variable<String>(sha256);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['backup_status'] = Variable<String>(backupStatus);
    return map;
  }

  BackupFilesCompanion toCompanion(bool nullToAbsent) {
    return BackupFilesCompanion(
      id: Value(id),
      folderId: Value(folderId),
      fileName: Value(fileName),
      extension: Value(extension),
      originalPath: Value(originalPath),
      backupPath: Value(backupPath),
      fileSize: Value(fileSize),
      sha256: Value(sha256),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      backupStatus: Value(backupStatus),
    );
  }

  factory BackupFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupFile(
      id: serializer.fromJson<int>(json['id']),
      folderId: serializer.fromJson<int>(json['folderId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      extension: serializer.fromJson<String>(json['extension']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      backupPath: serializer.fromJson<String>(json['backupPath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      sha256: serializer.fromJson<String>(json['sha256']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      backupStatus: serializer.fromJson<String>(json['backupStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'folderId': serializer.toJson<int>(folderId),
      'fileName': serializer.toJson<String>(fileName),
      'extension': serializer.toJson<String>(extension),
      'originalPath': serializer.toJson<String>(originalPath),
      'backupPath': serializer.toJson<String>(backupPath),
      'fileSize': serializer.toJson<int>(fileSize),
      'sha256': serializer.toJson<String>(sha256),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'backupStatus': serializer.toJson<String>(backupStatus),
    };
  }

  BackupFile copyWith({
    int? id,
    int? folderId,
    String? fileName,
    String? extension,
    String? originalPath,
    String? backupPath,
    int? fileSize,
    String? sha256,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? backupStatus,
  }) => BackupFile(
    id: id ?? this.id,
    folderId: folderId ?? this.folderId,
    fileName: fileName ?? this.fileName,
    extension: extension ?? this.extension,
    originalPath: originalPath ?? this.originalPath,
    backupPath: backupPath ?? this.backupPath,
    fileSize: fileSize ?? this.fileSize,
    sha256: sha256 ?? this.sha256,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    backupStatus: backupStatus ?? this.backupStatus,
  );
  BackupFile copyWithCompanion(BackupFilesCompanion data) {
    return BackupFile(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      extension: data.extension.present ? data.extension.value : this.extension,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      backupPath: data.backupPath.present
          ? data.backupPath.value
          : this.backupPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      backupStatus: data.backupStatus.present
          ? data.backupStatus.value
          : this.backupStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupFile(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('fileName: $fileName, ')
          ..write('extension: $extension, ')
          ..write('originalPath: $originalPath, ')
          ..write('backupPath: $backupPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('backupStatus: $backupStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    fileName,
    extension,
    originalPath,
    backupPath,
    fileSize,
    sha256,
    createdAt,
    modifiedAt,
    backupStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupFile &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.fileName == this.fileName &&
          other.extension == this.extension &&
          other.originalPath == this.originalPath &&
          other.backupPath == this.backupPath &&
          other.fileSize == this.fileSize &&
          other.sha256 == this.sha256 &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.backupStatus == this.backupStatus);
}

class BackupFilesCompanion extends UpdateCompanion<BackupFile> {
  final Value<int> id;
  final Value<int> folderId;
  final Value<String> fileName;
  final Value<String> extension;
  final Value<String> originalPath;
  final Value<String> backupPath;
  final Value<int> fileSize;
  final Value<String> sha256;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> backupStatus;
  const BackupFilesCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.extension = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.backupPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.backupStatus = const Value.absent(),
  });
  BackupFilesCompanion.insert({
    this.id = const Value.absent(),
    required int folderId,
    required String fileName,
    required String extension,
    required String originalPath,
    required String backupPath,
    required int fileSize,
    required String sha256,
    this.createdAt = const Value.absent(),
    required DateTime modifiedAt,
    required String backupStatus,
  }) : folderId = Value(folderId),
       fileName = Value(fileName),
       extension = Value(extension),
       originalPath = Value(originalPath),
       backupPath = Value(backupPath),
       fileSize = Value(fileSize),
       sha256 = Value(sha256),
       modifiedAt = Value(modifiedAt),
       backupStatus = Value(backupStatus);
  static Insertable<BackupFile> custom({
    Expression<int>? id,
    Expression<int>? folderId,
    Expression<String>? fileName,
    Expression<String>? extension,
    Expression<String>? originalPath,
    Expression<String>? backupPath,
    Expression<int>? fileSize,
    Expression<String>? sha256,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? backupStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (fileName != null) 'file_name': fileName,
      if (extension != null) 'extension': extension,
      if (originalPath != null) 'original_path': originalPath,
      if (backupPath != null) 'backup_path': backupPath,
      if (fileSize != null) 'file_size': fileSize,
      if (sha256 != null) 'sha256': sha256,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (backupStatus != null) 'backup_status': backupStatus,
    });
  }

  BackupFilesCompanion copyWith({
    Value<int>? id,
    Value<int>? folderId,
    Value<String>? fileName,
    Value<String>? extension,
    Value<String>? originalPath,
    Value<String>? backupPath,
    Value<int>? fileSize,
    Value<String>? sha256,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? backupStatus,
  }) {
    return BackupFilesCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      fileName: fileName ?? this.fileName,
      extension: extension ?? this.extension,
      originalPath: originalPath ?? this.originalPath,
      backupPath: backupPath ?? this.backupPath,
      fileSize: fileSize ?? this.fileSize,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      backupStatus: backupStatus ?? this.backupStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (backupPath.present) {
      map['backup_path'] = Variable<String>(backupPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (backupStatus.present) {
      map['backup_status'] = Variable<String>(backupStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupFilesCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('fileName: $fileName, ')
          ..write('extension: $extension, ')
          ..write('originalPath: $originalPath, ')
          ..write('backupPath: $backupPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('backupStatus: $backupStatus')
          ..write(')'))
        .toString();
  }
}

class $FileVersionsTable extends FileVersions
    with TableInfo<$FileVersionsTable, FileVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<int> fileId = GeneratedColumn<int>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES backup_files (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _versionNumberMeta = const VerificationMeta(
    'versionNumber',
  );
  @override
  late final GeneratedColumn<int> versionNumber = GeneratedColumn<int>(
    'version_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backupPathMeta = const VerificationMeta(
    'backupPath',
  );
  @override
  late final GeneratedColumn<String> backupPath = GeneratedColumn<String>(
    'backup_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileId,
    versionNumber,
    backupPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('version_number')) {
      context.handle(
        _versionNumberMeta,
        versionNumber.isAcceptableOrUnknown(
          data['version_number']!,
          _versionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionNumberMeta);
    }
    if (data.containsKey('backup_path')) {
      context.handle(
        _backupPathMeta,
        backupPath.isAcceptableOrUnknown(data['backup_path']!, _backupPathMeta),
      );
    } else if (isInserting) {
      context.missing(_backupPathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_id'],
      )!,
      versionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_number'],
      )!,
      backupPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FileVersionsTable createAlias(String alias) {
    return $FileVersionsTable(attachedDatabase, alias);
  }
}

class FileVersion extends DataClass implements Insertable<FileVersion> {
  final int id;
  final int fileId;
  final int versionNumber;
  final String backupPath;
  final DateTime createdAt;
  const FileVersion({
    required this.id,
    required this.fileId,
    required this.versionNumber,
    required this.backupPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_id'] = Variable<int>(fileId);
    map['version_number'] = Variable<int>(versionNumber);
    map['backup_path'] = Variable<String>(backupPath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FileVersionsCompanion toCompanion(bool nullToAbsent) {
    return FileVersionsCompanion(
      id: Value(id),
      fileId: Value(fileId),
      versionNumber: Value(versionNumber),
      backupPath: Value(backupPath),
      createdAt: Value(createdAt),
    );
  }

  factory FileVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileVersion(
      id: serializer.fromJson<int>(json['id']),
      fileId: serializer.fromJson<int>(json['fileId']),
      versionNumber: serializer.fromJson<int>(json['versionNumber']),
      backupPath: serializer.fromJson<String>(json['backupPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileId': serializer.toJson<int>(fileId),
      'versionNumber': serializer.toJson<int>(versionNumber),
      'backupPath': serializer.toJson<String>(backupPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FileVersion copyWith({
    int? id,
    int? fileId,
    int? versionNumber,
    String? backupPath,
    DateTime? createdAt,
  }) => FileVersion(
    id: id ?? this.id,
    fileId: fileId ?? this.fileId,
    versionNumber: versionNumber ?? this.versionNumber,
    backupPath: backupPath ?? this.backupPath,
    createdAt: createdAt ?? this.createdAt,
  );
  FileVersion copyWithCompanion(FileVersionsCompanion data) {
    return FileVersion(
      id: data.id.present ? data.id.value : this.id,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      versionNumber: data.versionNumber.present
          ? data.versionNumber.value
          : this.versionNumber,
      backupPath: data.backupPath.present
          ? data.backupPath.value
          : this.backupPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileVersion(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('backupPath: $backupPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fileId, versionNumber, backupPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileVersion &&
          other.id == this.id &&
          other.fileId == this.fileId &&
          other.versionNumber == this.versionNumber &&
          other.backupPath == this.backupPath &&
          other.createdAt == this.createdAt);
}

class FileVersionsCompanion extends UpdateCompanion<FileVersion> {
  final Value<int> id;
  final Value<int> fileId;
  final Value<int> versionNumber;
  final Value<String> backupPath;
  final Value<DateTime> createdAt;
  const FileVersionsCompanion({
    this.id = const Value.absent(),
    this.fileId = const Value.absent(),
    this.versionNumber = const Value.absent(),
    this.backupPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FileVersionsCompanion.insert({
    this.id = const Value.absent(),
    required int fileId,
    required int versionNumber,
    required String backupPath,
    this.createdAt = const Value.absent(),
  }) : fileId = Value(fileId),
       versionNumber = Value(versionNumber),
       backupPath = Value(backupPath);
  static Insertable<FileVersion> custom({
    Expression<int>? id,
    Expression<int>? fileId,
    Expression<int>? versionNumber,
    Expression<String>? backupPath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileId != null) 'file_id': fileId,
      if (versionNumber != null) 'version_number': versionNumber,
      if (backupPath != null) 'backup_path': backupPath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FileVersionsCompanion copyWith({
    Value<int>? id,
    Value<int>? fileId,
    Value<int>? versionNumber,
    Value<String>? backupPath,
    Value<DateTime>? createdAt,
  }) {
    return FileVersionsCompanion(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      versionNumber: versionNumber ?? this.versionNumber,
      backupPath: backupPath ?? this.backupPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
    }
    if (versionNumber.present) {
      map['version_number'] = Variable<int>(versionNumber.value);
    }
    if (backupPath.present) {
      map['backup_path'] = Variable<String>(backupPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileVersionsCompanion(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('backupPath: $backupPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BackupLogsTable extends BackupLogs
    with TableInfo<$BackupLogsTable, BackupLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _logTypeMeta = const VerificationMeta(
    'logType',
  );
  @override
  late final GeneratedColumn<String> logType = GeneratedColumn<String>(
    'log_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stackTraceMeta = const VerificationMeta(
    'stackTrace',
  );
  @override
  late final GeneratedColumn<String> stackTrace = GeneratedColumn<String>(
    'stack_trace',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    logType,
    message,
    createdAt,
    tag,
    stackTrace,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('log_type')) {
      context.handle(
        _logTypeMeta,
        logType.isAcceptableOrUnknown(data['log_type']!, _logTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_logTypeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('stack_trace')) {
      context.handle(
        _stackTraceMeta,
        stackTrace.isAcceptableOrUnknown(data['stack_trace']!, _stackTraceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      logType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_type'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      stackTrace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stack_trace'],
      ),
    );
  }

  @override
  $BackupLogsTable createAlias(String alias) {
    return $BackupLogsTable(attachedDatabase, alias);
  }
}

class BackupLog extends DataClass implements Insertable<BackupLog> {
  final int id;
  final String logType;
  final String message;
  final DateTime createdAt;
  final String? tag;
  final String? stackTrace;
  const BackupLog({
    required this.id,
    required this.logType,
    required this.message,
    required this.createdAt,
    this.tag,
    this.stackTrace,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['log_type'] = Variable<String>(logType);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || stackTrace != null) {
      map['stack_trace'] = Variable<String>(stackTrace);
    }
    return map;
  }

  BackupLogsCompanion toCompanion(bool nullToAbsent) {
    return BackupLogsCompanion(
      id: Value(id),
      logType: Value(logType),
      message: Value(message),
      createdAt: Value(createdAt),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      stackTrace: stackTrace == null && nullToAbsent
          ? const Value.absent()
          : Value(stackTrace),
    );
  }

  factory BackupLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupLog(
      id: serializer.fromJson<int>(json['id']),
      logType: serializer.fromJson<String>(json['logType']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      tag: serializer.fromJson<String?>(json['tag']),
      stackTrace: serializer.fromJson<String?>(json['stackTrace']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'logType': serializer.toJson<String>(logType),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'tag': serializer.toJson<String?>(tag),
      'stackTrace': serializer.toJson<String?>(stackTrace),
    };
  }

  BackupLog copyWith({
    int? id,
    String? logType,
    String? message,
    DateTime? createdAt,
    Value<String?> tag = const Value.absent(),
    Value<String?> stackTrace = const Value.absent(),
  }) => BackupLog(
    id: id ?? this.id,
    logType: logType ?? this.logType,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
    tag: tag.present ? tag.value : this.tag,
    stackTrace: stackTrace.present ? stackTrace.value : this.stackTrace,
  );
  BackupLog copyWithCompanion(BackupLogsCompanion data) {
    return BackupLog(
      id: data.id.present ? data.id.value : this.id,
      logType: data.logType.present ? data.logType.value : this.logType,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      tag: data.tag.present ? data.tag.value : this.tag,
      stackTrace: data.stackTrace.present
          ? data.stackTrace.value
          : this.stackTrace,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupLog(')
          ..write('id: $id, ')
          ..write('logType: $logType, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('tag: $tag, ')
          ..write('stackTrace: $stackTrace')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, logType, message, createdAt, tag, stackTrace);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupLog &&
          other.id == this.id &&
          other.logType == this.logType &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.tag == this.tag &&
          other.stackTrace == this.stackTrace);
}

class BackupLogsCompanion extends UpdateCompanion<BackupLog> {
  final Value<int> id;
  final Value<String> logType;
  final Value<String> message;
  final Value<DateTime> createdAt;
  final Value<String?> tag;
  final Value<String?> stackTrace;
  const BackupLogsCompanion({
    this.id = const Value.absent(),
    this.logType = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.tag = const Value.absent(),
    this.stackTrace = const Value.absent(),
  });
  BackupLogsCompanion.insert({
    this.id = const Value.absent(),
    required String logType,
    required String message,
    this.createdAt = const Value.absent(),
    this.tag = const Value.absent(),
    this.stackTrace = const Value.absent(),
  }) : logType = Value(logType),
       message = Value(message);
  static Insertable<BackupLog> custom({
    Expression<int>? id,
    Expression<String>? logType,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
    Expression<String>? tag,
    Expression<String>? stackTrace,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (logType != null) 'log_type': logType,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (tag != null) 'tag': tag,
      if (stackTrace != null) 'stack_trace': stackTrace,
    });
  }

  BackupLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? logType,
    Value<String>? message,
    Value<DateTime>? createdAt,
    Value<String?>? tag,
    Value<String?>? stackTrace,
  }) {
    return BackupLogsCompanion(
      id: id ?? this.id,
      logType: logType ?? this.logType,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      tag: tag ?? this.tag,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (logType.present) {
      map['log_type'] = Variable<String>(logType.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (stackTrace.present) {
      map['stack_trace'] = Variable<String>(stackTrace.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupLogsCompanion(')
          ..write('id: $id, ')
          ..write('logType: $logType, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('tag: $tag, ')
          ..write('stackTrace: $stackTrace')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _autoStartMeta = const VerificationMeta(
    'autoStart',
  );
  @override
  late final GeneratedColumn<bool> autoStart = GeneratedColumn<bool>(
    'auto_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_start" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _darkModeMeta = const VerificationMeta(
    'darkMode',
  );
  @override
  late final GeneratedColumn<bool> darkMode = GeneratedColumn<bool>(
    'dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationsMeta = const VerificationMeta(
    'notifications',
  );
  @override
  late final GeneratedColumn<bool> notifications = GeneratedColumn<bool>(
    'notifications',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _verifyHashMeta = const VerificationMeta(
    'verifyHash',
  );
  @override
  late final GeneratedColumn<bool> verifyHash = GeneratedColumn<bool>(
    'verify_hash',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("verify_hash" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _versioningEnabledMeta = const VerificationMeta(
    'versioningEnabled',
  );
  @override
  late final GeneratedColumn<bool> versioningEnabled = GeneratedColumn<bool>(
    'versioning_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("versioning_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _backupModeMeta = const VerificationMeta(
    'backupMode',
  );
  @override
  late final GeneratedColumn<String> backupMode = GeneratedColumn<String>(
    'backup_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('incremental'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _defaultDestinationPathMeta =
      const VerificationMeta('defaultDestinationPath');
  @override
  late final GeneratedColumn<String> defaultDestinationPath =
      GeneratedColumn<String>(
        'default_destination_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _autoBackupEnabledMeta = const VerificationMeta(
    'autoBackupEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoBackupEnabled = GeneratedColumn<bool>(
    'auto_backup_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_backup_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _backupIntervalMeta = const VerificationMeta(
    'backupInterval',
  );
  @override
  late final GeneratedColumn<String> backupInterval = GeneratedColumn<String>(
    'backup_interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _notifyOnSuccessMeta = const VerificationMeta(
    'notifyOnSuccess',
  );
  @override
  late final GeneratedColumn<bool> notifyOnSuccess = GeneratedColumn<bool>(
    'notify_on_success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_on_success" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyOnFailureMeta = const VerificationMeta(
    'notifyOnFailure',
  );
  @override
  late final GeneratedColumn<bool> notifyOnFailure = GeneratedColumn<bool>(
    'notify_on_failure',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_on_failure" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    autoStart,
    darkMode,
    notifications,
    verifyHash,
    versioningEnabled,
    backupMode,
    language,
    defaultDestinationPath,
    themeMode,
    autoBackupEnabled,
    backupInterval,
    notifyOnSuccess,
    notifyOnFailure,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('auto_start')) {
      context.handle(
        _autoStartMeta,
        autoStart.isAcceptableOrUnknown(data['auto_start']!, _autoStartMeta),
      );
    }
    if (data.containsKey('dark_mode')) {
      context.handle(
        _darkModeMeta,
        darkMode.isAcceptableOrUnknown(data['dark_mode']!, _darkModeMeta),
      );
    }
    if (data.containsKey('notifications')) {
      context.handle(
        _notificationsMeta,
        notifications.isAcceptableOrUnknown(
          data['notifications']!,
          _notificationsMeta,
        ),
      );
    }
    if (data.containsKey('verify_hash')) {
      context.handle(
        _verifyHashMeta,
        verifyHash.isAcceptableOrUnknown(data['verify_hash']!, _verifyHashMeta),
      );
    }
    if (data.containsKey('versioning_enabled')) {
      context.handle(
        _versioningEnabledMeta,
        versioningEnabled.isAcceptableOrUnknown(
          data['versioning_enabled']!,
          _versioningEnabledMeta,
        ),
      );
    }
    if (data.containsKey('backup_mode')) {
      context.handle(
        _backupModeMeta,
        backupMode.isAcceptableOrUnknown(data['backup_mode']!, _backupModeMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('default_destination_path')) {
      context.handle(
        _defaultDestinationPathMeta,
        defaultDestinationPath.isAcceptableOrUnknown(
          data['default_destination_path']!,
          _defaultDestinationPathMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('auto_backup_enabled')) {
      context.handle(
        _autoBackupEnabledMeta,
        autoBackupEnabled.isAcceptableOrUnknown(
          data['auto_backup_enabled']!,
          _autoBackupEnabledMeta,
        ),
      );
    }
    if (data.containsKey('backup_interval')) {
      context.handle(
        _backupIntervalMeta,
        backupInterval.isAcceptableOrUnknown(
          data['backup_interval']!,
          _backupIntervalMeta,
        ),
      );
    }
    if (data.containsKey('notify_on_success')) {
      context.handle(
        _notifyOnSuccessMeta,
        notifyOnSuccess.isAcceptableOrUnknown(
          data['notify_on_success']!,
          _notifyOnSuccessMeta,
        ),
      );
    }
    if (data.containsKey('notify_on_failure')) {
      context.handle(
        _notifyOnFailureMeta,
        notifyOnFailure.isAcceptableOrUnknown(
          data['notify_on_failure']!,
          _notifyOnFailureMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      autoStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_start'],
      )!,
      darkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dark_mode'],
      )!,
      notifications: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications'],
      )!,
      verifyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}verify_hash'],
      )!,
      versioningEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}versioning_enabled'],
      )!,
      backupMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_mode'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      defaultDestinationPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_destination_path'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      autoBackupEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_backup_enabled'],
      )!,
      backupInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_interval'],
      )!,
      notifyOnSuccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_on_success'],
      )!,
      notifyOnFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_on_failure'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final bool autoStart;
  final bool darkMode;
  final bool notifications;
  final bool verifyHash;
  final bool versioningEnabled;
  final String backupMode;
  final String language;
  final String defaultDestinationPath;
  final String themeMode;
  final bool autoBackupEnabled;
  final String backupInterval;
  final bool notifyOnSuccess;
  final bool notifyOnFailure;
  const Setting({
    required this.id,
    required this.autoStart,
    required this.darkMode,
    required this.notifications,
    required this.verifyHash,
    required this.versioningEnabled,
    required this.backupMode,
    required this.language,
    required this.defaultDestinationPath,
    required this.themeMode,
    required this.autoBackupEnabled,
    required this.backupInterval,
    required this.notifyOnSuccess,
    required this.notifyOnFailure,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['auto_start'] = Variable<bool>(autoStart);
    map['dark_mode'] = Variable<bool>(darkMode);
    map['notifications'] = Variable<bool>(notifications);
    map['verify_hash'] = Variable<bool>(verifyHash);
    map['versioning_enabled'] = Variable<bool>(versioningEnabled);
    map['backup_mode'] = Variable<String>(backupMode);
    map['language'] = Variable<String>(language);
    map['default_destination_path'] = Variable<String>(defaultDestinationPath);
    map['theme_mode'] = Variable<String>(themeMode);
    map['auto_backup_enabled'] = Variable<bool>(autoBackupEnabled);
    map['backup_interval'] = Variable<String>(backupInterval);
    map['notify_on_success'] = Variable<bool>(notifyOnSuccess);
    map['notify_on_failure'] = Variable<bool>(notifyOnFailure);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      autoStart: Value(autoStart),
      darkMode: Value(darkMode),
      notifications: Value(notifications),
      verifyHash: Value(verifyHash),
      versioningEnabled: Value(versioningEnabled),
      backupMode: Value(backupMode),
      language: Value(language),
      defaultDestinationPath: Value(defaultDestinationPath),
      themeMode: Value(themeMode),
      autoBackupEnabled: Value(autoBackupEnabled),
      backupInterval: Value(backupInterval),
      notifyOnSuccess: Value(notifyOnSuccess),
      notifyOnFailure: Value(notifyOnFailure),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      autoStart: serializer.fromJson<bool>(json['autoStart']),
      darkMode: serializer.fromJson<bool>(json['darkMode']),
      notifications: serializer.fromJson<bool>(json['notifications']),
      verifyHash: serializer.fromJson<bool>(json['verifyHash']),
      versioningEnabled: serializer.fromJson<bool>(json['versioningEnabled']),
      backupMode: serializer.fromJson<String>(json['backupMode']),
      language: serializer.fromJson<String>(json['language']),
      defaultDestinationPath: serializer.fromJson<String>(
        json['defaultDestinationPath'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      autoBackupEnabled: serializer.fromJson<bool>(json['autoBackupEnabled']),
      backupInterval: serializer.fromJson<String>(json['backupInterval']),
      notifyOnSuccess: serializer.fromJson<bool>(json['notifyOnSuccess']),
      notifyOnFailure: serializer.fromJson<bool>(json['notifyOnFailure']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'autoStart': serializer.toJson<bool>(autoStart),
      'darkMode': serializer.toJson<bool>(darkMode),
      'notifications': serializer.toJson<bool>(notifications),
      'verifyHash': serializer.toJson<bool>(verifyHash),
      'versioningEnabled': serializer.toJson<bool>(versioningEnabled),
      'backupMode': serializer.toJson<String>(backupMode),
      'language': serializer.toJson<String>(language),
      'defaultDestinationPath': serializer.toJson<String>(
        defaultDestinationPath,
      ),
      'themeMode': serializer.toJson<String>(themeMode),
      'autoBackupEnabled': serializer.toJson<bool>(autoBackupEnabled),
      'backupInterval': serializer.toJson<String>(backupInterval),
      'notifyOnSuccess': serializer.toJson<bool>(notifyOnSuccess),
      'notifyOnFailure': serializer.toJson<bool>(notifyOnFailure),
    };
  }

  Setting copyWith({
    int? id,
    bool? autoStart,
    bool? darkMode,
    bool? notifications,
    bool? verifyHash,
    bool? versioningEnabled,
    String? backupMode,
    String? language,
    String? defaultDestinationPath,
    String? themeMode,
    bool? autoBackupEnabled,
    String? backupInterval,
    bool? notifyOnSuccess,
    bool? notifyOnFailure,
  }) => Setting(
    id: id ?? this.id,
    autoStart: autoStart ?? this.autoStart,
    darkMode: darkMode ?? this.darkMode,
    notifications: notifications ?? this.notifications,
    verifyHash: verifyHash ?? this.verifyHash,
    versioningEnabled: versioningEnabled ?? this.versioningEnabled,
    backupMode: backupMode ?? this.backupMode,
    language: language ?? this.language,
    defaultDestinationPath:
        defaultDestinationPath ?? this.defaultDestinationPath,
    themeMode: themeMode ?? this.themeMode,
    autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    backupInterval: backupInterval ?? this.backupInterval,
    notifyOnSuccess: notifyOnSuccess ?? this.notifyOnSuccess,
    notifyOnFailure: notifyOnFailure ?? this.notifyOnFailure,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      autoStart: data.autoStart.present ? data.autoStart.value : this.autoStart,
      darkMode: data.darkMode.present ? data.darkMode.value : this.darkMode,
      notifications: data.notifications.present
          ? data.notifications.value
          : this.notifications,
      verifyHash: data.verifyHash.present
          ? data.verifyHash.value
          : this.verifyHash,
      versioningEnabled: data.versioningEnabled.present
          ? data.versioningEnabled.value
          : this.versioningEnabled,
      backupMode: data.backupMode.present
          ? data.backupMode.value
          : this.backupMode,
      language: data.language.present ? data.language.value : this.language,
      defaultDestinationPath: data.defaultDestinationPath.present
          ? data.defaultDestinationPath.value
          : this.defaultDestinationPath,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      autoBackupEnabled: data.autoBackupEnabled.present
          ? data.autoBackupEnabled.value
          : this.autoBackupEnabled,
      backupInterval: data.backupInterval.present
          ? data.backupInterval.value
          : this.backupInterval,
      notifyOnSuccess: data.notifyOnSuccess.present
          ? data.notifyOnSuccess.value
          : this.notifyOnSuccess,
      notifyOnFailure: data.notifyOnFailure.present
          ? data.notifyOnFailure.value
          : this.notifyOnFailure,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('autoStart: $autoStart, ')
          ..write('darkMode: $darkMode, ')
          ..write('notifications: $notifications, ')
          ..write('verifyHash: $verifyHash, ')
          ..write('versioningEnabled: $versioningEnabled, ')
          ..write('backupMode: $backupMode, ')
          ..write('language: $language, ')
          ..write('defaultDestinationPath: $defaultDestinationPath, ')
          ..write('themeMode: $themeMode, ')
          ..write('autoBackupEnabled: $autoBackupEnabled, ')
          ..write('backupInterval: $backupInterval, ')
          ..write('notifyOnSuccess: $notifyOnSuccess, ')
          ..write('notifyOnFailure: $notifyOnFailure')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    autoStart,
    darkMode,
    notifications,
    verifyHash,
    versioningEnabled,
    backupMode,
    language,
    defaultDestinationPath,
    themeMode,
    autoBackupEnabled,
    backupInterval,
    notifyOnSuccess,
    notifyOnFailure,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.autoStart == this.autoStart &&
          other.darkMode == this.darkMode &&
          other.notifications == this.notifications &&
          other.verifyHash == this.verifyHash &&
          other.versioningEnabled == this.versioningEnabled &&
          other.backupMode == this.backupMode &&
          other.language == this.language &&
          other.defaultDestinationPath == this.defaultDestinationPath &&
          other.themeMode == this.themeMode &&
          other.autoBackupEnabled == this.autoBackupEnabled &&
          other.backupInterval == this.backupInterval &&
          other.notifyOnSuccess == this.notifyOnSuccess &&
          other.notifyOnFailure == this.notifyOnFailure);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<bool> autoStart;
  final Value<bool> darkMode;
  final Value<bool> notifications;
  final Value<bool> verifyHash;
  final Value<bool> versioningEnabled;
  final Value<String> backupMode;
  final Value<String> language;
  final Value<String> defaultDestinationPath;
  final Value<String> themeMode;
  final Value<bool> autoBackupEnabled;
  final Value<String> backupInterval;
  final Value<bool> notifyOnSuccess;
  final Value<bool> notifyOnFailure;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.autoStart = const Value.absent(),
    this.darkMode = const Value.absent(),
    this.notifications = const Value.absent(),
    this.verifyHash = const Value.absent(),
    this.versioningEnabled = const Value.absent(),
    this.backupMode = const Value.absent(),
    this.language = const Value.absent(),
    this.defaultDestinationPath = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.autoBackupEnabled = const Value.absent(),
    this.backupInterval = const Value.absent(),
    this.notifyOnSuccess = const Value.absent(),
    this.notifyOnFailure = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.autoStart = const Value.absent(),
    this.darkMode = const Value.absent(),
    this.notifications = const Value.absent(),
    this.verifyHash = const Value.absent(),
    this.versioningEnabled = const Value.absent(),
    this.backupMode = const Value.absent(),
    this.language = const Value.absent(),
    this.defaultDestinationPath = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.autoBackupEnabled = const Value.absent(),
    this.backupInterval = const Value.absent(),
    this.notifyOnSuccess = const Value.absent(),
    this.notifyOnFailure = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<bool>? autoStart,
    Expression<bool>? darkMode,
    Expression<bool>? notifications,
    Expression<bool>? verifyHash,
    Expression<bool>? versioningEnabled,
    Expression<String>? backupMode,
    Expression<String>? language,
    Expression<String>? defaultDestinationPath,
    Expression<String>? themeMode,
    Expression<bool>? autoBackupEnabled,
    Expression<String>? backupInterval,
    Expression<bool>? notifyOnSuccess,
    Expression<bool>? notifyOnFailure,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (autoStart != null) 'auto_start': autoStart,
      if (darkMode != null) 'dark_mode': darkMode,
      if (notifications != null) 'notifications': notifications,
      if (verifyHash != null) 'verify_hash': verifyHash,
      if (versioningEnabled != null) 'versioning_enabled': versioningEnabled,
      if (backupMode != null) 'backup_mode': backupMode,
      if (language != null) 'language': language,
      if (defaultDestinationPath != null)
        'default_destination_path': defaultDestinationPath,
      if (themeMode != null) 'theme_mode': themeMode,
      if (autoBackupEnabled != null) 'auto_backup_enabled': autoBackupEnabled,
      if (backupInterval != null) 'backup_interval': backupInterval,
      if (notifyOnSuccess != null) 'notify_on_success': notifyOnSuccess,
      if (notifyOnFailure != null) 'notify_on_failure': notifyOnFailure,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? autoStart,
    Value<bool>? darkMode,
    Value<bool>? notifications,
    Value<bool>? verifyHash,
    Value<bool>? versioningEnabled,
    Value<String>? backupMode,
    Value<String>? language,
    Value<String>? defaultDestinationPath,
    Value<String>? themeMode,
    Value<bool>? autoBackupEnabled,
    Value<String>? backupInterval,
    Value<bool>? notifyOnSuccess,
    Value<bool>? notifyOnFailure,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      autoStart: autoStart ?? this.autoStart,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      verifyHash: verifyHash ?? this.verifyHash,
      versioningEnabled: versioningEnabled ?? this.versioningEnabled,
      backupMode: backupMode ?? this.backupMode,
      language: language ?? this.language,
      defaultDestinationPath:
          defaultDestinationPath ?? this.defaultDestinationPath,
      themeMode: themeMode ?? this.themeMode,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupInterval: backupInterval ?? this.backupInterval,
      notifyOnSuccess: notifyOnSuccess ?? this.notifyOnSuccess,
      notifyOnFailure: notifyOnFailure ?? this.notifyOnFailure,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (autoStart.present) {
      map['auto_start'] = Variable<bool>(autoStart.value);
    }
    if (darkMode.present) {
      map['dark_mode'] = Variable<bool>(darkMode.value);
    }
    if (notifications.present) {
      map['notifications'] = Variable<bool>(notifications.value);
    }
    if (verifyHash.present) {
      map['verify_hash'] = Variable<bool>(verifyHash.value);
    }
    if (versioningEnabled.present) {
      map['versioning_enabled'] = Variable<bool>(versioningEnabled.value);
    }
    if (backupMode.present) {
      map['backup_mode'] = Variable<String>(backupMode.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (defaultDestinationPath.present) {
      map['default_destination_path'] = Variable<String>(
        defaultDestinationPath.value,
      );
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (autoBackupEnabled.present) {
      map['auto_backup_enabled'] = Variable<bool>(autoBackupEnabled.value);
    }
    if (backupInterval.present) {
      map['backup_interval'] = Variable<String>(backupInterval.value);
    }
    if (notifyOnSuccess.present) {
      map['notify_on_success'] = Variable<bool>(notifyOnSuccess.value);
    }
    if (notifyOnFailure.present) {
      map['notify_on_failure'] = Variable<bool>(notifyOnFailure.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('autoStart: $autoStart, ')
          ..write('darkMode: $darkMode, ')
          ..write('notifications: $notifications, ')
          ..write('verifyHash: $verifyHash, ')
          ..write('versioningEnabled: $versioningEnabled, ')
          ..write('backupMode: $backupMode, ')
          ..write('language: $language, ')
          ..write('defaultDestinationPath: $defaultDestinationPath, ')
          ..write('themeMode: $themeMode, ')
          ..write('autoBackupEnabled: $autoBackupEnabled, ')
          ..write('backupInterval: $backupInterval, ')
          ..write('notifyOnSuccess: $notifyOnSuccess, ')
          ..write('notifyOnFailure: $notifyOnFailure')
          ..write(')'))
        .toString();
  }
}

class $BackupHistoryTable extends BackupHistory
    with TableInfo<$BackupHistoryTable, BackupHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES backup_folders (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filesCountMeta = const VerificationMeta(
    'filesCount',
  );
  @override
  late final GeneratedColumn<int> filesCount = GeneratedColumn<int>(
    'files_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalSizeMeta = const VerificationMeta(
    'totalSize',
  );
  @override
  late final GeneratedColumn<int> totalSize = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _backupTypeMeta = const VerificationMeta(
    'backupType',
  );
  @override
  late final GeneratedColumn<String> backupType = GeneratedColumn<String>(
    'backup_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('full'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    timestamp,
    status,
    message,
    filesCount,
    totalSize,
    backupType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('files_count')) {
      context.handle(
        _filesCountMeta,
        filesCount.isAcceptableOrUnknown(data['files_count']!, _filesCountMeta),
      );
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _totalSizeMeta,
        totalSize.isAcceptableOrUnknown(data['total_size']!, _totalSizeMeta),
      );
    }
    if (data.containsKey('backup_type')) {
      context.handle(
        _backupTypeMeta,
        backupType.isAcceptableOrUnknown(data['backup_type']!, _backupTypeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      filesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}files_count'],
      )!,
      totalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      )!,
      backupType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_type'],
      )!,
    );
  }

  @override
  $BackupHistoryTable createAlias(String alias) {
    return $BackupHistoryTable(attachedDatabase, alias);
  }
}

class BackupHistoryData extends DataClass
    implements Insertable<BackupHistoryData> {
  final int id;
  final int? folderId;
  final DateTime timestamp;
  final String status;
  final String message;
  final int filesCount;
  final int totalSize;
  final String backupType;
  const BackupHistoryData({
    required this.id,
    this.folderId,
    required this.timestamp,
    required this.status,
    required this.message,
    required this.filesCount,
    required this.totalSize,
    required this.backupType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['status'] = Variable<String>(status);
    map['message'] = Variable<String>(message);
    map['files_count'] = Variable<int>(filesCount);
    map['total_size'] = Variable<int>(totalSize);
    map['backup_type'] = Variable<String>(backupType);
    return map;
  }

  BackupHistoryCompanion toCompanion(bool nullToAbsent) {
    return BackupHistoryCompanion(
      id: Value(id),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      timestamp: Value(timestamp),
      status: Value(status),
      message: Value(message),
      filesCount: Value(filesCount),
      totalSize: Value(totalSize),
      backupType: Value(backupType),
    );
  }

  factory BackupHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupHistoryData(
      id: serializer.fromJson<int>(json['id']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String>(json['message']),
      filesCount: serializer.fromJson<int>(json['filesCount']),
      totalSize: serializer.fromJson<int>(json['totalSize']),
      backupType: serializer.fromJson<String>(json['backupType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'folderId': serializer.toJson<int?>(folderId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String>(message),
      'filesCount': serializer.toJson<int>(filesCount),
      'totalSize': serializer.toJson<int>(totalSize),
      'backupType': serializer.toJson<String>(backupType),
    };
  }

  BackupHistoryData copyWith({
    int? id,
    Value<int?> folderId = const Value.absent(),
    DateTime? timestamp,
    String? status,
    String? message,
    int? filesCount,
    int? totalSize,
    String? backupType,
  }) => BackupHistoryData(
    id: id ?? this.id,
    folderId: folderId.present ? folderId.value : this.folderId,
    timestamp: timestamp ?? this.timestamp,
    status: status ?? this.status,
    message: message ?? this.message,
    filesCount: filesCount ?? this.filesCount,
    totalSize: totalSize ?? this.totalSize,
    backupType: backupType ?? this.backupType,
  );
  BackupHistoryData copyWithCompanion(BackupHistoryCompanion data) {
    return BackupHistoryData(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
      filesCount: data.filesCount.present
          ? data.filesCount.value
          : this.filesCount,
      totalSize: data.totalSize.present ? data.totalSize.value : this.totalSize,
      backupType: data.backupType.present
          ? data.backupType.value
          : this.backupType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupHistoryData(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('filesCount: $filesCount, ')
          ..write('totalSize: $totalSize, ')
          ..write('backupType: $backupType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    timestamp,
    status,
    message,
    filesCount,
    totalSize,
    backupType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupHistoryData &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.timestamp == this.timestamp &&
          other.status == this.status &&
          other.message == this.message &&
          other.filesCount == this.filesCount &&
          other.totalSize == this.totalSize &&
          other.backupType == this.backupType);
}

class BackupHistoryCompanion extends UpdateCompanion<BackupHistoryData> {
  final Value<int> id;
  final Value<int?> folderId;
  final Value<DateTime> timestamp;
  final Value<String> status;
  final Value<String> message;
  final Value<int> filesCount;
  final Value<int> totalSize;
  final Value<String> backupType;
  const BackupHistoryCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
    this.filesCount = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.backupType = const Value.absent(),
  });
  BackupHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.timestamp = const Value.absent(),
    required String status,
    required String message,
    this.filesCount = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.backupType = const Value.absent(),
  }) : status = Value(status),
       message = Value(message);
  static Insertable<BackupHistoryData> custom({
    Expression<int>? id,
    Expression<int>? folderId,
    Expression<DateTime>? timestamp,
    Expression<String>? status,
    Expression<String>? message,
    Expression<int>? filesCount,
    Expression<int>? totalSize,
    Expression<String>? backupType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (filesCount != null) 'files_count': filesCount,
      if (totalSize != null) 'total_size': totalSize,
      if (backupType != null) 'backup_type': backupType,
    });
  }

  BackupHistoryCompanion copyWith({
    Value<int>? id,
    Value<int?>? folderId,
    Value<DateTime>? timestamp,
    Value<String>? status,
    Value<String>? message,
    Value<int>? filesCount,
    Value<int>? totalSize,
    Value<String>? backupType,
  }) {
    return BackupHistoryCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      message: message ?? this.message,
      filesCount: filesCount ?? this.filesCount,
      totalSize: totalSize ?? this.totalSize,
      backupType: backupType ?? this.backupType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (filesCount.present) {
      map['files_count'] = Variable<int>(filesCount.value);
    }
    if (totalSize.present) {
      map['total_size'] = Variable<int>(totalSize.value);
    }
    if (backupType.present) {
      map['backup_type'] = Variable<String>(backupType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupHistoryCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('filesCount: $filesCount, ')
          ..write('totalSize: $totalSize, ')
          ..write('backupType: $backupType')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoriesTable extends SearchHistories
    with TableInfo<$SearchHistoriesTable, SearchHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, query, createdAt, pinned];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
    );
  }

  @override
  $SearchHistoriesTable createAlias(String alias) {
    return $SearchHistoriesTable(attachedDatabase, alias);
  }
}

class SearchHistory extends DataClass implements Insertable<SearchHistory> {
  final int id;
  final String query;
  final DateTime createdAt;
  final bool pinned;
  const SearchHistory({
    required this.id,
    required this.query,
    required this.createdAt,
    required this.pinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query'] = Variable<String>(query);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['pinned'] = Variable<bool>(pinned);
    return map;
  }

  SearchHistoriesCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoriesCompanion(
      id: Value(id),
      query: Value(query),
      createdAt: Value(createdAt),
      pinned: Value(pinned),
    );
  }

  factory SearchHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistory(
      id: serializer.fromJson<int>(json['id']),
      query: serializer.fromJson<String>(json['query']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      pinned: serializer.fromJson<bool>(json['pinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'query': serializer.toJson<String>(query),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'pinned': serializer.toJson<bool>(pinned),
    };
  }

  SearchHistory copyWith({
    int? id,
    String? query,
    DateTime? createdAt,
    bool? pinned,
  }) => SearchHistory(
    id: id ?? this.id,
    query: query ?? this.query,
    createdAt: createdAt ?? this.createdAt,
    pinned: pinned ?? this.pinned,
  );
  SearchHistory copyWithCompanion(SearchHistoriesCompanion data) {
    return SearchHistory(
      id: data.id.present ? data.id.value : this.id,
      query: data.query.present ? data.query.value : this.query,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistory(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('createdAt: $createdAt, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, query, createdAt, pinned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistory &&
          other.id == this.id &&
          other.query == this.query &&
          other.createdAt == this.createdAt &&
          other.pinned == this.pinned);
}

class SearchHistoriesCompanion extends UpdateCompanion<SearchHistory> {
  final Value<int> id;
  final Value<String> query;
  final Value<DateTime> createdAt;
  final Value<bool> pinned;
  const SearchHistoriesCompanion({
    this.id = const Value.absent(),
    this.query = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pinned = const Value.absent(),
  });
  SearchHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String query,
    this.createdAt = const Value.absent(),
    this.pinned = const Value.absent(),
  }) : query = Value(query);
  static Insertable<SearchHistory> custom({
    Expression<int>? id,
    Expression<String>? query,
    Expression<DateTime>? createdAt,
    Expression<bool>? pinned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (query != null) 'query': query,
      if (createdAt != null) 'created_at': createdAt,
      if (pinned != null) 'pinned': pinned,
    });
  }

  SearchHistoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? query,
    Value<DateTime>? createdAt,
    Value<bool>? pinned,
  }) {
    return SearchHistoriesCompanion(
      id: id ?? this.id,
      query: query ?? this.query,
      createdAt: createdAt ?? this.createdAt,
      pinned: pinned ?? this.pinned,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('createdAt: $createdAt, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }
}

class $PairedDevicesTable extends PairedDevices
    with TableInfo<$PairedDevicesTable, PairedDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PairedDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceUuidMeta = const VerificationMeta(
    'deviceUuid',
  );
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
    'device_uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _osVersionMeta = const VerificationMeta(
    'osVersion',
  );
  @override
  late final GeneratedColumn<String> osVersion = GeneratedColumn<String>(
    'os_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceModelMeta = const VerificationMeta(
    'deviceModel',
  );
  @override
  late final GeneratedColumn<String> deviceModel = GeneratedColumn<String>(
    'device_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceUuid,
    deviceName,
    platform,
    osVersion,
    appVersion,
    deviceModel,
    createdAt,
    lastSeen,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paired_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<PairedDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_uuid')) {
      context.handle(
        _deviceUuidMeta,
        deviceUuid.isAcceptableOrUnknown(data['device_uuid']!, _deviceUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceUuidMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('os_version')) {
      context.handle(
        _osVersionMeta,
        osVersion.isAcceptableOrUnknown(data['os_version']!, _osVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_osVersionMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('device_model')) {
      context.handle(
        _deviceModelMeta,
        deviceModel.isAcceptableOrUnknown(
          data['device_model']!,
          _deviceModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceModelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceUuid};
  @override
  PairedDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairedDevice(
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      osVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os_version'],
      )!,
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      deviceModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_model'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $PairedDevicesTable createAlias(String alias) {
    return $PairedDevicesTable(attachedDatabase, alias);
  }
}

class PairedDevice extends DataClass implements Insertable<PairedDevice> {
  final String deviceUuid;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String appVersion;
  final String deviceModel;
  final DateTime createdAt;
  final DateTime lastSeen;
  final String status;
  const PairedDevice({
    required this.deviceUuid,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.deviceModel,
    required this.createdAt,
    required this.lastSeen,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_uuid'] = Variable<String>(deviceUuid);
    map['device_name'] = Variable<String>(deviceName);
    map['platform'] = Variable<String>(platform);
    map['os_version'] = Variable<String>(osVersion);
    map['app_version'] = Variable<String>(appVersion);
    map['device_model'] = Variable<String>(deviceModel);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['status'] = Variable<String>(status);
    return map;
  }

  PairedDevicesCompanion toCompanion(bool nullToAbsent) {
    return PairedDevicesCompanion(
      deviceUuid: Value(deviceUuid),
      deviceName: Value(deviceName),
      platform: Value(platform),
      osVersion: Value(osVersion),
      appVersion: Value(appVersion),
      deviceModel: Value(deviceModel),
      createdAt: Value(createdAt),
      lastSeen: Value(lastSeen),
      status: Value(status),
    );
  }

  factory PairedDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairedDevice(
      deviceUuid: serializer.fromJson<String>(json['deviceUuid']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      platform: serializer.fromJson<String>(json['platform']),
      osVersion: serializer.fromJson<String>(json['osVersion']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      deviceModel: serializer.fromJson<String>(json['deviceModel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceUuid': serializer.toJson<String>(deviceUuid),
      'deviceName': serializer.toJson<String>(deviceName),
      'platform': serializer.toJson<String>(platform),
      'osVersion': serializer.toJson<String>(osVersion),
      'appVersion': serializer.toJson<String>(appVersion),
      'deviceModel': serializer.toJson<String>(deviceModel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'status': serializer.toJson<String>(status),
    };
  }

  PairedDevice copyWith({
    String? deviceUuid,
    String? deviceName,
    String? platform,
    String? osVersion,
    String? appVersion,
    String? deviceModel,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? status,
  }) => PairedDevice(
    deviceUuid: deviceUuid ?? this.deviceUuid,
    deviceName: deviceName ?? this.deviceName,
    platform: platform ?? this.platform,
    osVersion: osVersion ?? this.osVersion,
    appVersion: appVersion ?? this.appVersion,
    deviceModel: deviceModel ?? this.deviceModel,
    createdAt: createdAt ?? this.createdAt,
    lastSeen: lastSeen ?? this.lastSeen,
    status: status ?? this.status,
  );
  PairedDevice copyWithCompanion(PairedDevicesCompanion data) {
    return PairedDevice(
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      platform: data.platform.present ? data.platform.value : this.platform,
      osVersion: data.osVersion.present ? data.osVersion.value : this.osVersion,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      deviceModel: data.deviceModel.present
          ? data.deviceModel.value
          : this.deviceModel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevice(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('platform: $platform, ')
          ..write('osVersion: $osVersion, ')
          ..write('appVersion: $appVersion, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceUuid,
    deviceName,
    platform,
    osVersion,
    appVersion,
    deviceModel,
    createdAt,
    lastSeen,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairedDevice &&
          other.deviceUuid == this.deviceUuid &&
          other.deviceName == this.deviceName &&
          other.platform == this.platform &&
          other.osVersion == this.osVersion &&
          other.appVersion == this.appVersion &&
          other.deviceModel == this.deviceModel &&
          other.createdAt == this.createdAt &&
          other.lastSeen == this.lastSeen &&
          other.status == this.status);
}

class PairedDevicesCompanion extends UpdateCompanion<PairedDevice> {
  final Value<String> deviceUuid;
  final Value<String> deviceName;
  final Value<String> platform;
  final Value<String> osVersion;
  final Value<String> appVersion;
  final Value<String> deviceModel;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastSeen;
  final Value<String> status;
  final Value<int> rowid;
  const PairedDevicesCompanion({
    this.deviceUuid = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.platform = const Value.absent(),
    this.osVersion = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.deviceModel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairedDevicesCompanion.insert({
    required String deviceUuid,
    required String deviceName,
    required String platform,
    required String osVersion,
    required String appVersion,
    required String deviceModel,
    this.createdAt = const Value.absent(),
    this.lastSeen = const Value.absent(),
    required String status,
    this.rowid = const Value.absent(),
  }) : deviceUuid = Value(deviceUuid),
       deviceName = Value(deviceName),
       platform = Value(platform),
       osVersion = Value(osVersion),
       appVersion = Value(appVersion),
       deviceModel = Value(deviceModel),
       status = Value(status);
  static Insertable<PairedDevice> custom({
    Expression<String>? deviceUuid,
    Expression<String>? deviceName,
    Expression<String>? platform,
    Expression<String>? osVersion,
    Expression<String>? appVersion,
    Expression<String>? deviceModel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSeen,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (deviceName != null) 'device_name': deviceName,
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'os_version': osVersion,
      if (appVersion != null) 'app_version': appVersion,
      if (deviceModel != null) 'device_model': deviceModel,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairedDevicesCompanion copyWith({
    Value<String>? deviceUuid,
    Value<String>? deviceName,
    Value<String>? platform,
    Value<String>? osVersion,
    Value<String>? appVersion,
    Value<String>? deviceModel,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastSeen,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return PairedDevicesCompanion(
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      deviceModel: deviceModel ?? this.deviceModel,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (osVersion.present) {
      map['os_version'] = Variable<String>(osVersion.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (deviceModel.present) {
      map['device_model'] = Variable<String>(deviceModel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesCompanion(')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('deviceName: $deviceName, ')
          ..write('platform: $platform, ')
          ..write('osVersion: $osVersion, ')
          ..write('appVersion: $appVersion, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupJobsTable extends BackupJobs
    with TableInfo<$BackupJobsTable, BackupJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceUuidMeta = const VerificationMeta(
    'deviceUuid',
  );
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
    'device_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderUuidMeta = const VerificationMeta(
    'folderUuid',
  );
  @override
  late final GeneratedColumn<String> folderUuid = GeneratedColumn<String>(
    'folder_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationUuidMeta = const VerificationMeta(
    'destinationUuid',
  );
  @override
  late final GeneratedColumn<String> destinationUuid = GeneratedColumn<String>(
    'destination_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedTimeMeta = const VerificationMeta(
    'startedTime',
  );
  @override
  late final GeneratedColumn<DateTime> startedTime = GeneratedColumn<DateTime>(
    'started_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedTimeMeta = const VerificationMeta(
    'completedTime',
  );
  @override
  late final GeneratedColumn<DateTime> completedTime =
      GeneratedColumn<DateTime>(
        'completed_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFilesMeta = const VerificationMeta(
    'totalFiles',
  );
  @override
  late final GeneratedColumn<int> totalFiles = GeneratedColumn<int>(
    'total_files',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalSizeMeta = const VerificationMeta(
    'totalSize',
  );
  @override
  late final GeneratedColumn<int> totalSize = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _filesToBackupMeta = const VerificationMeta(
    'filesToBackup',
  );
  @override
  late final GeneratedColumn<int> filesToBackup = GeneratedColumn<int>(
    'files_to_backup',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skippedFilesMeta = const VerificationMeta(
    'skippedFiles',
  );
  @override
  late final GeneratedColumn<int> skippedFiles = GeneratedColumn<int>(
    'skipped_files',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceUuid,
    folderUuid,
    folderId,
    destinationUuid,
    createdAt,
    startedTime,
    completedTime,
    status,
    progress,
    totalFiles,
    totalSize,
    filesToBackup,
    skippedFiles,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_uuid')) {
      context.handle(
        _deviceUuidMeta,
        deviceUuid.isAcceptableOrUnknown(data['device_uuid']!, _deviceUuidMeta),
      );
    }
    if (data.containsKey('folder_uuid')) {
      context.handle(
        _folderUuidMeta,
        folderUuid.isAcceptableOrUnknown(data['folder_uuid']!, _folderUuidMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('destination_uuid')) {
      context.handle(
        _destinationUuidMeta,
        destinationUuid.isAcceptableOrUnknown(
          data['destination_uuid']!,
          _destinationUuidMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('started_time')) {
      context.handle(
        _startedTimeMeta,
        startedTime.isAcceptableOrUnknown(
          data['started_time']!,
          _startedTimeMeta,
        ),
      );
    }
    if (data.containsKey('completed_time')) {
      context.handle(
        _completedTimeMeta,
        completedTime.isAcceptableOrUnknown(
          data['completed_time']!,
          _completedTimeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('total_files')) {
      context.handle(
        _totalFilesMeta,
        totalFiles.isAcceptableOrUnknown(data['total_files']!, _totalFilesMeta),
      );
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _totalSizeMeta,
        totalSize.isAcceptableOrUnknown(data['total_size']!, _totalSizeMeta),
      );
    }
    if (data.containsKey('files_to_backup')) {
      context.handle(
        _filesToBackupMeta,
        filesToBackup.isAcceptableOrUnknown(
          data['files_to_backup']!,
          _filesToBackupMeta,
        ),
      );
    }
    if (data.containsKey('skipped_files')) {
      context.handle(
        _skippedFilesMeta,
        skippedFiles.isAcceptableOrUnknown(
          data['skipped_files']!,
          _skippedFilesMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      ),
      folderUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_uuid'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      )!,
      destinationUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_uuid'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      startedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_time'],
      ),
      completedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      totalFiles: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_files'],
      )!,
      totalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      )!,
      filesToBackup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}files_to_backup'],
      )!,
      skippedFiles: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_files'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $BackupJobsTable createAlias(String alias) {
    return $BackupJobsTable(attachedDatabase, alias);
  }
}

class BackupJob extends DataClass implements Insertable<BackupJob> {
  final String id;
  final String? deviceUuid;
  final String? folderUuid;
  final int folderId;
  final String? destinationUuid;
  final DateTime createdAt;
  final DateTime? startedTime;
  final DateTime? completedTime;
  final String status;
  final double progress;
  final int totalFiles;
  final int totalSize;
  final int filesToBackup;
  final int skippedFiles;
  final String? error;
  const BackupJob({
    required this.id,
    this.deviceUuid,
    this.folderUuid,
    required this.folderId,
    this.destinationUuid,
    required this.createdAt,
    this.startedTime,
    this.completedTime,
    required this.status,
    required this.progress,
    required this.totalFiles,
    required this.totalSize,
    required this.filesToBackup,
    required this.skippedFiles,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || deviceUuid != null) {
      map['device_uuid'] = Variable<String>(deviceUuid);
    }
    if (!nullToAbsent || folderUuid != null) {
      map['folder_uuid'] = Variable<String>(folderUuid);
    }
    map['folder_id'] = Variable<int>(folderId);
    if (!nullToAbsent || destinationUuid != null) {
      map['destination_uuid'] = Variable<String>(destinationUuid);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedTime != null) {
      map['started_time'] = Variable<DateTime>(startedTime);
    }
    if (!nullToAbsent || completedTime != null) {
      map['completed_time'] = Variable<DateTime>(completedTime);
    }
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    map['total_files'] = Variable<int>(totalFiles);
    map['total_size'] = Variable<int>(totalSize);
    map['files_to_backup'] = Variable<int>(filesToBackup);
    map['skipped_files'] = Variable<int>(skippedFiles);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  BackupJobsCompanion toCompanion(bool nullToAbsent) {
    return BackupJobsCompanion(
      id: Value(id),
      deviceUuid: deviceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceUuid),
      folderUuid: folderUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(folderUuid),
      folderId: Value(folderId),
      destinationUuid: destinationUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationUuid),
      createdAt: Value(createdAt),
      startedTime: startedTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startedTime),
      completedTime: completedTime == null && nullToAbsent
          ? const Value.absent()
          : Value(completedTime),
      status: Value(status),
      progress: Value(progress),
      totalFiles: Value(totalFiles),
      totalSize: Value(totalSize),
      filesToBackup: Value(filesToBackup),
      skippedFiles: Value(skippedFiles),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory BackupJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupJob(
      id: serializer.fromJson<String>(json['id']),
      deviceUuid: serializer.fromJson<String?>(json['deviceUuid']),
      folderUuid: serializer.fromJson<String?>(json['folderUuid']),
      folderId: serializer.fromJson<int>(json['folderId']),
      destinationUuid: serializer.fromJson<String?>(json['destinationUuid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedTime: serializer.fromJson<DateTime?>(json['startedTime']),
      completedTime: serializer.fromJson<DateTime?>(json['completedTime']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      totalFiles: serializer.fromJson<int>(json['totalFiles']),
      totalSize: serializer.fromJson<int>(json['totalSize']),
      filesToBackup: serializer.fromJson<int>(json['filesToBackup']),
      skippedFiles: serializer.fromJson<int>(json['skippedFiles']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceUuid': serializer.toJson<String?>(deviceUuid),
      'folderUuid': serializer.toJson<String?>(folderUuid),
      'folderId': serializer.toJson<int>(folderId),
      'destinationUuid': serializer.toJson<String?>(destinationUuid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedTime': serializer.toJson<DateTime?>(startedTime),
      'completedTime': serializer.toJson<DateTime?>(completedTime),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'totalFiles': serializer.toJson<int>(totalFiles),
      'totalSize': serializer.toJson<int>(totalSize),
      'filesToBackup': serializer.toJson<int>(filesToBackup),
      'skippedFiles': serializer.toJson<int>(skippedFiles),
      'error': serializer.toJson<String?>(error),
    };
  }

  BackupJob copyWith({
    String? id,
    Value<String?> deviceUuid = const Value.absent(),
    Value<String?> folderUuid = const Value.absent(),
    int? folderId,
    Value<String?> destinationUuid = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> startedTime = const Value.absent(),
    Value<DateTime?> completedTime = const Value.absent(),
    String? status,
    double? progress,
    int? totalFiles,
    int? totalSize,
    int? filesToBackup,
    int? skippedFiles,
    Value<String?> error = const Value.absent(),
  }) => BackupJob(
    id: id ?? this.id,
    deviceUuid: deviceUuid.present ? deviceUuid.value : this.deviceUuid,
    folderUuid: folderUuid.present ? folderUuid.value : this.folderUuid,
    folderId: folderId ?? this.folderId,
    destinationUuid: destinationUuid.present
        ? destinationUuid.value
        : this.destinationUuid,
    createdAt: createdAt ?? this.createdAt,
    startedTime: startedTime.present ? startedTime.value : this.startedTime,
    completedTime: completedTime.present
        ? completedTime.value
        : this.completedTime,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    totalFiles: totalFiles ?? this.totalFiles,
    totalSize: totalSize ?? this.totalSize,
    filesToBackup: filesToBackup ?? this.filesToBackup,
    skippedFiles: skippedFiles ?? this.skippedFiles,
    error: error.present ? error.value : this.error,
  );
  BackupJob copyWithCompanion(BackupJobsCompanion data) {
    return BackupJob(
      id: data.id.present ? data.id.value : this.id,
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      folderUuid: data.folderUuid.present
          ? data.folderUuid.value
          : this.folderUuid,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      destinationUuid: data.destinationUuid.present
          ? data.destinationUuid.value
          : this.destinationUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedTime: data.startedTime.present
          ? data.startedTime.value
          : this.startedTime,
      completedTime: data.completedTime.present
          ? data.completedTime.value
          : this.completedTime,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      totalFiles: data.totalFiles.present
          ? data.totalFiles.value
          : this.totalFiles,
      totalSize: data.totalSize.present ? data.totalSize.value : this.totalSize,
      filesToBackup: data.filesToBackup.present
          ? data.filesToBackup.value
          : this.filesToBackup,
      skippedFiles: data.skippedFiles.present
          ? data.skippedFiles.value
          : this.skippedFiles,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupJob(')
          ..write('id: $id, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('folderUuid: $folderUuid, ')
          ..write('folderId: $folderId, ')
          ..write('destinationUuid: $destinationUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedTime: $startedTime, ')
          ..write('completedTime: $completedTime, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalSize: $totalSize, ')
          ..write('filesToBackup: $filesToBackup, ')
          ..write('skippedFiles: $skippedFiles, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceUuid,
    folderUuid,
    folderId,
    destinationUuid,
    createdAt,
    startedTime,
    completedTime,
    status,
    progress,
    totalFiles,
    totalSize,
    filesToBackup,
    skippedFiles,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupJob &&
          other.id == this.id &&
          other.deviceUuid == this.deviceUuid &&
          other.folderUuid == this.folderUuid &&
          other.folderId == this.folderId &&
          other.destinationUuid == this.destinationUuid &&
          other.createdAt == this.createdAt &&
          other.startedTime == this.startedTime &&
          other.completedTime == this.completedTime &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.totalFiles == this.totalFiles &&
          other.totalSize == this.totalSize &&
          other.filesToBackup == this.filesToBackup &&
          other.skippedFiles == this.skippedFiles &&
          other.error == this.error);
}

class BackupJobsCompanion extends UpdateCompanion<BackupJob> {
  final Value<String> id;
  final Value<String?> deviceUuid;
  final Value<String?> folderUuid;
  final Value<int> folderId;
  final Value<String?> destinationUuid;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedTime;
  final Value<DateTime?> completedTime;
  final Value<String> status;
  final Value<double> progress;
  final Value<int> totalFiles;
  final Value<int> totalSize;
  final Value<int> filesToBackup;
  final Value<int> skippedFiles;
  final Value<String?> error;
  final Value<int> rowid;
  const BackupJobsCompanion({
    this.id = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.folderUuid = const Value.absent(),
    this.folderId = const Value.absent(),
    this.destinationUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedTime = const Value.absent(),
    this.completedTime = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalFiles = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.filesToBackup = const Value.absent(),
    this.skippedFiles = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupJobsCompanion.insert({
    required String id,
    this.deviceUuid = const Value.absent(),
    this.folderUuid = const Value.absent(),
    required int folderId,
    this.destinationUuid = const Value.absent(),
    required DateTime createdAt,
    this.startedTime = const Value.absent(),
    this.completedTime = const Value.absent(),
    required String status,
    required double progress,
    this.totalFiles = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.filesToBackup = const Value.absent(),
    this.skippedFiles = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       folderId = Value(folderId),
       createdAt = Value(createdAt),
       status = Value(status),
       progress = Value(progress);
  static Insertable<BackupJob> custom({
    Expression<String>? id,
    Expression<String>? deviceUuid,
    Expression<String>? folderUuid,
    Expression<int>? folderId,
    Expression<String>? destinationUuid,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedTime,
    Expression<DateTime>? completedTime,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? totalFiles,
    Expression<int>? totalSize,
    Expression<int>? filesToBackup,
    Expression<int>? skippedFiles,
    Expression<String>? error,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (folderUuid != null) 'folder_uuid': folderUuid,
      if (folderId != null) 'folder_id': folderId,
      if (destinationUuid != null) 'destination_uuid': destinationUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (startedTime != null) 'started_time': startedTime,
      if (completedTime != null) 'completed_time': completedTime,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (totalFiles != null) 'total_files': totalFiles,
      if (totalSize != null) 'total_size': totalSize,
      if (filesToBackup != null) 'files_to_backup': filesToBackup,
      if (skippedFiles != null) 'skipped_files': skippedFiles,
      if (error != null) 'error': error,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupJobsCompanion copyWith({
    Value<String>? id,
    Value<String?>? deviceUuid,
    Value<String?>? folderUuid,
    Value<int>? folderId,
    Value<String?>? destinationUuid,
    Value<DateTime>? createdAt,
    Value<DateTime?>? startedTime,
    Value<DateTime?>? completedTime,
    Value<String>? status,
    Value<double>? progress,
    Value<int>? totalFiles,
    Value<int>? totalSize,
    Value<int>? filesToBackup,
    Value<int>? skippedFiles,
    Value<String?>? error,
    Value<int>? rowid,
  }) {
    return BackupJobsCompanion(
      id: id ?? this.id,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      folderUuid: folderUuid ?? this.folderUuid,
      folderId: folderId ?? this.folderId,
      destinationUuid: destinationUuid ?? this.destinationUuid,
      createdAt: createdAt ?? this.createdAt,
      startedTime: startedTime ?? this.startedTime,
      completedTime: completedTime ?? this.completedTime,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalFiles: totalFiles ?? this.totalFiles,
      totalSize: totalSize ?? this.totalSize,
      filesToBackup: filesToBackup ?? this.filesToBackup,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      error: error ?? this.error,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (folderUuid.present) {
      map['folder_uuid'] = Variable<String>(folderUuid.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (destinationUuid.present) {
      map['destination_uuid'] = Variable<String>(destinationUuid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedTime.present) {
      map['started_time'] = Variable<DateTime>(startedTime.value);
    }
    if (completedTime.present) {
      map['completed_time'] = Variable<DateTime>(completedTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (totalFiles.present) {
      map['total_files'] = Variable<int>(totalFiles.value);
    }
    if (totalSize.present) {
      map['total_size'] = Variable<int>(totalSize.value);
    }
    if (filesToBackup.present) {
      map['files_to_backup'] = Variable<int>(filesToBackup.value);
    }
    if (skippedFiles.present) {
      map['skipped_files'] = Variable<int>(skippedFiles.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupJobsCompanion(')
          ..write('id: $id, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('folderUuid: $folderUuid, ')
          ..write('folderId: $folderId, ')
          ..write('destinationUuid: $destinationUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedTime: $startedTime, ')
          ..write('completedTime: $completedTime, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalSize: $totalSize, ')
          ..write('filesToBackup: $filesToBackup, ')
          ..write('skippedFiles: $skippedFiles, ')
          ..write('error: $error, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FileTransfersTable extends FileTransfers
    with TableInfo<$FileTransfersTable, FileTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferredBytesMeta = const VerificationMeta(
    'transferredBytes',
  );
  @override
  late final GeneratedColumn<int> transferredBytes = GeneratedColumn<int>(
    'transferred_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    fileName,
    relativePath,
    fileSize,
    hash,
    status,
    transferredBytes,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileTransfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('transferred_bytes')) {
      context.handle(
        _transferredBytesMeta,
        transferredBytes.isAcceptableOrUnknown(
          data['transferred_bytes']!,
          _transferredBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferredBytesMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileTransfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      transferredBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transferred_bytes'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $FileTransfersTable createAlias(String alias) {
    return $FileTransfersTable(attachedDatabase, alias);
  }
}

class FileTransfer extends DataClass implements Insertable<FileTransfer> {
  final String id;
  final String sessionId;
  final String fileName;
  final String relativePath;
  final int fileSize;
  final String? hash;
  final String status;
  final int transferredBytes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  const FileTransfer({
    required this.id,
    required this.sessionId,
    required this.fileName,
    required this.relativePath,
    required this.fileSize,
    this.hash,
    required this.status,
    required this.transferredBytes,
    this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['file_name'] = Variable<String>(fileName);
    map['relative_path'] = Variable<String>(relativePath);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    map['status'] = Variable<String>(status);
    map['transferred_bytes'] = Variable<int>(transferredBytes);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  FileTransfersCompanion toCompanion(bool nullToAbsent) {
    return FileTransfersCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      fileName: Value(fileName),
      relativePath: Value(relativePath),
      fileSize: Value(fileSize),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      status: Value(status),
      transferredBytes: Value(transferredBytes),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory FileTransfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileTransfer(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      hash: serializer.fromJson<String?>(json['hash']),
      status: serializer.fromJson<String>(json['status']),
      transferredBytes: serializer.fromJson<int>(json['transferredBytes']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'fileName': serializer.toJson<String>(fileName),
      'relativePath': serializer.toJson<String>(relativePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'hash': serializer.toJson<String?>(hash),
      'status': serializer.toJson<String>(status),
      'transferredBytes': serializer.toJson<int>(transferredBytes),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  FileTransfer copyWith({
    String? id,
    String? sessionId,
    String? fileName,
    String? relativePath,
    int? fileSize,
    Value<String?> hash = const Value.absent(),
    String? status,
    int? transferredBytes,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => FileTransfer(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    fileName: fileName ?? this.fileName,
    relativePath: relativePath ?? this.relativePath,
    fileSize: fileSize ?? this.fileSize,
    hash: hash.present ? hash.value : this.hash,
    status: status ?? this.status,
    transferredBytes: transferredBytes ?? this.transferredBytes,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  FileTransfer copyWithCompanion(FileTransfersCompanion data) {
    return FileTransfer(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      hash: data.hash.present ? data.hash.value : this.hash,
      status: data.status.present ? data.status.value : this.status,
      transferredBytes: data.transferredBytes.present
          ? data.transferredBytes.value
          : this.transferredBytes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileTransfer(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('fileName: $fileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('hash: $hash, ')
          ..write('status: $status, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    fileName,
    relativePath,
    fileSize,
    hash,
    status,
    transferredBytes,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileTransfer &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.fileName == this.fileName &&
          other.relativePath == this.relativePath &&
          other.fileSize == this.fileSize &&
          other.hash == this.hash &&
          other.status == this.status &&
          other.transferredBytes == this.transferredBytes &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class FileTransfersCompanion extends UpdateCompanion<FileTransfer> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> fileName;
  final Value<String> relativePath;
  final Value<int> fileSize;
  final Value<String?> hash;
  final Value<String> status;
  final Value<int> transferredBytes;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const FileTransfersCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.hash = const Value.absent(),
    this.status = const Value.absent(),
    this.transferredBytes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileTransfersCompanion.insert({
    required String id,
    required String sessionId,
    required String fileName,
    required String relativePath,
    required int fileSize,
    this.hash = const Value.absent(),
    required String status,
    required int transferredBytes,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       fileName = Value(fileName),
       relativePath = Value(relativePath),
       fileSize = Value(fileSize),
       status = Value(status),
       transferredBytes = Value(transferredBytes);
  static Insertable<FileTransfer> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? fileName,
    Expression<String>? relativePath,
    Expression<int>? fileSize,
    Expression<String>? hash,
    Expression<String>? status,
    Expression<int>? transferredBytes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (fileName != null) 'file_name': fileName,
      if (relativePath != null) 'relative_path': relativePath,
      if (fileSize != null) 'file_size': fileSize,
      if (hash != null) 'hash': hash,
      if (status != null) 'status': status,
      if (transferredBytes != null) 'transferred_bytes': transferredBytes,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileTransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? fileName,
    Value<String>? relativePath,
    Value<int>? fileSize,
    Value<String?>? hash,
    Value<String>? status,
    Value<int>? transferredBytes,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return FileTransfersCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      fileName: fileName ?? this.fileName,
      relativePath: relativePath ?? this.relativePath,
      fileSize: fileSize ?? this.fileSize,
      hash: hash ?? this.hash,
      status: status ?? this.status,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (transferredBytes.present) {
      map['transferred_bytes'] = Variable<int>(transferredBytes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileTransfersCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('fileName: $fileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('hash: $hash, ')
          ..write('status: $status, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BackupFoldersTable backupFolders = $BackupFoldersTable(this);
  late final $BackupFilesTable backupFiles = $BackupFilesTable(this);
  late final $FileVersionsTable fileVersions = $FileVersionsTable(this);
  late final $BackupLogsTable backupLogs = $BackupLogsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $BackupHistoryTable backupHistory = $BackupHistoryTable(this);
  late final $SearchHistoriesTable searchHistories = $SearchHistoriesTable(
    this,
  );
  late final $PairedDevicesTable pairedDevices = $PairedDevicesTable(this);
  late final $BackupJobsTable backupJobs = $BackupJobsTable(this);
  late final $FileTransfersTable fileTransfers = $FileTransfersTable(this);
  late final Index idxBackupFilesName = Index(
    'idx_backup_files_name',
    'CREATE INDEX idx_backup_files_name ON backup_files (file_name)',
  );
  late final Index idxBackupFilesSha = Index(
    'idx_backup_files_sha',
    'CREATE INDEX idx_backup_files_sha ON backup_files (sha256)',
  );
  late final BackupFoldersDao backupFoldersDao = BackupFoldersDao(
    this as AppDatabase,
  );
  late final BackupFilesDao backupFilesDao = BackupFilesDao(
    this as AppDatabase,
  );
  late final FileVersionsDao fileVersionsDao = FileVersionsDao(
    this as AppDatabase,
  );
  late final BackupLogsDao backupLogsDao = BackupLogsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final SearchHistoriesDao searchHistoriesDao = SearchHistoriesDao(
    this as AppDatabase,
  );
  late final PairedDevicesDao pairedDevicesDao = PairedDevicesDao(
    this as AppDatabase,
  );
  late final BackupJobsDao backupJobsDao = BackupJobsDao(this as AppDatabase);
  late final FileTransfersDao fileTransfersDao = FileTransfersDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    backupFolders,
    backupFiles,
    fileVersions,
    backupLogs,
    settings,
    backupHistory,
    searchHistories,
    pairedDevices,
    backupJobs,
    fileTransfers,
    idxBackupFilesName,
    idxBackupFilesSha,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'backup_folders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('backup_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'backup_files',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('file_versions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'backup_folders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('backup_history', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BackupFoldersTableCreateCompanionBuilder =
    BackupFoldersCompanion Function({
      Value<int> id,
      required String name,
      required String sourcePath,
      required String destinationPath,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<String> backupInterval,
      Value<DateTime?> lastBackupAt,
      Value<DateTime?> nextBackupAt,
      Value<String?> destinationType,
      Value<String?> deviceUuid,
      Value<String?> deviceName,
      Value<String?> remoteFolderId,
      Value<String?> remoteFolderPath,
      Value<DateTime?> lastVerified,
    });
typedef $$BackupFoldersTableUpdateCompanionBuilder =
    BackupFoldersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> sourcePath,
      Value<String> destinationPath,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<String> backupInterval,
      Value<DateTime?> lastBackupAt,
      Value<DateTime?> nextBackupAt,
      Value<String?> destinationType,
      Value<String?> deviceUuid,
      Value<String?> deviceName,
      Value<String?> remoteFolderId,
      Value<String?> remoteFolderPath,
      Value<DateTime?> lastVerified,
    });

final class $$BackupFoldersTableReferences
    extends BaseReferences<_$AppDatabase, $BackupFoldersTable, BackupFolder> {
  $$BackupFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BackupFilesTable, List<BackupFile>>
  _backupFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.backupFiles,
    aliasName: 'backup_folders__id__backup_files__folder_id',
  );

  $$BackupFilesTableProcessedTableManager get backupFilesRefs {
    final manager = $$BackupFilesTableTableManager(
      $_db,
      $_db.backupFiles,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_backupFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BackupHistoryTable, List<BackupHistoryData>>
  _backupHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.backupHistory,
    aliasName: 'backup_folders__id__backup_history__folder_id',
  );

  $$BackupHistoryTableProcessedTableManager get backupHistoryRefs {
    final manager = $$BackupHistoryTableTableManager(
      $_db,
      $_db.backupHistory,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_backupHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BackupFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $BackupFoldersTable> {
  $$BackupFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationPath => $composableBuilder(
    column: $table.destinationPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupInterval => $composableBuilder(
    column: $table.backupInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextBackupAt => $composableBuilder(
    column: $table.nextBackupAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationType => $composableBuilder(
    column: $table.destinationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteFolderId => $composableBuilder(
    column: $table.remoteFolderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteFolderPath => $composableBuilder(
    column: $table.remoteFolderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVerified => $composableBuilder(
    column: $table.lastVerified,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> backupFilesRefs(
    Expression<bool> Function($$BackupFilesTableFilterComposer f) f,
  ) {
    final $$BackupFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupFiles,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFilesTableFilterComposer(
            $db: $db,
            $table: $db.backupFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> backupHistoryRefs(
    Expression<bool> Function($$BackupHistoryTableFilterComposer f) f,
  ) {
    final $$BackupHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupHistory,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupHistoryTableFilterComposer(
            $db: $db,
            $table: $db.backupHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BackupFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupFoldersTable> {
  $$BackupFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationPath => $composableBuilder(
    column: $table.destinationPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupInterval => $composableBuilder(
    column: $table.backupInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextBackupAt => $composableBuilder(
    column: $table.nextBackupAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationType => $composableBuilder(
    column: $table.destinationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteFolderId => $composableBuilder(
    column: $table.remoteFolderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteFolderPath => $composableBuilder(
    column: $table.remoteFolderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVerified => $composableBuilder(
    column: $table.lastVerified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupFoldersTable> {
  $$BackupFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationPath => $composableBuilder(
    column: $table.destinationPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get backupInterval => $composableBuilder(
    column: $table.backupInterval,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextBackupAt => $composableBuilder(
    column: $table.nextBackupAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationType => $composableBuilder(
    column: $table.destinationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteFolderId => $composableBuilder(
    column: $table.remoteFolderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteFolderPath => $composableBuilder(
    column: $table.remoteFolderPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastVerified => $composableBuilder(
    column: $table.lastVerified,
    builder: (column) => column,
  );

  Expression<T> backupFilesRefs<T extends Object>(
    Expression<T> Function($$BackupFilesTableAnnotationComposer a) f,
  ) {
    final $$BackupFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupFiles,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.backupFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> backupHistoryRefs<T extends Object>(
    Expression<T> Function($$BackupHistoryTableAnnotationComposer a) f,
  ) {
    final $$BackupHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupHistory,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.backupHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BackupFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupFoldersTable,
          BackupFolder,
          $$BackupFoldersTableFilterComposer,
          $$BackupFoldersTableOrderingComposer,
          $$BackupFoldersTableAnnotationComposer,
          $$BackupFoldersTableCreateCompanionBuilder,
          $$BackupFoldersTableUpdateCompanionBuilder,
          (BackupFolder, $$BackupFoldersTableReferences),
          BackupFolder,
          PrefetchHooks Function({bool backupFilesRefs, bool backupHistoryRefs})
        > {
  $$BackupFoldersTableTableManager(_$AppDatabase db, $BackupFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
                Value<String> destinationPath = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> backupInterval = const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
                Value<DateTime?> nextBackupAt = const Value.absent(),
                Value<String?> destinationType = const Value.absent(),
                Value<String?> deviceUuid = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> remoteFolderId = const Value.absent(),
                Value<String?> remoteFolderPath = const Value.absent(),
                Value<DateTime?> lastVerified = const Value.absent(),
              }) => BackupFoldersCompanion(
                id: id,
                name: name,
                sourcePath: sourcePath,
                destinationPath: destinationPath,
                enabled: enabled,
                createdAt: createdAt,
                backupInterval: backupInterval,
                lastBackupAt: lastBackupAt,
                nextBackupAt: nextBackupAt,
                destinationType: destinationType,
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                remoteFolderId: remoteFolderId,
                remoteFolderPath: remoteFolderPath,
                lastVerified: lastVerified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String sourcePath,
                required String destinationPath,
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> backupInterval = const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
                Value<DateTime?> nextBackupAt = const Value.absent(),
                Value<String?> destinationType = const Value.absent(),
                Value<String?> deviceUuid = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> remoteFolderId = const Value.absent(),
                Value<String?> remoteFolderPath = const Value.absent(),
                Value<DateTime?> lastVerified = const Value.absent(),
              }) => BackupFoldersCompanion.insert(
                id: id,
                name: name,
                sourcePath: sourcePath,
                destinationPath: destinationPath,
                enabled: enabled,
                createdAt: createdAt,
                backupInterval: backupInterval,
                lastBackupAt: lastBackupAt,
                nextBackupAt: nextBackupAt,
                destinationType: destinationType,
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                remoteFolderId: remoteFolderId,
                remoteFolderPath: remoteFolderPath,
                lastVerified: lastVerified,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BackupFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({backupFilesRefs = false, backupHistoryRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (backupFilesRefs) db.backupFiles,
                    if (backupHistoryRefs) db.backupHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (backupFilesRefs)
                        await $_getPrefetchedData<
                          BackupFolder,
                          $BackupFoldersTable,
                          BackupFile
                        >(
                          currentTable: table,
                          referencedTable: $$BackupFoldersTableReferences
                              ._backupFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BackupFoldersTableReferences(
                                db,
                                table,
                                p0,
                              ).backupFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (backupHistoryRefs)
                        await $_getPrefetchedData<
                          BackupFolder,
                          $BackupFoldersTable,
                          BackupHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$BackupFoldersTableReferences
                              ._backupHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BackupFoldersTableReferences(
                                db,
                                table,
                                p0,
                              ).backupHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BackupFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupFoldersTable,
      BackupFolder,
      $$BackupFoldersTableFilterComposer,
      $$BackupFoldersTableOrderingComposer,
      $$BackupFoldersTableAnnotationComposer,
      $$BackupFoldersTableCreateCompanionBuilder,
      $$BackupFoldersTableUpdateCompanionBuilder,
      (BackupFolder, $$BackupFoldersTableReferences),
      BackupFolder,
      PrefetchHooks Function({bool backupFilesRefs, bool backupHistoryRefs})
    >;
typedef $$BackupFilesTableCreateCompanionBuilder =
    BackupFilesCompanion Function({
      Value<int> id,
      required int folderId,
      required String fileName,
      required String extension,
      required String originalPath,
      required String backupPath,
      required int fileSize,
      required String sha256,
      Value<DateTime> createdAt,
      required DateTime modifiedAt,
      required String backupStatus,
    });
typedef $$BackupFilesTableUpdateCompanionBuilder =
    BackupFilesCompanion Function({
      Value<int> id,
      Value<int> folderId,
      Value<String> fileName,
      Value<String> extension,
      Value<String> originalPath,
      Value<String> backupPath,
      Value<int> fileSize,
      Value<String> sha256,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> backupStatus,
    });

final class $$BackupFilesTableReferences
    extends BaseReferences<_$AppDatabase, $BackupFilesTable, BackupFile> {
  $$BackupFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BackupFoldersTable _folderIdTable(_$AppDatabase db) => db
      .backupFolders
      .createAlias('backup_files__folder_id__backup_folders__id');

  $$BackupFoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<int>('folder_id')!;

    final manager = $$BackupFoldersTableTableManager(
      $_db,
      $_db.backupFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FileVersionsTable, List<FileVersion>>
  _fileVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fileVersions,
    aliasName: 'backup_files__id__file_versions__file_id',
  );

  $$FileVersionsTableProcessedTableManager get fileVersionsRefs {
    final manager = $$FileVersionsTableTableManager(
      $_db,
      $_db.fileVersions,
    ).filter((f) => f.fileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fileVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BackupFilesTableFilterComposer
    extends Composer<_$AppDatabase, $BackupFilesTable> {
  $$BackupFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupPath => $composableBuilder(
    column: $table.backupPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupStatus => $composableBuilder(
    column: $table.backupStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$BackupFoldersTableFilterComposer get folderId {
    final $$BackupFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.backupFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFoldersTableFilterComposer(
            $db: $db,
            $table: $db.backupFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> fileVersionsRefs(
    Expression<bool> Function($$FileVersionsTableFilterComposer f) f,
  ) {
    final $$FileVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileVersions,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileVersionsTableFilterComposer(
            $db: $db,
            $table: $db.fileVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BackupFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupFilesTable> {
  $$BackupFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupPath => $composableBuilder(
    column: $table.backupPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupStatus => $composableBuilder(
    column: $table.backupStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$BackupFoldersTableOrderingComposer get folderId {
    final $$BackupFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.backupFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.backupFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupFilesTable> {
  $$BackupFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get extension =>
      $composableBuilder(column: $table.extension, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupPath => $composableBuilder(
    column: $table.backupPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupStatus => $composableBuilder(
    column: $table.backupStatus,
    builder: (column) => column,
  );

  $$BackupFoldersTableAnnotationComposer get folderId {
    final $$BackupFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.backupFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.backupFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> fileVersionsRefs<T extends Object>(
    Expression<T> Function($$FileVersionsTableAnnotationComposer a) f,
  ) {
    final $$FileVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileVersions,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.fileVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BackupFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupFilesTable,
          BackupFile,
          $$BackupFilesTableFilterComposer,
          $$BackupFilesTableOrderingComposer,
          $$BackupFilesTableAnnotationComposer,
          $$BackupFilesTableCreateCompanionBuilder,
          $$BackupFilesTableUpdateCompanionBuilder,
          (BackupFile, $$BackupFilesTableReferences),
          BackupFile,
          PrefetchHooks Function({bool folderId, bool fileVersionsRefs})
        > {
  $$BackupFilesTableTableManager(_$AppDatabase db, $BackupFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> folderId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> extension = const Value.absent(),
                Value<String> originalPath = const Value.absent(),
                Value<String> backupPath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> backupStatus = const Value.absent(),
              }) => BackupFilesCompanion(
                id: id,
                folderId: folderId,
                fileName: fileName,
                extension: extension,
                originalPath: originalPath,
                backupPath: backupPath,
                fileSize: fileSize,
                sha256: sha256,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                backupStatus: backupStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int folderId,
                required String fileName,
                required String extension,
                required String originalPath,
                required String backupPath,
                required int fileSize,
                required String sha256,
                Value<DateTime> createdAt = const Value.absent(),
                required DateTime modifiedAt,
                required String backupStatus,
              }) => BackupFilesCompanion.insert(
                id: id,
                folderId: folderId,
                fileName: fileName,
                extension: extension,
                originalPath: originalPath,
                backupPath: backupPath,
                fileSize: fileSize,
                sha256: sha256,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                backupStatus: backupStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BackupFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({folderId = false, fileVersionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (fileVersionsRefs) db.fileVersions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable:
                                        $$BackupFilesTableReferences
                                            ._folderIdTable(db),
                                    referencedColumn:
                                        $$BackupFilesTableReferences
                                            ._folderIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (fileVersionsRefs)
                        await $_getPrefetchedData<
                          BackupFile,
                          $BackupFilesTable,
                          FileVersion
                        >(
                          currentTable: table,
                          referencedTable: $$BackupFilesTableReferences
                              ._fileVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BackupFilesTableReferences(
                                db,
                                table,
                                p0,
                              ).fileVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BackupFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupFilesTable,
      BackupFile,
      $$BackupFilesTableFilterComposer,
      $$BackupFilesTableOrderingComposer,
      $$BackupFilesTableAnnotationComposer,
      $$BackupFilesTableCreateCompanionBuilder,
      $$BackupFilesTableUpdateCompanionBuilder,
      (BackupFile, $$BackupFilesTableReferences),
      BackupFile,
      PrefetchHooks Function({bool folderId, bool fileVersionsRefs})
    >;
typedef $$FileVersionsTableCreateCompanionBuilder =
    FileVersionsCompanion Function({
      Value<int> id,
      required int fileId,
      required int versionNumber,
      required String backupPath,
      Value<DateTime> createdAt,
    });
typedef $$FileVersionsTableUpdateCompanionBuilder =
    FileVersionsCompanion Function({
      Value<int> id,
      Value<int> fileId,
      Value<int> versionNumber,
      Value<String> backupPath,
      Value<DateTime> createdAt,
    });

final class $$FileVersionsTableReferences
    extends BaseReferences<_$AppDatabase, $FileVersionsTable, FileVersion> {
  $$FileVersionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BackupFilesTable _fileIdTable(_$AppDatabase db) =>
      db.backupFiles.createAlias('file_versions__file_id__backup_files__id');

  $$BackupFilesTableProcessedTableManager get fileId {
    final $_column = $_itemColumn<int>('file_id')!;

    final manager = $$BackupFilesTableTableManager(
      $_db,
      $_db.backupFiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FileVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $FileVersionsTable> {
  $$FileVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupPath => $composableBuilder(
    column: $table.backupPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BackupFilesTableFilterComposer get fileId {
    final $$BackupFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.backupFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFilesTableFilterComposer(
            $db: $db,
            $table: $db.backupFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FileVersionsTable> {
  $$FileVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupPath => $composableBuilder(
    column: $table.backupPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BackupFilesTableOrderingComposer get fileId {
    final $$BackupFilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.backupFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFilesTableOrderingComposer(
            $db: $db,
            $table: $db.backupFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileVersionsTable> {
  $$FileVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupPath => $composableBuilder(
    column: $table.backupPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BackupFilesTableAnnotationComposer get fileId {
    final $$BackupFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.backupFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.backupFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileVersionsTable,
          FileVersion,
          $$FileVersionsTableFilterComposer,
          $$FileVersionsTableOrderingComposer,
          $$FileVersionsTableAnnotationComposer,
          $$FileVersionsTableCreateCompanionBuilder,
          $$FileVersionsTableUpdateCompanionBuilder,
          (FileVersion, $$FileVersionsTableReferences),
          FileVersion,
          PrefetchHooks Function({bool fileId})
        > {
  $$FileVersionsTableTableManager(_$AppDatabase db, $FileVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fileId = const Value.absent(),
                Value<int> versionNumber = const Value.absent(),
                Value<String> backupPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FileVersionsCompanion(
                id: id,
                fileId: fileId,
                versionNumber: versionNumber,
                backupPath: backupPath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fileId,
                required int versionNumber,
                required String backupPath,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FileVersionsCompanion.insert(
                id: id,
                fileId: fileId,
                versionNumber: versionNumber,
                backupPath: backupPath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FileVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fileId,
                                referencedTable: $$FileVersionsTableReferences
                                    ._fileIdTable(db),
                                referencedColumn: $$FileVersionsTableReferences
                                    ._fileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FileVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileVersionsTable,
      FileVersion,
      $$FileVersionsTableFilterComposer,
      $$FileVersionsTableOrderingComposer,
      $$FileVersionsTableAnnotationComposer,
      $$FileVersionsTableCreateCompanionBuilder,
      $$FileVersionsTableUpdateCompanionBuilder,
      (FileVersion, $$FileVersionsTableReferences),
      FileVersion,
      PrefetchHooks Function({bool fileId})
    >;
typedef $$BackupLogsTableCreateCompanionBuilder =
    BackupLogsCompanion Function({
      Value<int> id,
      required String logType,
      required String message,
      Value<DateTime> createdAt,
      Value<String?> tag,
      Value<String?> stackTrace,
    });
typedef $$BackupLogsTableUpdateCompanionBuilder =
    BackupLogsCompanion Function({
      Value<int> id,
      Value<String> logType,
      Value<String> message,
      Value<DateTime> createdAt,
      Value<String?> tag,
      Value<String?> stackTrace,
    });

class $$BackupLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupLogsTable> {
  $$BackupLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logType => $composableBuilder(
    column: $table.logType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BackupLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupLogsTable> {
  $$BackupLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logType => $composableBuilder(
    column: $table.logType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupLogsTable> {
  $$BackupLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get logType =>
      $composableBuilder(column: $table.logType, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => column,
  );
}

class $$BackupLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupLogsTable,
          BackupLog,
          $$BackupLogsTableFilterComposer,
          $$BackupLogsTableOrderingComposer,
          $$BackupLogsTableAnnotationComposer,
          $$BackupLogsTableCreateCompanionBuilder,
          $$BackupLogsTableUpdateCompanionBuilder,
          (
            BackupLog,
            BaseReferences<_$AppDatabase, $BackupLogsTable, BackupLog>,
          ),
          BackupLog,
          PrefetchHooks Function()
        > {
  $$BackupLogsTableTableManager(_$AppDatabase db, $BackupLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> logType = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> stackTrace = const Value.absent(),
              }) => BackupLogsCompanion(
                id: id,
                logType: logType,
                message: message,
                createdAt: createdAt,
                tag: tag,
                stackTrace: stackTrace,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String logType,
                required String message,
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> stackTrace = const Value.absent(),
              }) => BackupLogsCompanion.insert(
                id: id,
                logType: logType,
                message: message,
                createdAt: createdAt,
                tag: tag,
                stackTrace: stackTrace,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupLogsTable,
      BackupLog,
      $$BackupLogsTableFilterComposer,
      $$BackupLogsTableOrderingComposer,
      $$BackupLogsTableAnnotationComposer,
      $$BackupLogsTableCreateCompanionBuilder,
      $$BackupLogsTableUpdateCompanionBuilder,
      (BackupLog, BaseReferences<_$AppDatabase, $BackupLogsTable, BackupLog>),
      BackupLog,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<bool> autoStart,
      Value<bool> darkMode,
      Value<bool> notifications,
      Value<bool> verifyHash,
      Value<bool> versioningEnabled,
      Value<String> backupMode,
      Value<String> language,
      Value<String> defaultDestinationPath,
      Value<String> themeMode,
      Value<bool> autoBackupEnabled,
      Value<String> backupInterval,
      Value<bool> notifyOnSuccess,
      Value<bool> notifyOnFailure,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<bool> autoStart,
      Value<bool> darkMode,
      Value<bool> notifications,
      Value<bool> verifyHash,
      Value<bool> versioningEnabled,
      Value<String> backupMode,
      Value<String> language,
      Value<String> defaultDestinationPath,
      Value<String> themeMode,
      Value<bool> autoBackupEnabled,
      Value<String> backupInterval,
      Value<bool> notifyOnSuccess,
      Value<bool> notifyOnFailure,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoStart => $composableBuilder(
    column: $table.autoStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get darkMode => $composableBuilder(
    column: $table.darkMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifications => $composableBuilder(
    column: $table.notifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get verifyHash => $composableBuilder(
    column: $table.verifyHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get versioningEnabled => $composableBuilder(
    column: $table.versioningEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupMode => $composableBuilder(
    column: $table.backupMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultDestinationPath => $composableBuilder(
    column: $table.defaultDestinationPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoBackupEnabled => $composableBuilder(
    column: $table.autoBackupEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupInterval => $composableBuilder(
    column: $table.backupInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyOnSuccess => $composableBuilder(
    column: $table.notifyOnSuccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyOnFailure => $composableBuilder(
    column: $table.notifyOnFailure,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoStart => $composableBuilder(
    column: $table.autoStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get darkMode => $composableBuilder(
    column: $table.darkMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifications => $composableBuilder(
    column: $table.notifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get verifyHash => $composableBuilder(
    column: $table.verifyHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get versioningEnabled => $composableBuilder(
    column: $table.versioningEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupMode => $composableBuilder(
    column: $table.backupMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultDestinationPath => $composableBuilder(
    column: $table.defaultDestinationPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoBackupEnabled => $composableBuilder(
    column: $table.autoBackupEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupInterval => $composableBuilder(
    column: $table.backupInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyOnSuccess => $composableBuilder(
    column: $table.notifyOnSuccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyOnFailure => $composableBuilder(
    column: $table.notifyOnFailure,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get autoStart =>
      $composableBuilder(column: $table.autoStart, builder: (column) => column);

  GeneratedColumn<bool> get darkMode =>
      $composableBuilder(column: $table.darkMode, builder: (column) => column);

  GeneratedColumn<bool> get notifications => $composableBuilder(
    column: $table.notifications,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get verifyHash => $composableBuilder(
    column: $table.verifyHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get versioningEnabled => $composableBuilder(
    column: $table.versioningEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupMode => $composableBuilder(
    column: $table.backupMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get defaultDestinationPath => $composableBuilder(
    column: $table.defaultDestinationPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get autoBackupEnabled => $composableBuilder(
    column: $table.autoBackupEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupInterval => $composableBuilder(
    column: $table.backupInterval,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyOnSuccess => $composableBuilder(
    column: $table.notifyOnSuccess,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyOnFailure => $composableBuilder(
    column: $table.notifyOnFailure,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> autoStart = const Value.absent(),
                Value<bool> darkMode = const Value.absent(),
                Value<bool> notifications = const Value.absent(),
                Value<bool> verifyHash = const Value.absent(),
                Value<bool> versioningEnabled = const Value.absent(),
                Value<String> backupMode = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> defaultDestinationPath = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> autoBackupEnabled = const Value.absent(),
                Value<String> backupInterval = const Value.absent(),
                Value<bool> notifyOnSuccess = const Value.absent(),
                Value<bool> notifyOnFailure = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                autoStart: autoStart,
                darkMode: darkMode,
                notifications: notifications,
                verifyHash: verifyHash,
                versioningEnabled: versioningEnabled,
                backupMode: backupMode,
                language: language,
                defaultDestinationPath: defaultDestinationPath,
                themeMode: themeMode,
                autoBackupEnabled: autoBackupEnabled,
                backupInterval: backupInterval,
                notifyOnSuccess: notifyOnSuccess,
                notifyOnFailure: notifyOnFailure,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> autoStart = const Value.absent(),
                Value<bool> darkMode = const Value.absent(),
                Value<bool> notifications = const Value.absent(),
                Value<bool> verifyHash = const Value.absent(),
                Value<bool> versioningEnabled = const Value.absent(),
                Value<String> backupMode = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> defaultDestinationPath = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> autoBackupEnabled = const Value.absent(),
                Value<String> backupInterval = const Value.absent(),
                Value<bool> notifyOnSuccess = const Value.absent(),
                Value<bool> notifyOnFailure = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                autoStart: autoStart,
                darkMode: darkMode,
                notifications: notifications,
                verifyHash: verifyHash,
                versioningEnabled: versioningEnabled,
                backupMode: backupMode,
                language: language,
                defaultDestinationPath: defaultDestinationPath,
                themeMode: themeMode,
                autoBackupEnabled: autoBackupEnabled,
                backupInterval: backupInterval,
                notifyOnSuccess: notifyOnSuccess,
                notifyOnFailure: notifyOnFailure,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$BackupHistoryTableCreateCompanionBuilder =
    BackupHistoryCompanion Function({
      Value<int> id,
      Value<int?> folderId,
      Value<DateTime> timestamp,
      required String status,
      required String message,
      Value<int> filesCount,
      Value<int> totalSize,
      Value<String> backupType,
    });
typedef $$BackupHistoryTableUpdateCompanionBuilder =
    BackupHistoryCompanion Function({
      Value<int> id,
      Value<int?> folderId,
      Value<DateTime> timestamp,
      Value<String> status,
      Value<String> message,
      Value<int> filesCount,
      Value<int> totalSize,
      Value<String> backupType,
    });

final class $$BackupHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $BackupHistoryTable, BackupHistoryData> {
  $$BackupHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BackupFoldersTable _folderIdTable(_$AppDatabase db) => db
      .backupFolders
      .createAlias('backup_history__folder_id__backup_folders__id');

  $$BackupFoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<int>('folder_id');
    if ($_column == null) return null;
    final manager = $$BackupFoldersTableTableManager(
      $_db,
      $_db.backupFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BackupHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get filesCount => $composableBuilder(
    column: $table.filesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupType => $composableBuilder(
    column: $table.backupType,
    builder: (column) => ColumnFilters(column),
  );

  $$BackupFoldersTableFilterComposer get folderId {
    final $$BackupFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.backupFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFoldersTableFilterComposer(
            $db: $db,
            $table: $db.backupFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get filesCount => $composableBuilder(
    column: $table.filesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupType => $composableBuilder(
    column: $table.backupType,
    builder: (column) => ColumnOrderings(column),
  );

  $$BackupFoldersTableOrderingComposer get folderId {
    final $$BackupFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.backupFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.backupFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get filesCount => $composableBuilder(
    column: $table.filesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSize =>
      $composableBuilder(column: $table.totalSize, builder: (column) => column);

  GeneratedColumn<String> get backupType => $composableBuilder(
    column: $table.backupType,
    builder: (column) => column,
  );

  $$BackupFoldersTableAnnotationComposer get folderId {
    final $$BackupFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.backupFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.backupFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupHistoryTable,
          BackupHistoryData,
          $$BackupHistoryTableFilterComposer,
          $$BackupHistoryTableOrderingComposer,
          $$BackupHistoryTableAnnotationComposer,
          $$BackupHistoryTableCreateCompanionBuilder,
          $$BackupHistoryTableUpdateCompanionBuilder,
          (BackupHistoryData, $$BackupHistoryTableReferences),
          BackupHistoryData,
          PrefetchHooks Function({bool folderId})
        > {
  $$BackupHistoryTableTableManager(_$AppDatabase db, $BackupHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int> filesCount = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<String> backupType = const Value.absent(),
              }) => BackupHistoryCompanion(
                id: id,
                folderId: folderId,
                timestamp: timestamp,
                status: status,
                message: message,
                filesCount: filesCount,
                totalSize: totalSize,
                backupType: backupType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required String status,
                required String message,
                Value<int> filesCount = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<String> backupType = const Value.absent(),
              }) => BackupHistoryCompanion.insert(
                id: id,
                folderId: folderId,
                timestamp: timestamp,
                status: status,
                message: message,
                filesCount: filesCount,
                totalSize: totalSize,
                backupType: backupType,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BackupHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({folderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (folderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.folderId,
                                referencedTable: $$BackupHistoryTableReferences
                                    ._folderIdTable(db),
                                referencedColumn: $$BackupHistoryTableReferences
                                    ._folderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BackupHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupHistoryTable,
      BackupHistoryData,
      $$BackupHistoryTableFilterComposer,
      $$BackupHistoryTableOrderingComposer,
      $$BackupHistoryTableAnnotationComposer,
      $$BackupHistoryTableCreateCompanionBuilder,
      $$BackupHistoryTableUpdateCompanionBuilder,
      (BackupHistoryData, $$BackupHistoryTableReferences),
      BackupHistoryData,
      PrefetchHooks Function({bool folderId})
    >;
typedef $$SearchHistoriesTableCreateCompanionBuilder =
    SearchHistoriesCompanion Function({
      Value<int> id,
      required String query,
      Value<DateTime> createdAt,
      Value<bool> pinned,
    });
typedef $$SearchHistoriesTableUpdateCompanionBuilder =
    SearchHistoriesCompanion Function({
      Value<int> id,
      Value<String> query,
      Value<DateTime> createdAt,
      Value<bool> pinned,
    });

class $$SearchHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);
}

class $$SearchHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoriesTable,
          SearchHistory,
          $$SearchHistoriesTableFilterComposer,
          $$SearchHistoriesTableOrderingComposer,
          $$SearchHistoriesTableAnnotationComposer,
          $$SearchHistoriesTableCreateCompanionBuilder,
          $$SearchHistoriesTableUpdateCompanionBuilder,
          (
            SearchHistory,
            BaseReferences<_$AppDatabase, $SearchHistoriesTable, SearchHistory>,
          ),
          SearchHistory,
          PrefetchHooks Function()
        > {
  $$SearchHistoriesTableTableManager(
    _$AppDatabase db,
    $SearchHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
              }) => SearchHistoriesCompanion(
                id: id,
                query: query,
                createdAt: createdAt,
                pinned: pinned,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String query,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
              }) => SearchHistoriesCompanion.insert(
                id: id,
                query: query,
                createdAt: createdAt,
                pinned: pinned,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoriesTable,
      SearchHistory,
      $$SearchHistoriesTableFilterComposer,
      $$SearchHistoriesTableOrderingComposer,
      $$SearchHistoriesTableAnnotationComposer,
      $$SearchHistoriesTableCreateCompanionBuilder,
      $$SearchHistoriesTableUpdateCompanionBuilder,
      (
        SearchHistory,
        BaseReferences<_$AppDatabase, $SearchHistoriesTable, SearchHistory>,
      ),
      SearchHistory,
      PrefetchHooks Function()
    >;
typedef $$PairedDevicesTableCreateCompanionBuilder =
    PairedDevicesCompanion Function({
      required String deviceUuid,
      required String deviceName,
      required String platform,
      required String osVersion,
      required String appVersion,
      required String deviceModel,
      Value<DateTime> createdAt,
      Value<DateTime> lastSeen,
      required String status,
      Value<int> rowid,
    });
typedef $$PairedDevicesTableUpdateCompanionBuilder =
    PairedDevicesCompanion Function({
      Value<String> deviceUuid,
      Value<String> deviceName,
      Value<String> platform,
      Value<String> osVersion,
      Value<String> appVersion,
      Value<String> deviceModel,
      Value<DateTime> createdAt,
      Value<DateTime> lastSeen,
      Value<String> status,
      Value<int> rowid,
    });

class $$PairedDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osVersion => $composableBuilder(
    column: $table.osVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PairedDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osVersion => $composableBuilder(
    column: $table.osVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PairedDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PairedDevicesTable> {
  $$PairedDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get osVersion =>
      $composableBuilder(column: $table.osVersion, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$PairedDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PairedDevicesTable,
          PairedDevice,
          $$PairedDevicesTableFilterComposer,
          $$PairedDevicesTableOrderingComposer,
          $$PairedDevicesTableAnnotationComposer,
          $$PairedDevicesTableCreateCompanionBuilder,
          $$PairedDevicesTableUpdateCompanionBuilder,
          (
            PairedDevice,
            BaseReferences<_$AppDatabase, $PairedDevicesTable, PairedDevice>,
          ),
          PairedDevice,
          PrefetchHooks Function()
        > {
  $$PairedDevicesTableTableManager(_$AppDatabase db, $PairedDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PairedDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PairedDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PairedDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceUuid = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> osVersion = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String> deviceModel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesCompanion(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                platform: platform,
                osVersion: osVersion,
                appVersion: appVersion,
                deviceModel: deviceModel,
                createdAt: createdAt,
                lastSeen: lastSeen,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceUuid,
                required String deviceName,
                required String platform,
                required String osVersion,
                required String appVersion,
                required String deviceModel,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesCompanion.insert(
                deviceUuid: deviceUuid,
                deviceName: deviceName,
                platform: platform,
                osVersion: osVersion,
                appVersion: appVersion,
                deviceModel: deviceModel,
                createdAt: createdAt,
                lastSeen: lastSeen,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PairedDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PairedDevicesTable,
      PairedDevice,
      $$PairedDevicesTableFilterComposer,
      $$PairedDevicesTableOrderingComposer,
      $$PairedDevicesTableAnnotationComposer,
      $$PairedDevicesTableCreateCompanionBuilder,
      $$PairedDevicesTableUpdateCompanionBuilder,
      (
        PairedDevice,
        BaseReferences<_$AppDatabase, $PairedDevicesTable, PairedDevice>,
      ),
      PairedDevice,
      PrefetchHooks Function()
    >;
typedef $$BackupJobsTableCreateCompanionBuilder =
    BackupJobsCompanion Function({
      required String id,
      Value<String?> deviceUuid,
      Value<String?> folderUuid,
      required int folderId,
      Value<String?> destinationUuid,
      required DateTime createdAt,
      Value<DateTime?> startedTime,
      Value<DateTime?> completedTime,
      required String status,
      required double progress,
      Value<int> totalFiles,
      Value<int> totalSize,
      Value<int> filesToBackup,
      Value<int> skippedFiles,
      Value<String?> error,
      Value<int> rowid,
    });
typedef $$BackupJobsTableUpdateCompanionBuilder =
    BackupJobsCompanion Function({
      Value<String> id,
      Value<String?> deviceUuid,
      Value<String?> folderUuid,
      Value<int> folderId,
      Value<String?> destinationUuid,
      Value<DateTime> createdAt,
      Value<DateTime?> startedTime,
      Value<DateTime?> completedTime,
      Value<String> status,
      Value<double> progress,
      Value<int> totalFiles,
      Value<int> totalSize,
      Value<int> filesToBackup,
      Value<int> skippedFiles,
      Value<String?> error,
      Value<int> rowid,
    });

class $$BackupJobsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupJobsTable> {
  $$BackupJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderUuid => $composableBuilder(
    column: $table.folderUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationUuid => $composableBuilder(
    column: $table.destinationUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedTime => $composableBuilder(
    column: $table.startedTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedTime => $composableBuilder(
    column: $table.completedTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFiles => $composableBuilder(
    column: $table.totalFiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get filesToBackup => $composableBuilder(
    column: $table.filesToBackup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedFiles => $composableBuilder(
    column: $table.skippedFiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BackupJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupJobsTable> {
  $$BackupJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderUuid => $composableBuilder(
    column: $table.folderUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationUuid => $composableBuilder(
    column: $table.destinationUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedTime => $composableBuilder(
    column: $table.startedTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedTime => $composableBuilder(
    column: $table.completedTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFiles => $composableBuilder(
    column: $table.totalFiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get filesToBackup => $composableBuilder(
    column: $table.filesToBackup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedFiles => $composableBuilder(
    column: $table.skippedFiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupJobsTable> {
  $$BackupJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderUuid => $composableBuilder(
    column: $table.folderUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get destinationUuid => $composableBuilder(
    column: $table.destinationUuid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedTime => $composableBuilder(
    column: $table.startedTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedTime => $composableBuilder(
    column: $table.completedTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get totalFiles => $composableBuilder(
    column: $table.totalFiles,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSize =>
      $composableBuilder(column: $table.totalSize, builder: (column) => column);

  GeneratedColumn<int> get filesToBackup => $composableBuilder(
    column: $table.filesToBackup,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedFiles => $composableBuilder(
    column: $table.skippedFiles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$BackupJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupJobsTable,
          BackupJob,
          $$BackupJobsTableFilterComposer,
          $$BackupJobsTableOrderingComposer,
          $$BackupJobsTableAnnotationComposer,
          $$BackupJobsTableCreateCompanionBuilder,
          $$BackupJobsTableUpdateCompanionBuilder,
          (
            BackupJob,
            BaseReferences<_$AppDatabase, $BackupJobsTable, BackupJob>,
          ),
          BackupJob,
          PrefetchHooks Function()
        > {
  $$BackupJobsTableTableManager(_$AppDatabase db, $BackupJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> deviceUuid = const Value.absent(),
                Value<String?> folderUuid = const Value.absent(),
                Value<int> folderId = const Value.absent(),
                Value<String?> destinationUuid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedTime = const Value.absent(),
                Value<DateTime?> completedTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> totalFiles = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<int> filesToBackup = const Value.absent(),
                Value<int> skippedFiles = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupJobsCompanion(
                id: id,
                deviceUuid: deviceUuid,
                folderUuid: folderUuid,
                folderId: folderId,
                destinationUuid: destinationUuid,
                createdAt: createdAt,
                startedTime: startedTime,
                completedTime: completedTime,
                status: status,
                progress: progress,
                totalFiles: totalFiles,
                totalSize: totalSize,
                filesToBackup: filesToBackup,
                skippedFiles: skippedFiles,
                error: error,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> deviceUuid = const Value.absent(),
                Value<String?> folderUuid = const Value.absent(),
                required int folderId,
                Value<String?> destinationUuid = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> startedTime = const Value.absent(),
                Value<DateTime?> completedTime = const Value.absent(),
                required String status,
                required double progress,
                Value<int> totalFiles = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<int> filesToBackup = const Value.absent(),
                Value<int> skippedFiles = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupJobsCompanion.insert(
                id: id,
                deviceUuid: deviceUuid,
                folderUuid: folderUuid,
                folderId: folderId,
                destinationUuid: destinationUuid,
                createdAt: createdAt,
                startedTime: startedTime,
                completedTime: completedTime,
                status: status,
                progress: progress,
                totalFiles: totalFiles,
                totalSize: totalSize,
                filesToBackup: filesToBackup,
                skippedFiles: skippedFiles,
                error: error,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupJobsTable,
      BackupJob,
      $$BackupJobsTableFilterComposer,
      $$BackupJobsTableOrderingComposer,
      $$BackupJobsTableAnnotationComposer,
      $$BackupJobsTableCreateCompanionBuilder,
      $$BackupJobsTableUpdateCompanionBuilder,
      (BackupJob, BaseReferences<_$AppDatabase, $BackupJobsTable, BackupJob>),
      BackupJob,
      PrefetchHooks Function()
    >;
typedef $$FileTransfersTableCreateCompanionBuilder =
    FileTransfersCompanion Function({
      required String id,
      required String sessionId,
      required String fileName,
      required String relativePath,
      required int fileSize,
      Value<String?> hash,
      required String status,
      required int transferredBytes,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$FileTransfersTableUpdateCompanionBuilder =
    FileTransfersCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> fileName,
      Value<String> relativePath,
      Value<int> fileSize,
      Value<String?> hash,
      Value<String> status,
      Value<int> transferredBytes,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$FileTransfersTableFilterComposer
    extends Composer<_$AppDatabase, $FileTransfersTable> {
  $$FileTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transferredBytes => $composableBuilder(
    column: $table.transferredBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FileTransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $FileTransfersTable> {
  $$FileTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transferredBytes => $composableBuilder(
    column: $table.transferredBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FileTransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileTransfersTable> {
  $$FileTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get transferredBytes => $composableBuilder(
    column: $table.transferredBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$FileTransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileTransfersTable,
          FileTransfer,
          $$FileTransfersTableFilterComposer,
          $$FileTransfersTableOrderingComposer,
          $$FileTransfersTableAnnotationComposer,
          $$FileTransfersTableCreateCompanionBuilder,
          $$FileTransfersTableUpdateCompanionBuilder,
          (
            FileTransfer,
            BaseReferences<_$AppDatabase, $FileTransfersTable, FileTransfer>,
          ),
          FileTransfer,
          PrefetchHooks Function()
        > {
  $$FileTransfersTableTableManager(_$AppDatabase db, $FileTransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileTransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> transferredBytes = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileTransfersCompanion(
                id: id,
                sessionId: sessionId,
                fileName: fileName,
                relativePath: relativePath,
                fileSize: fileSize,
                hash: hash,
                status: status,
                transferredBytes: transferredBytes,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String fileName,
                required String relativePath,
                required int fileSize,
                Value<String?> hash = const Value.absent(),
                required String status,
                required int transferredBytes,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileTransfersCompanion.insert(
                id: id,
                sessionId: sessionId,
                fileName: fileName,
                relativePath: relativePath,
                fileSize: fileSize,
                hash: hash,
                status: status,
                transferredBytes: transferredBytes,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FileTransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileTransfersTable,
      FileTransfer,
      $$FileTransfersTableFilterComposer,
      $$FileTransfersTableOrderingComposer,
      $$FileTransfersTableAnnotationComposer,
      $$FileTransfersTableCreateCompanionBuilder,
      $$FileTransfersTableUpdateCompanionBuilder,
      (
        FileTransfer,
        BaseReferences<_$AppDatabase, $FileTransfersTable, FileTransfer>,
      ),
      FileTransfer,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BackupFoldersTableTableManager get backupFolders =>
      $$BackupFoldersTableTableManager(_db, _db.backupFolders);
  $$BackupFilesTableTableManager get backupFiles =>
      $$BackupFilesTableTableManager(_db, _db.backupFiles);
  $$FileVersionsTableTableManager get fileVersions =>
      $$FileVersionsTableTableManager(_db, _db.fileVersions);
  $$BackupLogsTableTableManager get backupLogs =>
      $$BackupLogsTableTableManager(_db, _db.backupLogs);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$BackupHistoryTableTableManager get backupHistory =>
      $$BackupHistoryTableTableManager(_db, _db.backupHistory);
  $$SearchHistoriesTableTableManager get searchHistories =>
      $$SearchHistoriesTableTableManager(_db, _db.searchHistories);
  $$PairedDevicesTableTableManager get pairedDevices =>
      $$PairedDevicesTableTableManager(_db, _db.pairedDevices);
  $$BackupJobsTableTableManager get backupJobs =>
      $$BackupJobsTableTableManager(_db, _db.backupJobs);
  $$FileTransfersTableTableManager get fileTransfers =>
      $$FileTransfersTableTableManager(_db, _db.fileTransfers);
}

mixin _$BackupFoldersDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupFoldersTable get backupFolders => attachedDatabase.backupFolders;
  BackupFoldersDaoManager get managers => BackupFoldersDaoManager(this);
}

class BackupFoldersDaoManager {
  final _$BackupFoldersDaoMixin _db;
  BackupFoldersDaoManager(this._db);
  $$BackupFoldersTableTableManager get backupFolders =>
      $$BackupFoldersTableTableManager(_db.attachedDatabase, _db.backupFolders);
}

mixin _$BackupFilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupFoldersTable get backupFolders => attachedDatabase.backupFolders;
  $BackupFilesTable get backupFiles => attachedDatabase.backupFiles;
  BackupFilesDaoManager get managers => BackupFilesDaoManager(this);
}

class BackupFilesDaoManager {
  final _$BackupFilesDaoMixin _db;
  BackupFilesDaoManager(this._db);
  $$BackupFoldersTableTableManager get backupFolders =>
      $$BackupFoldersTableTableManager(_db.attachedDatabase, _db.backupFolders);
  $$BackupFilesTableTableManager get backupFiles =>
      $$BackupFilesTableTableManager(_db.attachedDatabase, _db.backupFiles);
}

mixin _$FileVersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupFoldersTable get backupFolders => attachedDatabase.backupFolders;
  $BackupFilesTable get backupFiles => attachedDatabase.backupFiles;
  $FileVersionsTable get fileVersions => attachedDatabase.fileVersions;
  FileVersionsDaoManager get managers => FileVersionsDaoManager(this);
}

class FileVersionsDaoManager {
  final _$FileVersionsDaoMixin _db;
  FileVersionsDaoManager(this._db);
  $$BackupFoldersTableTableManager get backupFolders =>
      $$BackupFoldersTableTableManager(_db.attachedDatabase, _db.backupFolders);
  $$BackupFilesTableTableManager get backupFiles =>
      $$BackupFilesTableTableManager(_db.attachedDatabase, _db.backupFiles);
  $$FileVersionsTableTableManager get fileVersions =>
      $$FileVersionsTableTableManager(_db.attachedDatabase, _db.fileVersions);
}

mixin _$BackupLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupLogsTable get backupLogs => attachedDatabase.backupLogs;
  BackupLogsDaoManager get managers => BackupLogsDaoManager(this);
}

class BackupLogsDaoManager {
  final _$BackupLogsDaoMixin _db;
  BackupLogsDaoManager(this._db);
  $$BackupLogsTableTableManager get backupLogs =>
      $$BackupLogsTableTableManager(_db.attachedDatabase, _db.backupLogs);
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db.attachedDatabase, _db.settings);
}

mixin _$SearchHistoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SearchHistoriesTable get searchHistories => attachedDatabase.searchHistories;
  SearchHistoriesDaoManager get managers => SearchHistoriesDaoManager(this);
}

class SearchHistoriesDaoManager {
  final _$SearchHistoriesDaoMixin _db;
  SearchHistoriesDaoManager(this._db);
  $$SearchHistoriesTableTableManager get searchHistories =>
      $$SearchHistoriesTableTableManager(
        _db.attachedDatabase,
        _db.searchHistories,
      );
}

mixin _$PairedDevicesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PairedDevicesTable get pairedDevices => attachedDatabase.pairedDevices;
  PairedDevicesDaoManager get managers => PairedDevicesDaoManager(this);
}

class PairedDevicesDaoManager {
  final _$PairedDevicesDaoMixin _db;
  PairedDevicesDaoManager(this._db);
  $$PairedDevicesTableTableManager get pairedDevices =>
      $$PairedDevicesTableTableManager(_db.attachedDatabase, _db.pairedDevices);
}

mixin _$BackupJobsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupJobsTable get backupJobs => attachedDatabase.backupJobs;
  BackupJobsDaoManager get managers => BackupJobsDaoManager(this);
}

class BackupJobsDaoManager {
  final _$BackupJobsDaoMixin _db;
  BackupJobsDaoManager(this._db);
  $$BackupJobsTableTableManager get backupJobs =>
      $$BackupJobsTableTableManager(_db.attachedDatabase, _db.backupJobs);
}

mixin _$FileTransfersDaoMixin on DatabaseAccessor<AppDatabase> {
  $FileTransfersTable get fileTransfers => attachedDatabase.fileTransfers;
  FileTransfersDaoManager get managers => FileTransfersDaoManager(this);
}

class FileTransfersDaoManager {
  final _$FileTransfersDaoMixin _db;
  FileTransfersDaoManager(this._db);
  $$FileTransfersTableTableManager get fileTransfers =>
      $$FileTransfersTableTableManager(_db.attachedDatabase, _db.fileTransfers);
}
