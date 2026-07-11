import 'dart:async';

class BandwidthManager {
  int _limitBytesPerSec = 0; // 0 means unlimited
  bool _isPaused = false;
  
  int _bytesTransferredInWindow = 0;
  int _windowStartTimeMs = DateTime.now().millisecondsSinceEpoch;

  // Limits
  static const int limitLow = 128 * 1024;      // 128 KB/s
  static const int limitMedium = 1024 * 1024;  // 1 MB/s
  static const int limitHigh = 5 * 1024 * 1024; // 5 MB/s

  void setLimit(int limit) {
    _limitBytesPerSec = limit;
  }

  int get limit => _limitBytesPerSec;

  bool get isPaused => _isPaused;

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  Future<void> throttle(int byteCount) async {
    // 1. Enforce Pause
    while (_isPaused) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_limitBytesPerSec <= 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _windowStartTimeMs;

    if (elapsed >= 1000) {
      // Reset window
      _bytesTransferredInWindow = byteCount;
      _windowStartTimeMs = now;
      return;
    }

    _bytesTransferredInWindow += byteCount;

    if (_bytesTransferredInWindow >= _limitBytesPerSec) {
      // Calculate delay to next window
      final sleepTime = 1000 - elapsed;
      if (sleepTime > 0) {
        await Future.delayed(Duration(milliseconds: sleepTime));
      }
      // Reset window after sleep
      _bytesTransferredInWindow = byteCount;
      _windowStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
  }
}
