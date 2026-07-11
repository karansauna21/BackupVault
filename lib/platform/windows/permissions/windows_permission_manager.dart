import '../../../core/services/permission_manager.dart';

class WindowsPermissionManager implements PermissionManager {
  @override
  Future<bool> hasStoragePermission() async => true;

  @override
  Future<bool> requestStoragePermission() async => true;

  @override
  Future<bool> hasPermission(String permissionName) async => true;

  @override
  Future<bool> requestPermission(String permissionName) async => true;
}
