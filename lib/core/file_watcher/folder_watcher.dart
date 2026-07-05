import 'dart:async';
import 'dart:io';

class FolderWatcher {
  final String path;
  final void Function(FileSystemEvent event) onEvent;
  final void Function(Object error) onError;
  StreamSubscription<FileSystemEvent>? _subscription;
  bool _isPaused = false;

  FolderWatcher({
    required this.path,
    required this.onEvent,
    required this.onError,
  });

  void start() {
    stop();
    _isPaused = false;
    final dir = Directory(path);
    _subscription = dir.watch(recursive: true).listen(
      (event) {
        if (!_isPaused) {
          onEvent(event);
        }
      },
      onError: (err) {
        onError(err);
      },
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
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

  bool get isMonitoring => _subscription != null;
  bool get isPaused => _isPaused;
}
