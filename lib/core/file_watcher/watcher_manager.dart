import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/logging_service.dart';
import '../services/backup_engine.dart';
import 'file_event.dart';
import 'file_event_queue.dart';
import 'folder_monitor.dart';
import 'watcher_state.dart';

class WatcherManager extends Notifier<WatcherState> {
  final Map<int, FolderMonitor> _monitors = {};
  late final FileEventQueue _eventQueue;

  @override
  WatcherState build() {
    _eventQueue = FileEventQueue(
      onEventsReady: _onEventsReady,
      debounceDuration: const Duration(milliseconds: 500),
    );

    ref.onDispose(() {
      _eventQueue.dispose();
      stopAll();
    });

    return WatcherState.initial();
  }

  void startMonitoringFolder(
    BackupFolder folder, {
    List<String> excludedSubfolders = const [],
    List<String> excludedExtensions = const [],
  }) {
    final folderId = folder.id;
    if (_monitors.containsKey(folderId)) {
      stopMonitoringFolder(folderId);
    }

    final monitor = FolderMonitor(
      folderId: folderId,
      sourcePath: folder.sourcePath,
      excludedSubfolders: excludedSubfolders,
      excludedExtensions: excludedExtensions,
      onEvent: _onEvent,
      onError: (error) => _onError(folderId, error),
    );

    _monitors[folderId] = monitor;
    monitor.start();

    final newMonitoredIds = Set<int>.from(state.monitoredFolderIds)..add(folderId);
    state = state.copyWith(
      status: WatcherStatus.active,
      monitoredFolderIds: newMonitoredIds,
    );
  }

  void stopMonitoringFolder(int folderId) {
    final monitor = _monitors.remove(folderId);
    if (monitor != null) {
      monitor.stop();
      final newMonitoredIds = Set<int>.from(state.monitoredFolderIds)..remove(folderId);
      final newStatus = newMonitoredIds.isEmpty ? WatcherStatus.idle : state.status;
      state = state.copyWith(
        status: newStatus,
        monitoredFolderIds: newMonitoredIds,
      );
    }
  }

  void stopAll() {
    for (final monitor in _monitors.values) {
      monitor.stop();
    }
    _monitors.clear();
    state = state.copyWith(
      status: WatcherStatus.idle,
      monitoredFolderIds: const {},
    );
  }

  void pauseAll() {
    for (final monitor in _monitors.values) {
      monitor.pause();
    }
    state = state.copyWith(status: WatcherStatus.paused);
  }

  void resumeAll() {
    for (final monitor in _monitors.values) {
      monitor.resume();
    }
    state = state.copyWith(
      status: _monitors.isEmpty ? WatcherStatus.idle : WatcherStatus.active,
    );
  }

  void restartAll() {
    for (final monitor in _monitors.values) {
      monitor.restart();
    }
    state = state.copyWith(
      status: _monitors.isEmpty ? WatcherStatus.idle : WatcherStatus.active,
    );
  }

  void _onEvent(FileEvent event) {
    final logger = ref.read(loggingServiceProvider);
    logger.info('FileWatcher', 'Event: ${event.type} on path: ${event.path}');

    state = state.copyWith(
      lastEvent: event,
      status: WatcherStatus.active,
      errorMessage: null,
    );

    _eventQueue.add(event);
  }

  void _onError(int folderId, String error) {
    final logger = ref.read(loggingServiceProvider);
    logger.error('FileWatcher', 'Folder $folderId monitor error: $error');

    state = state.copyWith(
      status: WatcherStatus.error,
      errorMessage: 'Folder monitor error: $error',
    );
  }

  void _onEventsReady(List<FileEvent> events) {
    final engine = ref.read(backupEngineProvider);
    for (final event in events) {
      engine.handleWatcherFileEvent(event);
    }
  }
}

final watcherStateProvider = NotifierProvider<WatcherManager, WatcherState>(() {
  return WatcherManager();
});
