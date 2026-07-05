import 'dart:io';
import 'package:flutter/services.dart';

class AndroidStorage {
  static const MethodChannel _channel = MethodChannel('com.backupvault.backup_vault/storage');

  /// Check if the application has storage/all files access permissions.
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool hasPerm = await _channel.invokeMethod('hasStoragePermission');
      return hasPerm;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Request the storage/all files access permission.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool granted = await _channel.invokeMethod('requestStoragePermission');
      return granted;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Launch the SAF ACTION_OPEN_DOCUMENT_TREE folder picker.
  /// Returns a Map with keys 'uri' and 'path', or null if cancelled.
  static Future<Map<String, String>?> pickDirectory() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod('pickDirectory');
      if (result == null) return null;
      final map = Map<String, dynamic>.from(result);
      return {
        'uri': map['uri'] as String? ?? '',
        'path': map['path'] as String? ?? '',
      };
    } on PlatformException catch (_) {
      return null;
    }
  }
}
