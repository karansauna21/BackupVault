import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/services/logging_service.dart';
import '../transport/secure_channel.dart';
import '../transport/transport_manager.dart';
import 'transfer_repository.dart';
import 'transfer_session.dart';

class TransferWorker {
  final String deviceId;
  final String sourceFolderPath;
  final List<File> files;
  final SecureChannel channel;
  final TransferRepository repository;
  final LoggingService logger;
  final TransportManager transportManager;
  final int chunkSize;

  TransferSession? _session;
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  // Stats for V2 Progress display
  double _currentProgress = 0.0;
  double _currentSpeed = 0.0;
  String _currentFile = '';
  int _remainingBytes = 0;
  double _etaSeconds = 0.0;

  TransferWorker({
    required this.deviceId,
    required this.sourceFolderPath,
    required this.files,
    required this.channel,
    required this.repository,
    required this.logger,
    required this.transportManager,
    this.chunkSize = 4 * 1024 * 1024,
  });

  Stream<double> get progressStream => _progressController.stream;
  TransferSession? get session => _session;
  
  double get currentProgress => _currentProgress;
  double get currentSpeed => _currentSpeed;
  String get currentFile => _currentFile;
  int get remainingBytes => _remainingBytes;
  double get etaSeconds => _etaSeconds;

  Future<String> start() async {
    final sessionId = const Uuid().v4();
    
    _session = TransferSession(
      sessionId: sessionId,
      deviceId: deviceId,
      channel: channel,
      isSender: true,
      baseFolderPath: sourceFolderPath,
      chunkSize: chunkSize,
      repository: repository,
      logger: logger,
      transportManager: transportManager,
      onProgress: (progress, speed, file, remaining, eta) {
        _currentProgress = progress;
        _currentSpeed = speed;
        _currentFile = file;
        _remainingBytes = remaining;
        _etaSeconds = eta;
        _progressController.add(progress);
      },
    );

    // Populate queue with FileTransfer objects
    for (final file in files) {
      final relativePath = p.relative(file.path, from: sourceFolderPath);
      final size = await file.length();
      
      final transferRecord = FileTransfer(
        id: const Uuid().v4(),
        sessionId: sessionId,
        fileName: p.basename(file.path),
        relativePath: relativePath,
        fileSize: size,
        status: 'pending',
        transferredBytes: 0,
        startedAt: DateTime.now(),
      );
      
      _session!.addToQueue(transferRecord);
    }

    // Start session
    _session!.start();
    return sessionId;
  }

  void pause() => _session?.pause();
  void resume() => _session?.resume();
  void cancel() => _session?.cancel();
}
