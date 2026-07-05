import 'dart:ui';
import 'package:window_manager/window_manager.dart' as wm;
import 'package:screen_retriever/screen_retriever.dart';
import 'background_models.dart';
import 'background_repository.dart';

class WindowManager extends wm.WindowListener {
  final BackgroundRepository _repository;
  bool _minimizeToTrayOnClose = true;
  bool _isExiting = false;
  
  WindowState _currentState = const WindowState();
  WindowState get currentState => _currentState;

  final void Function(WindowState state)? onStateChanged;

  WindowManager(this._repository, {this.onStateChanged});

  Future<void> init() async {
    await wm.windowManager.ensureInitialized();
    wm.windowManager.addListener(this);
    
    // Prevent default exit on close button click
    await wm.windowManager.setPreventClose(true);

    // Load persisted state
    final savedState = await _repository.loadWindowState();
    _currentState = savedState;

    // Validate if the saved position is on any active screen (multiple monitors support)
    bool isPositionValid = false;
    if (savedState.x != null && savedState.y != null) {
      try {
        final displays = await ScreenRetriever.instance.getAllDisplays();
        for (final display in displays) {
          final pos = display.visiblePosition ?? Offset.zero;
          final size = display.visibleSize ?? display.size;
          final left = pos.dx;
          final top = pos.dy;
          final right = pos.dx + size.width;
          final bottom = pos.dy + size.height;

          // Check if saved top-left position is inside this screen's bounds
          if (savedState.x! >= left &&
              savedState.x! <= right &&
              savedState.y! >= top &&
              savedState.y! <= bottom) {
            isPositionValid = true;
            break;
          }
        }
      } catch (_) {
        // Fallback if screen retrieval fails
        isPositionValid = true;
      }
    }

    // Set initial window properties
    await wm.windowManager.setSize(Size(savedState.width, savedState.height));
    
    if (isPositionValid && savedState.x != null && savedState.y != null) {
      await wm.windowManager.setPosition(Offset(savedState.x!, savedState.y!));
    } else {
      await wm.windowManager.center();
    }

    if (savedState.isMaximized) {
      await wm.windowManager.maximize();
    }
  }

  void setMinimizeToTrayOnClose(bool value) {
    _minimizeToTrayOnClose = value;
  }

  Future<void> showWindow() async {
    await wm.windowManager.show();
    await wm.windowManager.focus();
    _currentState = _currentState.copyWith(isVisible: true, isMinimized: false);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }

  Future<void> hideWindow() async {
    await wm.windowManager.hide();
    _currentState = _currentState.copyWith(isVisible: false);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }

  Future<void> minimizeWindow() async {
    await wm.windowManager.minimize();
    _currentState = _currentState.copyWith(isMinimized: true);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }

  Future<void> restoreWindow() async {
    await wm.windowManager.restore();
    _currentState = _currentState.copyWith(isMinimized: false, isMaximized: false);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }

  Future<void> forceExit() async {
    _isExiting = true;
    await wm.windowManager.setPreventClose(false);
    await wm.windowManager.close();
  }

  // --- WindowListener overrides ---

  @override
  void onWindowClose() async {
    if (_isExiting) return;
    
    if (_minimizeToTrayOnClose) {
      await hideWindow();
    } else {
      await forceExit();
    }
  }

  @override
  void onWindowResized() async {
    if (_isExiting) return;
    final size = await wm.windowManager.getSize();
    final isMaximized = await wm.windowManager.isMaximized();
    
    if (!isMaximized) {
      _currentState = _currentState.copyWith(
        width: size.width,
        height: size.height,
        isMaximized: false,
      );
      onStateChanged?.call(_currentState);
      await _repository.saveWindowState(_currentState);
    }
  }

  @override
  void onWindowMoved() async {
    if (_isExiting) return;
    final pos = await wm.windowManager.getPosition();
    final isMaximized = await wm.windowManager.isMaximized();

    if (!isMaximized) {
      _currentState = _currentState.copyWith(
        x: pos.dx,
        y: pos.dy,
        isMaximized: false,
      );
      onStateChanged?.call(_currentState);
      await _repository.saveWindowState(_currentState);
    }
  }

  @override
  void onWindowMaximize() async {
    _currentState = _currentState.copyWith(isMaximized: true);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }

  @override
  void onWindowRestore() async {
    _currentState = _currentState.copyWith(isMaximized: false, isMinimized: false);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }

  @override
  void onWindowMinimize() async {
    _currentState = _currentState.copyWith(isMinimized: true);
    onStateChanged?.call(_currentState);
    await _repository.saveWindowState(_currentState);
  }
}
