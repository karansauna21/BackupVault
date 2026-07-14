import 'sync_queue.dart';

class SyncQueueManager extends SyncQueue {
  List<QueueItem> get pendingQueue => items
      .where((i) => i.status == 'waiting' || i.status == 'paused')
      .toList();

  List<QueueItem> get runningQueue =>
      items.where((i) => i.status == 'syncing').toList();

  List<QueueItem> get failedQueue =>
      items.where((i) => i.status == 'failed').toList();

  List<QueueItem> get completedQueue =>
      items.where((i) => i.status == 'completed').toList();
}
