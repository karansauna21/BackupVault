abstract class StorageProvider {
  Future<String?> resolvePath(String uriOrPath);
  Future<Map<String, String>?> pickDirectory();
  Future<Map<String, int>?> getDiskFreeSpace(String path);
}
