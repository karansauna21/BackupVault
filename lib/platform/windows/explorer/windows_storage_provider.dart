import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../../../core/services/storage_provider.dart';

class WindowsStorageProvider implements StorageProvider {
  @override
  Future<String?> resolvePath(String uriOrPath) async {
    return uriOrPath;
  }

  @override
  Future<Map<String, String>?> pickDirectory() async {
    return null;
  }

  @override
  Future<Map<String, int>?> getDiskFreeSpace(String path) async {
    if (!Platform.isWindows) return {'free': 0, 'total': 0};
    
    final lpFreeBytesAvailable = calloc<Uint64>();
    final lpTotalNumberOfBytes = calloc<Uint64>();
    final lpTotalNumberOfFreeBytes = calloc<Uint64>();

    try {
      final pathPtr = path.toNativeUtf16();
      final result = GetDiskFreeSpaceEx(
        pathPtr,
        lpFreeBytesAvailable.cast(),
        lpTotalNumberOfBytes.cast(),
        lpTotalNumberOfFreeBytes.cast(),
      );
      calloc.free(pathPtr);

      if (result != 0) {
        return {
          'free': lpFreeBytesAvailable.value,
          'total': lpTotalNumberOfBytes.value,
        };
      }
    } catch (_) {
      // ignored
    } finally {
      calloc.free(lpFreeBytesAvailable);
      calloc.free(lpTotalNumberOfBytes);
      calloc.free(lpTotalNumberOfFreeBytes);
    }
    return {'free': 0, 'total': 0};
  }
}
