import '../../../core/services/storage_provider.dart';
import '../saf/android_storage.dart';

class AndroidStorageProvider implements StorageProvider {
  @override
  Future<String?> resolvePath(String uriOrPath) {
    return AndroidStorage.resolvePath(uriOrPath);
  }

  @override
  Future<Map<String, String>?> pickDirectory() {
    return AndroidStorage.pickDirectory();
  }

  @override
  Future<Map<String, int>?> getDiskFreeSpace(String path) async {
    // Return standard dummy storage stats for Android
    return {
      'free': 100 * 1024 * 1024 * 1024,
      'total': 500 * 1024 * 1024 * 1024,
    };
  }
}
