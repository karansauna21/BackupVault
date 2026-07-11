import 'dart:async';

class QueueItem {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String destDeviceId;
  final DateTime addedAt;
  
  int priority; // 0 = low, 1 = normal, 2 = high
  String status; // "waiting", "syncing", "paused", "failed", "completed"
  int retryCount;
  String? errorMessage;

  QueueItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.destDeviceId,
    required this.addedAt,
    this.priority = 1,
    this.status = 'waiting',
    this.retryCount = 0,
    this.errorMessage,
  });

  QueueItem copyWith({
    int? priority,
    String? status,
    int? retryCount,
    String? errorMessage,
  }) {
    return QueueItem(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      destDeviceId: destDeviceId,
      addedAt: addedAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'fileName': fileName,
    'fileSize': fileSize,
    'destDeviceId': destDeviceId,
    'addedAt': addedAt.toIso8601String(),
    'priority': priority,
    'status': status,
    'retryCount': retryCount,
    'errorMessage': errorMessage,
  };
}

class SyncQueue {
  final List<QueueItem> _items = [];
  final StreamController<List<QueueItem>> _controller = StreamController<List<QueueItem>>.broadcast();

  Stream<List<QueueItem>> get onQueueChanged => _controller.stream;
  List<QueueItem> get items => List.unmodifiable(_items);

  void enqueue(QueueItem item) {
    // Prevent duplicate active queueing for the same file to the same device
    final exists = _items.any((i) => i.filePath == item.filePath && i.destDeviceId == item.destDeviceId && (i.status == 'waiting' || i.status == 'syncing'));
    if (!exists) {
      _items.add(item);
      _sortQueue();
      _notify();
    }
  }

  void _sortQueue() {
    // Sort by priority desc (higher priority first), then by oldest addedAt first
    _items.sort((a, b) {
      final pCompare = b.priority.compareTo(a.priority);
      if (pCompare != 0) return pCompare;
      return a.addedAt.compareTo(b.addedAt);
    });
  }

  void updateStatus(String itemId, String status, {String? errorMessage}) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].status = status;
      if (errorMessage != null) {
        _items[idx].errorMessage = errorMessage;
      }
      _notify();
    }
  }

  void incrementRetry(String itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].retryCount++;
      _notify();
    }
  }

  void updatePriority(String itemId, int newPriority) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].priority = newPriority;
      _sortQueue();
      _notify();
    }
  }

  void pause() {
    for (final item in _items) {
      if (item.status == 'waiting') {
        item.status = 'paused';
      }
    }
    _notify();
  }

  void resume() {
    for (final item in _items) {
      if (item.status == 'paused') {
        item.status = 'waiting';
      }
    }
    _notify();
  }

  void retry(String itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].status = 'waiting';
      _items[idx].retryCount = 0;
      _items[idx].errorMessage = null;
      _sortQueue();
      _notify();
    }
  }

  void cancel(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    _notify();
  }

  void clear() {
    _items.clear();
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }
}
