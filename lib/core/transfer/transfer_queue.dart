import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transfer_worker.dart';

class TransferQueueState {
  final List<TransferWorker> workers;
  final bool isPaused;
  final String? activeSessionId;

  TransferQueueState({
    required this.workers,
    required this.isPaused,
    this.activeSessionId,
  });

  TransferQueueState copyWith({
    List<TransferWorker>? workers,
    bool? isPaused,
    String? activeSessionId,
  }) {
    return TransferQueueState(
      workers: workers ?? this.workers,
      isPaused: isPaused ?? this.isPaused,
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }
}

class TransferQueueNotifier extends Notifier<TransferQueueState> {
  @override
  TransferQueueState build() {
    return TransferQueueState(
      workers: [],
      isPaused: false,
      activeSessionId: null,
    );
  }

  void enqueue(TransferWorker worker) {
    state = state.copyWith(
      workers: [...state.workers, worker],
    );
    _processNext();
  }

  void pause() {
    state = state.copyWith(isPaused: true);
    for (final worker in state.workers) {
      worker.pause();
    }
  }

  void resume() {
    state = state.copyWith(isPaused: false);
    for (final worker in state.workers) {
      worker.resume();
    }
    _processNext();
  }

  void cancel(String sessionId) {
    final index = state.workers.indexWhere((w) => w.session?.sessionId == sessionId);
    if (index != -1) {
      state.workers[index].cancel();
      state = state.copyWith(
        workers: state.workers.where((w) => w.session?.sessionId != sessionId).toList(),
        activeSessionId: state.activeSessionId == sessionId ? null : state.activeSessionId,
      );
    }
    _processNext();
  }

  void _processNext() async {
    if (state.isPaused) return;
    if (state.activeSessionId != null) return;

    final nextWorkerIndex = state.workers.indexWhere(
      (w) => w.session == null,
    );
    if (nextWorkerIndex == -1) return;

    final pending = state.workers[nextWorkerIndex];
    final sessionId = await pending.start();
    
    state = state.copyWith(activeSessionId: sessionId);

    // Watch session state
    pending.session!.onStateChanged = (status) {
      if (status == 'Completed' || status == 'Failed' || status == 'Cancelled') {
        state = state.copyWith(activeSessionId: null);
        _processNext();
      }
    };
  }
}

final transferQueueProvider = NotifierProvider<TransferQueueNotifier, TransferQueueState>(() {
  return TransferQueueNotifier();
});
