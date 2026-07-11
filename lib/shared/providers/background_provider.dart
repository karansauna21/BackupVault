import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/background_models.dart';
import '../../core/services/background_controller.dart';
import '../../core/services/background_service.dart';

/// Main background module provider managing the combined state
final backgroundModuleProvider = NotifierProvider<BackgroundController, BackgroundModuleState>(() {
  return BackgroundController();
});

/// Exposes the core background execution state
final backgroundStateProvider = Provider<BackgroundState>((ref) {
  return ref.watch(backgroundModuleProvider.select((s) => s.background));
});

/// Exposes the system tray UI and details state
final trayStateProvider = Provider<TrayState>((ref) {
  return ref.watch(backgroundModuleProvider.select((s) => s.tray));
});

/// Exposes the Windows auto-startup configuration state
final startupStateProvider = Provider<StartupState>((ref) {
  return ref.watch(backgroundModuleProvider.select((s) => s.startup));
});

/// Exposes the application window position and visibility state
final windowStateProvider = Provider<WindowState>((ref) {
  return ref.watch(backgroundModuleProvider.select((s) => s.window));
});

/// Exposes the individual running state of each system engine and watcher
final runningServicesStateProvider = Provider<RunningServicesState>((ref) {
  return ref.watch(backgroundModuleProvider.select((s) => s.services));
});

/// Exposes the crash recovery and retry monitoring state
final crashStateProvider = Provider<CrashState>((ref) {
  return ref.watch(backgroundModuleProvider.select((s) => s.crash));
});

/// Exposes background service directly
final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  return ref.watch(backgroundModuleProvider.notifier).backgroundService;
});
