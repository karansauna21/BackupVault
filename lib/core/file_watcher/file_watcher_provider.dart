import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'watcher_state.dart';
import 'watcher_manager.dart';
import 'file_event.dart';

final watcherStatusProvider = Provider<WatcherStatus>((ref) {
  final state = ref.watch(watcherStateProvider);
  return state.status;
});

final monitoredFoldersProvider = Provider<Set<int>>((ref) {
  final state = ref.watch(watcherStateProvider);
  return state.monitoredFolderIds;
});

final lastWatcherEventProvider = Provider<FileEvent?>((ref) {
  final state = ref.watch(watcherStateProvider);
  return state.lastEvent;
});

final watcherErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(watcherStateProvider);
  return state.errorMessage;
});
