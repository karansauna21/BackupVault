import 'dart:async';
import 'dart:io';

class FolderWatcher {
  final String path;
  final void Function(FileSystemEvent event) onEvent;
  final void Function(Object error) onError;
  
  StreamSubscription<FileSystemEvent>? _winSubscription;
  final Map<String, StreamSubscription<FileSystemEvent>> _androidSubscriptions = {};
  bool _isPaused = false;

  FolderWatcher({
    required this.path,
    required this.onEvent,
    required this.onError,
  });

  void start() {
    stop();
    _isPaused = false;
    
    if (Platform.isWindows) {
      final dir = Directory(path);
      _winSubscription = dir.watch(recursive: true).listen(
        (event) {
          if (!_isPaused) {
            onEvent(event);
          }
        },
        onError: onError,
      );
    } else {
      _watchDirectoryAndroid(path);
    }
  }

  void _watchDirectoryAndroid(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    try {
      final sub = dir.watch(recursive: false).listen(
        (event) {
          if (_isPaused) return;

          onEvent(event);

          if (event.isDirectory) {
            if (event.type == FileSystemEvent.create) {
              _watchDirectoryAndroid(event.path);
            } else if (event.type == FileSystemEvent.delete) {
              _unwatchDirectoryAndroid(event.path);
            }
          }
        },
        onError: (err) {
          _unwatchDirectoryAndroid(dirPath);
        },
      );
      _androidSubscriptions[dirPath] = sub;

      // Scan and watch nested subdirectories recursively
      dir.listSync(recursive: false, followLinks: false).forEach((entity) {
        if (entity is Directory) {
          _watchDirectoryAndroid(entity.path);
        }
      });
    } catch (_) {
      // Gracefully handle files/folders that cannot be accessed due to permissions
    }
  }

  void _unwatchDirectoryAndroid(String dirPath) {
    final keysToRemove = _androidSubscriptions.keys
        .where((k) => k == dirPath || k.startsWith('$dirPath/'))
        .toList();
    for (final key in keysToRemove) {
      _androidSubscriptions[key]?.cancel();
      _androidSubscriptions.remove(key);
    }
  }

  void stop() {
    if (Platform.isWindows) {
      _winSubscription?.cancel();
      _winSubscription = null;
    } else {
      for (final sub in _androidSubscriptions.values) {
        sub.cancel();
      }
      _androidSubscriptions.clear();
    }
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  void restart() {
    stop();
    start();
  }

  bool get isMonitoring => Platform.isWindows ? _winSubscription != null : _androidSubscriptions.isNotEmpty;
  bool get isPaused => _isPaused;
}
