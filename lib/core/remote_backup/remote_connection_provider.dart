import 'dart:async';

enum RemoteConnectionState {
  disconnected,
  connecting,
  connected,
  failed
}

abstract class RemoteConnectionProvider {
  String get providerId;
  Future<void> initialize();
  Future<void> connect(String deviceId);
  Future<void> disconnect(String deviceId);
  Future<void> sendData(String deviceId, List<int> data);
  Stream<List<int>> dataStream(String deviceId);
  Stream<RemoteConnectionState> connectionStateStream(String deviceId);
  void dispose();
}

class SimulatedRemoteConnectionProvider implements RemoteConnectionProvider {
  @override
  String get providerId => 'simulated_provider';

  final Map<String, StreamController<List<int>>> _dataStreams = {};
  final Map<String, StreamController<RemoteConnectionState>> _stateStreams = {};
  final Map<String, RemoteConnectionState> _states = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> connect(String deviceId) async {
    _stateStreams[deviceId] ??= StreamController<RemoteConnectionState>.broadcast();
    _dataStreams[deviceId] ??= StreamController<List<int>>.broadcast();
    
    _states[deviceId] = RemoteConnectionState.connecting;
    final stateStream = _stateStreams[deviceId];
    if (stateStream != null && !stateStream.isClosed) {
      stateStream.add(RemoteConnectionState.connecting);
    }
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    _states[deviceId] = RemoteConnectionState.connected;
    final stateStream2 = _stateStreams[deviceId];
    if (stateStream2 != null && !stateStream2.isClosed) {
      stateStream2.add(RemoteConnectionState.connected);
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _states[deviceId] = RemoteConnectionState.disconnected;
    final stateStream = _stateStreams[deviceId];
    if (stateStream != null && !stateStream.isClosed) {
      stateStream.add(RemoteConnectionState.disconnected);
    }
  }

  @override
  Future<void> sendData(String deviceId, List<int> data) async {
    Timer(const Duration(milliseconds: 30), () {
      final ctrl = _dataStreams[deviceId];
      if (ctrl != null && !ctrl.isClosed) {
        ctrl.add(data);
      }
    });
  }

  @override
  Stream<List<int>> dataStream(String deviceId) {
    _dataStreams[deviceId] ??= StreamController<List<int>>.broadcast();
    return _dataStreams[deviceId]!.stream;
  }

  @override
  Stream<RemoteConnectionState> connectionStateStream(String deviceId) {
    _stateStreams[deviceId] ??= StreamController<RemoteConnectionState>.broadcast();
    return _stateStreams[deviceId]!.stream;
  }

  @override
  void dispose() {
    for (final ctrl in _dataStreams.values) {
      ctrl.close();
    }
    for (final ctrl in _stateStreams.values) {
      ctrl.close();
    }
  }
}
