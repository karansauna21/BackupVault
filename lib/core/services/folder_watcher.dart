import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'logging_service.dart';

class FolderWatcher {
  final Map<int, StreamSubscription<FileSystemEvent>> _subscriptions = {};
  final Map<int, Map<String, StreamSubscription<FileSystemEvent>>> _androidFolderSubscriptions = {};
  final LoggingService _logger;

  FolderWatcher(this._logger);

  void startWatching(BackupFolder folder, void Function(FileSystemEvent event, BackupFolder folder) onEvent) async {
    final folderId = folder.id;
    if (isWatching(folderId)) {
      stopWatching(folderId);
    }

    final directory = Directory(folder.sourcePath);
    if (!await directory.exists()) {
      await _logger.error(
        'FolderWatcher',
        'Cannot watch folder "${folder.name}" because source path does not exist: ${folder.sourcePath}',
      );
      return;
    }

    await _logger.info('FolderWatcher', 'Starting real-time monitoring for: ${folder.sourcePath}');

    if (Platform.isWindows) {
      try {
        final subscription = directory.watch(recursive: true).listen(
          (event) {
            onEvent(event, folder);
          },
          onError: (error) {
            _logger.error('FolderWatcher', 'Error in stream for folder ${folder.name}: $error');
          },
        );

        _subscriptions[folderId] = subscription;
      } catch (e) {
        await _logger.error('FolderWatcher', 'Failed to start watching "${folder.name}": $e');
      }
    } else {
      final subMap = <String, StreamSubscription<FileSystemEvent>>{};
      _androidFolderSubscriptions[folderId] = subMap;
      _watchDirectoryAndroid(folderId, folder.sourcePath, folder, onEvent, subMap);
    }
  }

  void _watchDirectoryAndroid(
    int folderId,
    String dirPath,
    BackupFolder folder,
    void Function(FileSystemEvent event, BackupFolder folder) onEvent,
    Map<String, StreamSubscription<FileSystemEvent>> subMap,
  ) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    try {
      final sub = dir.watch(recursive: false).listen(
        (event) {
          onEvent(event, folder);

          if (event.isDirectory) {
            if (event.type == FileSystemEvent.create) {
              _watchDirectoryAndroid(folderId, event.path, folder, onEvent, subMap);
            } else if (event.type == FileSystemEvent.delete) {
              _unwatchDirectoryAndroid(folderId, event.path, subMap);
            }
          }
        },
        onError: (err) {
          _unwatchDirectoryAndroid(folderId, dirPath, subMap);
        },
      );
      subMap[dirPath] = sub;

      dir.listSync(recursive: false, followLinks: false).forEach((entity) {
        if (entity is Directory) {
          _watchDirectoryAndroid(folderId, entity.path, folder, onEvent, subMap);
        }
      });
    } catch (_) {}
  }

  void _unwatchDirectoryAndroid(
    int folderId,
    String dirPath,
    Map<String, StreamSubscription<FileSystemEvent>> subMap,
  ) {
    final keysToRemove = subMap.keys
        .where((k) => k == dirPath || k.startsWith('$dirPath/'))
        .toList();
    for (final key in keysToRemove) {
      subMap[key]?.cancel();
      subMap.remove(key);
    }
  }

  void stopWatching(int folderId) {
    if (Platform.isWindows) {
      final subscription = _subscriptions.remove(folderId);
      if (subscription != null) {
        subscription.cancel();
        _logger.info('FolderWatcher', 'Stopped monitoring for folder ID: $folderId');
      }
    } else {
      final subMap = _androidFolderSubscriptions.remove(folderId);
      if (subMap != null) {
        for (final sub in subMap.values) {
          sub.cancel();
        }
        _logger.info('FolderWatcher', 'Stopped monitoring for folder ID: $folderId');
      }
    }
  }

  void stopAll() {
    for (final id in _subscriptions.keys.toList()) {
      stopWatching(id);
    }
    for (final id in _androidFolderSubscriptions.keys.toList()) {
      stopWatching(id);
    }
  }

  bool isWatching(int folderId) {
    return _subscriptions.containsKey(folderId) || _androidFolderSubscriptions.containsKey(folderId);
  }
}

final folderWatcherProvider = Provider<FolderWatcher>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  return FolderWatcher(logger);
});
