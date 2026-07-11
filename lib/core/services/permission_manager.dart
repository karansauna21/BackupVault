abstract class PermissionManager {
  Future<bool> hasStoragePermission();
  Future<bool> requestStoragePermission();
  Future<bool> hasPermission(String permissionName);
  Future<bool> requestPermission(String permissionName);
}
