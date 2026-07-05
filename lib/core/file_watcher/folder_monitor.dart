import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'file_event.dart';
import 'folder_watcher.dart';

class FolderMonitor {
  final int folderId;
  final String sourcePath;
  final List<String> excludedSubfolders;
  final List<String> excludedExtensions;
  final void Function(FileEvent event) onEvent;
  final void Function(String error) onError;

  late final FolderWatcher _watcher;
  Timer? _restartTimer;
  bool _isStopped = false;

  FolderMonitor({
    required this.folderId,
    required this.sourcePath,
    required this.onEvent,
    required this.onError,
    this.excludedSubfolders = const [],
    this.excludedExtensions = const [],
  }) {
    _watcher = FolderWatcher(
      path: sourcePath,
      onEvent: _handleNativeEvent,
      onError: _handleError,
    );
  }

  void start() {
    _isStopped = false;
    _restartTimer?.cancel();
    try {
      _watcher.start();
    } catch (e) {
      _handleError(e);
    }
  }

  void stop() {
    _isStopped = true;
    _restartTimer?.cancel();
    _watcher.stop();
  }

  void pause() {
    _watcher.pause();
  }

  void resume() {
    _watcher.resume();
  }

  void restart() {
    _watcher.restart();
  }

  void _handleNativeEvent(FileSystemEvent nativeEvent) {
    if (_isExcluded(nativeEvent.path)) return;

    if (nativeEvent is FileSystemMoveEvent && nativeEvent.destination != null) {
      if (_isExcluded(nativeEvent.destination!)) return;
    }

    final event = _translateEvent(nativeEvent);
    if (event != null) {
      onEvent(event);
    }
  }

  void _handleError(Object error) {
    onError(error.toString());
    if (!_isStopped) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 5), () {
        if (!_isStopped) {
          start();
        }
      });
    }
  }

  bool _isExcluded(String path) {
    for (final ext in excludedExtensions) {
      if (path.endsWith(ext)) return true;
    }

    for (final folder in excludedSubfolders) {
      if (p.isWithin(folder, path) || p.equals(folder, path)) return true;
    }

    return false;
  }

  FileEvent? _translateEvent(FileSystemEvent nativeEvent) {
    final path = nativeEvent.path;
    final isDir = nativeEvent.isDirectory;

    FileEventType type;
    String? destPath;

    if (nativeEvent is FileSystemCreateEvent) {
      type = isDir ? FileEventType.folderCreated : FileEventType.newFile;
    } else if (nativeEvent is FileSystemModifyEvent) {
      if (isDir) return null; // Ignore directory modifications
      type = FileEventType.modifiedFile;
    } else if (nativeEvent is FileSystemDeleteEvent) {
      type = isDir ? FileEventType.folderDeleted : FileEventType.deletedFile;
    } else if (nativeEvent is FileSystemMoveEvent) {
      destPath = nativeEvent.destination;
      if (isDir) {
        type = FileEventType.folderMoved;
      } else {
        type = FileEventType.movedFile;
      }
    } else {
      return null;
    }

    return FileEvent(
      folderId: folderId,
      type: type,
      path: path,
      destinationPath: destPath,
      timestamp: DateTime.now(),
      isDir: isDir,
    );
  }

  bool get isMonitoring => _watcher.isMonitoring;
  bool get isPaused => _watcher.isPaused;

  void dispose() {
    stop();
  }
}
