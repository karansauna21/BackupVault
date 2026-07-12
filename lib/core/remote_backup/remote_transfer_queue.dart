import 'dart:async';

class RemoteQueueItem {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String destDeviceId;
  final DateTime addedAt;
  int priority; // 0 = low, 1 = normal, 2 = high
  String status; // 'waiting', 'syncing', 'paused', 'failed', 'completed'
  int retries;
  String? error;

  RemoteQueueItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.destDeviceId,
    required this.addedAt,
    this.priority = 1,
    this.status = 'waiting',
    this.retries = 0,
    this.error,
  });

  RemoteQueueItem copyWith({
    String? status,
    int? priority,
    int? retries,
    String? error,
  }) {
    return RemoteQueueItem(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      destDeviceId: destDeviceId,
      addedAt: addedAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retries: retries ?? this.retries,
      error: error ?? this.error,
    );
  }
}

class RemoteTransferQueue {
  final List<RemoteQueueItem> _items = [];
  final StreamController<List<RemoteQueueItem>> _queueController = StreamController.broadcast();

  Stream<List<RemoteQueueItem>> get onQueueChanged => _queueController.stream;
  List<RemoteQueueItem> get items => List.unmodifiable(_items);

  void enqueue(RemoteQueueItem item) {
    if (_items.any((i) => i.id == item.id)) return;
    _items.add(item);
    _sortQueue();
    _notify();
  }

  void remove(String id) {
    _items.removeWhere((i) => i.id == id);
    _notify();
  }

  void updateStatus(String id, String status) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].status = status;
      if (status == 'completed') {
        _items[idx].error = null;
      }
      _notify();
    }
  }

  void updatePriority(String id, int priority) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].priority = priority;
      _sortQueue();
      _notify();
    }
  }

  void markFailed(String id, String error) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].status = 'failed';
      _items[idx].error = error;
      _notify();
    }
  }

  void incrementRetries(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].retries++;
      _notify();
    }
  }

  void pauseAll() {
    for (final item in _items) {
      if (item.status == 'waiting' || item.status == 'syncing') {
        item.status = 'paused';
      }
    }
    _notify();
  }

  void resumeAll() {
    for (final item in _items) {
      if (item.status == 'paused') {
        item.status = 'waiting';
      }
    }
    _notify();
  }

  void clearCompleted() {
    _items.removeWhere((i) => i.status == 'completed');
    _notify();
  }

  void _sortQueue() {
    _items.sort((a, b) {
      // Sort by priority descending, then addedAt ascending
      final pCompare = b.priority.compareTo(a.priority);
      if (pCompare != 0) return pCompare;
      return a.addedAt.compareTo(b.addedAt);
    });
  }

  void _notify() {
    _queueController.add(List.from(_items));
  }

  void dispose() {
    _queueController.close();
  }
}
