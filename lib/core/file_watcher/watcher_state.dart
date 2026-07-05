import 'file_event.dart';

enum WatcherStatus {
  idle,
  active,
  paused,
  error
}

class WatcherState {
  final WatcherStatus status;
  final Set<int> monitoredFolderIds;
  final FileEvent? lastEvent;
  final String? errorMessage;

  WatcherState({
    required this.status,
    required this.monitoredFolderIds,
    this.lastEvent,
    this.errorMessage,
  });

  factory WatcherState.initial() {
    return WatcherState(
      status: WatcherStatus.idle,
      monitoredFolderIds: const {},
    );
  }

  WatcherState copyWith({
    WatcherStatus? status,
    Set<int>? monitoredFolderIds,
    FileEvent? lastEvent,
    String? errorMessage,
  }) {
    return WatcherState(
      status: status ?? this.status,
      monitoredFolderIds: monitoredFolderIds ?? this.monitoredFolderIds,
      lastEvent: lastEvent ?? this.lastEvent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
