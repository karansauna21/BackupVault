import '../../../core/services/permission_manager.dart';
import '../saf/android_storage.dart';

class AndroidPermissionManager implements PermissionManager {
  @override
  Future<bool> hasStoragePermission() {
    return AndroidStorage.hasStoragePermission();
  }

  @override
  Future<bool> requestStoragePermission() {
    return AndroidStorage.requestStoragePermission();
  }

  @override
  Future<bool> hasPermission(String permissionName) {
    return AndroidStorage.hasPermission(permissionName);
  }

  @override
  Future<bool> requestPermission(String permissionName) {
    return AndroidStorage.requestPermission(permissionName);
  }
}
