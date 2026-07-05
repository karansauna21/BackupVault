import 'dart:async';
import 'auto_start_manager.dart';
import 'background_models.dart';
import 'background_repository.dart';

class StartupManager {
  final AutoStartManager _autoStartManager;
  final BackgroundRepository _repository;

  StartupManager(this._autoStartManager, this._repository);

  Future<void> init() async {
    await _autoStartManager.init();
  }

  Future<StartupState> loadStartupState() async {
    final persisted = await _repository.loadStartupState();
    final systemEnabled = await _autoStartManager.isEnabled();
    
    // Keep in sync with system registry state
    return persisted.copyWith(isEnabled: systemEnabled);
  }

  Future<StartupState> updateStartupSettings({
    required bool enabled,
    required bool startMinimized,
    required bool startInSystemTray,
    required bool restorePreviousSession,
    required int startupDelaySeconds,
  }) async {
    if (enabled) {
      await _autoStartManager.enable();
    } else {
      await _autoStartManager.disable();
    }

    final newState = StartupState(
      isEnabled: enabled,
      startMinimized: startMinimized,
      startInSystemTray: startInSystemTray,
      restorePreviousSession: restorePreviousSession,
      startupDelaySeconds: startupDelaySeconds,
    );

    await _repository.saveStartupState(newState);
    return newState;
  }

  /// Implements startup delay option, executing the callback after delay if configured.
  Future<void> executeDelayedStartup(
      StartupState state, void Function() onExecute, void Function(int remainingSeconds) onProgress) async {
    if (state.startupDelaySeconds <= 0) {
      onExecute();
      return;
    }

    int remaining = state.startupDelaySeconds;
    onProgress(remaining);
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        onExecute();
      } else {
        onProgress(remaining);
      }
    });
  }
}
