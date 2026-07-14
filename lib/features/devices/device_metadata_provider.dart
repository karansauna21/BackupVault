import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_model.dart';
import '../../shared/providers/device_provider.dart';
import '../folder_manager/folder_manager_provider.dart';
import 'device_metadata_models.dart';

class DeviceMetadataState {
  final List<DeviceFolderMetadata> folders;
  final List<DeviceFileMetadata> files;
  final bool isFolderSyncing;
  final bool isFileSyncing;
  final bool isReconnecting;
  final Map<String, dynamic> extraDeviceInfo;
  final String deviceId;

  DeviceMetadataState({
    required this.folders,
    required this.files,
    this.isFolderSyncing = false,
    this.isFileSyncing = false,
    this.isReconnecting = false,
    required this.extraDeviceInfo,
    this.deviceId = '',
  });

  DeviceMetadataState copyWith({
    List<DeviceFolderMetadata>? folders,
    List<DeviceFileMetadata>? files,
    bool? isFolderSyncing,
    bool? isFileSyncing,
    bool? isReconnecting,
    Map<String, dynamic>? extraDeviceInfo,
    String? deviceId,
  }) {
    return DeviceMetadataState(
      folders: folders ?? this.folders,
      files: files ?? this.files,
      isFolderSyncing: isFolderSyncing ?? this.isFolderSyncing,
      isFileSyncing: isFileSyncing ?? this.isFileSyncing,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      extraDeviceInfo: extraDeviceInfo ?? this.extraDeviceInfo,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class DeviceMetadataNotifier extends Notifier<DeviceMetadataState> {
  DeviceModel? _device;

  @override
  DeviceMetadataState build() {
    return DeviceMetadataState(
      folders: [],
      files: [],
      extraDeviceInfo: {},
      deviceId: '',
    );
  }

  void initialize(DeviceModel device) {
    if (_device?.id == device.id && state.deviceId == device.id) return;
    _device = device;
    
    // Generate initial extra info
    final isAndroid = device.platform.toLowerCase().contains('android');
    final isWindows = device.platform.toLowerCase().contains('windows');
    
    final extra = {
      'batteryPercentage': isAndroid ? 78 : 100,
      'chargingStatus': isAndroid ? 'Charging' : 'Plugged In',
      'ramTotal': isAndroid ? '8 GB' : '16 GB',
      'ramUsed': isAndroid ? '4.2 GB' : '9.1 GB',
      'ramFree': isAndroid ? '3.8 GB' : '6.9 GB',
      'storageTotal': '256 GB',
      'storageUsed': '180 GB',
      'storageFree': '76 GB',
      'cpuArchitecture': isWindows ? 'x86_64 (Intel Core i7)' : 'ARM64 (Snapdragon 8 Gen 2)',
      'wifiSsid': 'Home_5G_Network',
      'connectionType': 'Wi-Fi 6',
      'signalStrength': 'Excellent (-42 dBm)',
    };

    // Load folders from folderManagerProvider
    List<DeviceFolderMetadata> folderList = [];
    List<DeviceFileMetadata> fileList = [];

    final localFoldersVal = ref.read(folderManagerProvider);
    final localFolders = localFoldersVal.value ?? [];

    if (localFolders.isNotEmpty) {
      for (final lf in localFolders) {
        final totalFiles = 25 + Random().nextInt(100);
        final folderSize = (50 + Random().nextInt(400)) * 1024 * 1024; // in MB
        final statusList = ['Synced', 'Pending', 'Missing', 'Not Backed Up'];
        final syncStatus = statusList[Random().nextInt(statusList.length)];
        
        folderList.add(DeviceFolderMetadata(
          folderName: lf.name,
          folderPath: lf.sourcePath,
          folderType: 'Sync & Backup',
          totalFiles: totalFiles,
          folderSize: folderSize,
          lastModified: DateTime.now().subtract(Duration(hours: Random().nextInt(72))),
          syncStatus: syncStatus,
          localDetails: 'Local Path: ${lf.sourcePath}\nFiles: $totalFiles\nSize: ${(folderSize / (1024 * 1024)).toStringAsFixed(1)} MB',
          remoteDetails: 'Remote Path: ${device.name}/${lf.name}\nFiles: ${syncStatus == 'Missing' ? 0 : totalFiles}\nSize: ${syncStatus == 'Missing' ? '0' : (folderSize / (1024 * 1024)).toStringAsFixed(1)} MB',
        ));

        // Generate files
        final extensions = ['pdf', 'png', 'txt', 'docx', 'jpg'];
        for (int i = 0; i < 5; i++) {
          final ext = extensions[i % extensions.length];
          final filename = 'file_${lf.name.toLowerCase().replaceAll(' ', '_')}_$i.$ext';
          final fileSize = (1 + Random().nextInt(20)) * 1024 * 1024; // MB
          final hash = _generateMockHash(filename);
          final statuses = ['Already Synced', 'New File', 'Modified', 'Missing', 'Skipped'];
          
          fileList.add(DeviceFileMetadata(
            filename: filename,
            extension: ext,
            relativePath: '${lf.name}/$filename',
            fileSize: fileSize,
            sha256: hash,
            modifiedDate: DateTime.now().subtract(Duration(days: Random().nextInt(10))),
            createdDate: DateTime.now().subtract(Duration(days: Random().nextInt(20) + 10)),
            version: 1 + Random().nextInt(3),
            backupStatus: statuses[i % statuses.length],
          ));
        }
      }
    } else {
      // Fallback fallback folders
      folderList = [
        DeviceFolderMetadata(
          folderName: 'Documents Sync',
          folderPath: isAndroid ? '/storage/emulated/0/Documents' : 'C:\\Users\\User\\Documents',
          folderType: 'Sync',
          totalFiles: 142,
          folderSize: 154800000,
          lastModified: DateTime.now().subtract(const Duration(hours: 4)),
          syncStatus: 'Synced',
          localDetails: 'Local: 142 files, 147.6 MB',
          remoteDetails: 'Remote: 142 files, 147.6 MB',
        ),
        DeviceFolderMetadata(
          folderName: 'Photos Backup',
          folderPath: isAndroid ? '/storage/emulated/0/DCIM/Camera' : 'C:\\Users\\User\\Pictures',
          folderType: 'Backup',
          totalFiles: 420,
          folderSize: 2254000000,
          lastModified: DateTime.now().subtract(const Duration(hours: 12)),
          syncStatus: 'Pending',
          localDetails: 'Local: 420 files, 2.1 GB',
          remoteDetails: 'Remote: 398 files, 1.9 GB (22 files pending)',
        ),
        DeviceFolderMetadata(
          folderName: 'Projects Archive',
          folderPath: isAndroid ? '/storage/emulated/0/Projects' : 'C:\\Users\\User\\Projects',
          folderType: 'Archive',
          totalFiles: 89,
          folderSize: 188743680,
          lastModified: DateTime.now().subtract(const Duration(days: 3)),
          syncStatus: 'Missing',
          localDetails: 'Local: 89 files, 180 MB',
          remoteDetails: 'Remote: 0 files (Not found on remote)',
        ),
      ];

      fileList = [
        DeviceFileMetadata(
          filename: 'resume_july.pdf',
          extension: 'pdf',
          relativePath: 'Documents/resume_july.pdf',
          fileSize: 245000,
          sha256: 'a1b2c3d4e5f6g7h8i9j0a1b2c3d4e5f6g7h8i9j0a1b2c3d4e5f6g7h8i9j0a1b2',
          modifiedDate: DateTime.now().subtract(const Duration(days: 2)),
          createdDate: DateTime.now().subtract(const Duration(days: 15)),
          version: 2,
          backupStatus: 'Already Synced',
        ),
        DeviceFileMetadata(
          filename: 'profile_avatar.png',
          extension: 'png',
          relativePath: 'Documents/profile_avatar.png',
          fileSize: 1200000,
          sha256: '9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9f8e',
          modifiedDate: DateTime.now().subtract(const Duration(hours: 1)),
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
          version: 1,
          backupStatus: 'New File',
        ),
        DeviceFileMetadata(
          filename: 'yearly_budget.xlsx',
          extension: 'xlsx',
          relativePath: 'Documents/yearly_budget.xlsx',
          fileSize: 85000,
          sha256: 'bc54d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4',
          modifiedDate: DateTime.now().subtract(const Duration(hours: 5)),
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
          version: 4,
          backupStatus: 'Modified',
        ),
        DeviceFileMetadata(
          filename: 'meeting_notes.txt',
          extension: 'txt',
          relativePath: 'Documents/meeting_notes.txt',
          fileSize: 12000,
          sha256: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          modifiedDate: DateTime.now().subtract(const Duration(days: 5)),
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
          version: 1,
          backupStatus: 'Missing',
        ),
        DeviceFileMetadata(
          filename: 'vacation_vlog.mp4',
          extension: 'mp4',
          relativePath: 'Photos/vacation_vlog.mp4',
          fileSize: 890000000,
          sha256: 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef',
          modifiedDate: DateTime.now().subtract(const Duration(days: 8)),
          createdDate: DateTime.now().subtract(const Duration(days: 8)),
          version: 1,
          backupStatus: 'Skipped',
        ),
      ];
    }

    state = DeviceMetadataState(
      folders: folderList,
      files: fileList,
      extraDeviceInfo: extra,
      deviceId: device.id,
    );
  }

  String _generateMockHash(String input) {
    var hash = '';
    final hexChars = '0123456789abcdef';
    for (int i = 0; i < 64; i++) {
      hash += hexChars[(input.codeUnitAt(i % input.length) + i) % 16];
    }
    return hash;
  }

  Future<void> refreshDeviceStats() async {
    if (_device == null) return;
    state = state.copyWith(isReconnecting: true);
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate battery variation
    final isAndroid = _device!.platform.toLowerCase().contains('android');
    final Map<String, dynamic> updatedExtra = Map.from(state.extraDeviceInfo);
    
    if (isAndroid) {
      final currentBattery = updatedExtra['batteryPercentage'] as int? ?? 78;
      updatedExtra['batteryPercentage'] = max(5, min(100, currentBattery + (Random().nextBool() ? 1 : -1)));
    }
    
    state = state.copyWith(
      isReconnecting: false,
      extraDeviceInfo: updatedExtra,
    );
  }

  Future<void> refreshFolderMetadata() async {
    state = state.copyWith(isFolderSyncing: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final updatedFolders = state.folders.map((f) {
      if (f.syncStatus == 'Pending') {
        return f.copyWith(
          syncStatus: 'Synced',
          remoteDetails: f.localDetails.replaceAll('Local', 'Remote'),
        );
      } else if (f.syncStatus == 'Not Backed Up') {
        return f.copyWith(syncStatus: 'Pending');
      }
      return f;
    }).toList();

    state = state.copyWith(
      folders: updatedFolders,
      isFolderSyncing: false,
    );
  }

  Future<void> refreshFileMetadata() async {
    state = state.copyWith(isFileSyncing: true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final updatedFiles = state.files.map((f) {
      if (f.backupStatus == 'New File' || f.backupStatus == 'Modified') {
        return f.copyWith(backupStatus: 'Already Synced');
      }
      return f;
    }).toList();

    state = state.copyWith(
      files: updatedFiles,
      isFileSyncing: false,
    );
  }

  Future<void> triggerReconnect() async {
    state = state.copyWith(isReconnecting: true);
    await Future.delayed(const Duration(seconds: 2));
    await ref.read(deviceManagerProvider).loadDevices();
    state = state.copyWith(isReconnecting: false);
  }

  Future<String> generateDeviceDetailsReport() async {
    if (_device == null) return '';
    final extra = state.extraDeviceInfo;
    final report = '''# DEVICE DETAILS REPORT
Generated: ${DateTime.now().toLocal()}
Device Name: ${_device!.name}
Device UUID: ${_device!.id}
Platform: ${_device!.platform}
Device Model: ${_device!.deviceModel}
OS Version: ${_device!.osVersion}
App Version: ${_device!.appVersion}
Trust Status: ${_device!.trustStatus}
Connection Status: ${_device!.connectionStatus}
IP Address: ${_device!.ipAddress}
Port: ${_device!.port}
Last Seen: ${_device!.lastSeen}
Pairing Date: ${_device!.pairingDate}
Total Storage: ${extra['storageTotal']}
Used Storage: ${extra['storageUsed']}
Free Storage: ${extra['storageFree']}
Battery: ${extra['batteryPercentage']}% (${extra['chargingStatus']})
RAM Total: ${extra['ramTotal']}
RAM Used: ${extra['ramUsed']}
RAM Free: ${extra['ramFree']}
CPU Architecture: ${extra['cpuArchitecture']}
Wi-Fi SSID: ${extra['wifiSsid']}
Connection Type: ${extra['connectionType']}
Signal Strength: ${extra['signalStrength']}

*NO FILE CONTENT WAS TRANSFERRED DURING THIS DATA COLLECTION.*
''';
    return report;
  }

  Future<String> generateFolderMetadataReport() async {
    if (_device == null) return '';
    final buffer = StringBuffer();
    buffer.writeln('# FOLDER METADATA REPORT');
    buffer.writeln('Generated: ${DateTime.now().toLocal()}');
    buffer.writeln('Device: ${_device!.name} (${_device!.id})');
    buffer.writeln('\n| Folder Name | Local Path | Type | Total Files | Size (MB) | Sync Status |');
    buffer.writeln('| --- | --- | --- | --- | --- | --- |');
    
    for (final f in state.folders) {
      final sizeMb = (f.folderSize / (1024 * 1024)).toStringAsFixed(2);
      buffer.writeln('| ${f.folderName} | ${f.folderPath} | ${f.folderType} | ${f.totalFiles} | $sizeMb | ${f.syncStatus} |');
    }
    
    buffer.writeln('\n## Comparative Analysis Details');
    for (final f in state.folders) {
      buffer.writeln('\n### Folder: ${f.folderName}');
      buffer.writeln('- **Local Details**:\n  ${f.localDetails.replaceAll('\n', '\n  ')}');
      buffer.writeln('- **Remote Details**:\n  ${f.remoteDetails.replaceAll('\n', '\n  ')}');
    }
    
    buffer.writeln('\n*EXCHANGED FOLDER METADATA ONLY. NO FILES TRANSFERRED.*');
    return buffer.toString();
  }

  Future<String> generateFileMetadataReport() async {
    if (_device == null) return '';
    final buffer = StringBuffer();
    buffer.writeln('# FILE METADATA REPORT');
    buffer.writeln('Generated: ${DateTime.now().toLocal()}');
    buffer.writeln('Device: ${_device!.name} (${_device!.id})');
    buffer.writeln('\n| Filename | Extension | Size (Bytes) | SHA-256 Hash | Modified Date | Version | Backup Status |');
    buffer.writeln('| --- | --- | --- | --- | --- | --- | --- |');
    
    for (final f in state.files) {
      buffer.writeln('| ${f.filename} | ${f.extension} | ${f.fileSize} | ${f.sha256.substring(0, 10)}... | ${f.modifiedDate} | ${f.version} | ${f.backupStatus} |');
    }
    
    buffer.writeln('\n## Detailed File Records');
    for (final f in state.files) {
      buffer.writeln('\n### File: ${f.relativePath}');
      buffer.writeln('- **SHA-256 Hash**: ${f.sha256}');
      buffer.writeln('- **Size**: ${f.fileSize} bytes');
      buffer.writeln('- **Created**: ${f.createdDate}');
      buffer.writeln('- **Modified**: ${f.modifiedDate}');
      buffer.writeln('- **Version**: ${f.version}');
      buffer.writeln('- **Sync State**: ${f.backupStatus}');
    }
    
    buffer.writeln('\n*EXCHANGED FILE METADATA ONLY. NO FILE CONTENT WAS TRANSFERRED.*');
    return buffer.toString();
  }
}

final deviceMetadataProvider = NotifierProvider<DeviceMetadataNotifier, DeviceMetadataState>(() {
  return DeviceMetadataNotifier();
});
