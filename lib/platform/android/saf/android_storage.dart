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

  /// Launch the SAF ACTION_OPEN_DOCUMENT_TREE folder picker with an optional initial URI.
  /// Returns a Map with keys 'uri' and 'path', or null if cancelled.
  static Future<Map<String, String>?> pickDirectory({String? initialUri}) async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod('pickDirectory', {'initialUri': initialUri});
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

  /// Resolve a tree URI to a raw absolute file system path.
  static Future<String?> resolvePath(String uri) async {
    if (!Platform.isAndroid) return null;
    try {
      final String? path = await _channel.invokeMethod('resolvePath', {'uri': uri});
      return path;
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Check if the application has a specific permission.
  static Future<bool> hasPermission(String permission) async {
    if (!Platform.isAndroid) return true;
    try {
      final bool hasPerm = await _channel.invokeMethod('hasPermission', {'permission': permission});
      return hasPerm;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Request a specific permission.
  static Future<bool> requestPermission(String permission) async {
    if (!Platform.isAndroid) return true;
    try {
      final bool granted = await _channel.invokeMethod('requestPermission', {'permission': permission});
      return granted;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if access to a URI is still persisted/valid.
  static Future<bool> isUriPermissionPersisted(String uri) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool persisted = await _channel.invokeMethod('isUriPermissionPersisted', {'uri': uri});
      return persisted;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get the list of all currently persisted URI permissions.
  static Future<List<String>> getPersistedUriPermissions() async {
    if (!Platform.isAndroid) return const [];
    try {
      final result = await _channel.invokeMethod('getPersistedUriPermissions');
      if (result == null) return const [];
      return List<String>.from(result);
    } on PlatformException catch (_) {
      return const [];
    }
  }

  /// Get list of connected storage volumes (Internal, SD Card, etc.)
  static Future<List<Map<String, dynamic>>> getStorageVolumes() async {
    if (!Platform.isAndroid) return const [];
    try {
      final result = await _channel.invokeMethod('getStorageVolumes');
      if (result == null) return const [];
      final List<dynamic> list = result;
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } on PlatformException catch (_) {
      return const [];
    }
  }
}
