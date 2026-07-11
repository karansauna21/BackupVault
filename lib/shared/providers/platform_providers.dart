import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/folder_picker.dart';
import '../../core/services/permission_manager.dart';
import '../../core/services/storage_provider.dart';
import '../../core/services/platform_info.dart';
import '../../core/services/platform_notification_service.dart';

import '../../platform/windows/folder_picker/windows_folder_picker.dart';
import '../../platform/windows/permissions/windows_permission_manager.dart';
import '../../platform/windows/explorer/windows_storage_provider.dart';
import '../../platform/windows/ui/windows_platform_info.dart';
import '../../platform/windows/notifications/windows_notification_service.dart';

import '../../platform/android/folder_picker/android_folder_picker.dart';
import '../../platform/android/permissions/android_permission_manager.dart';
import '../../platform/android/storage/android_storage_provider.dart';
import '../../platform/android/ui/android_platform_info.dart';
import '../../platform/android/notifications/android_notification_service.dart';

final folderPickerProvider = Provider<FolderPicker>((ref) {
  if (Platform.isAndroid) {
    return const AndroidFolderPickerImpl();
  } else {
    return const WindowsFolderPickerImpl();
  }
});

final permissionManagerProvider = Provider<PermissionManager>((ref) {
  if (Platform.isAndroid) {
    return AndroidPermissionManager();
  } else {
    return WindowsPermissionManager();
  }
});

final storageProvider = Provider<StorageProvider>((ref) {
  if (Platform.isAndroid) {
    return AndroidStorageProvider();
  } else {
    return WindowsStorageProvider();
  }
});

final platformInfoProvider = Provider<PlatformInfo>((ref) {
  if (Platform.isAndroid) {
    return AndroidPlatformInfo();
  } else {
    return WindowsPlatformInfo();
  }
});

final platformNotificationServiceProvider = Provider<PlatformNotificationService>((ref) {
  if (Platform.isAndroid) {
    return AndroidNotificationService();
  } else {
    return WindowsNotificationService();
  }
});
