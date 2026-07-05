import 'dart:async';
import 'file_event.dart';

class FileEventQueue {
  final List<FileEvent> _buffer = [];
  Timer? _debounceTimer;
  final Duration debounceDuration;
  final void Function(List<FileEvent> events) onEventsReady;

  FileEventQueue({
    required this.onEventsReady,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  void add(FileEvent event) {
    _buffer.add(event);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _flush);
  }

  void _flush() {
    if (_buffer.isEmpty) return;

    final consolidated = _consolidate(_buffer);
    _buffer.clear();
    if (consolidated.isNotEmpty) {
      onEventsReady(consolidated);
    }
  }

  List<FileEvent> _consolidate(List<FileEvent> events) {
    final Map<String, FileEvent> consolidated = {};
    for (final event in events) {
      final existing = consolidated[event.path];
      if (existing == null) {
        consolidated[event.path] = event;
      } else {
        // Progression rules:
        // 1. If created then modified, keep as newFile.
        if (existing.type == FileEventType.newFile && event.type == FileEventType.modifiedFile) {
          continue;
        }
        // 2. If folderCreated then modified, keep folderCreated.
        if (existing.type == FileEventType.folderCreated && event.type == FileEventType.modifiedFile) {
          continue;
        }
        // 3. Otherwise, overwrite with the latest state.
        consolidated[event.path] = event;
      }
    }
    return consolidated.values.toList();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _buffer.clear();
  }
}
