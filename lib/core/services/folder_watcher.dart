import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'logging_service.dart';

class FolderWatcher {
  final Map<int, StreamSubscription<FileSystemEvent>> _subscriptions = {};
  final LoggingService _logger;

  FolderWatcher(this._logger);

  void startWatching(BackupFolder folder, void Function(FileSystemEvent event, BackupFolder folder) onEvent) async {
    final folderId = folder.id;
    if (_subscriptions.containsKey(folderId)) {
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

    try {
      final subscription = directory.watch(recursive: true).listen(
        (event) {
          // Skip temporary/hidden files if necessary, but pass through main events
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
  }

  void stopWatching(int folderId) {
    final subscription = _subscriptions.remove(folderId);
    if (subscription != null) {
      subscription.cancel();
      _logger.info('FolderWatcher', 'Stopped monitoring for folder ID: $folderId');
    }
  }

  void stopAll() {
    for (final id in _subscriptions.keys.toList()) {
      stopWatching(id);
    }
  }

  bool isWatching(int folderId) {
    return _subscriptions.containsKey(folderId);
  }
}

final folderWatcherProvider = Provider<FolderWatcher>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  return FolderWatcher(logger);
});
