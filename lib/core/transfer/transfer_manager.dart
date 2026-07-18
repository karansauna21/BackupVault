import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/services/logging_service.dart';
import '../database/database_provider.dart';
import '../transport/transport_manager.dart';
import '../transport/transport_provider.dart';
import 'transfer_repository.dart';
import 'transfer_session.dart';
import 'transfer_worker.dart';

class TransferManager {
  final TransportManager transportManager;
  final TransferRepository repository;
  final LoggingService logger;
  final AppDatabase db;

  final Map<String, TransferSession> _activeSessions = {};

  TransferManager({
    required this.transportManager,
    required this.repository,
    required this.logger,
    required this.db,
  });

  Map<String, TransferSession> get activeSessions => _activeSessions;

  Future<TransferWorker> createSenderWorker({
    required String deviceId,
    required String sourceFolderPath,
    required List<File> files,
  }) async {
    // 1. Verify trusted pairing
    final device = await db.pairedDevicesDao.getDeviceByUuid(deviceId);
    if (device == null) {
      throw Exception('Security violation: Unknown device Rejected!');
    }

    final channel = transportManager.getChannel(deviceId);
    if (channel == null || !channel.isAuthenticated) {
      throw Exception('Security violation: Channel not authenticated or active');
    }

    final worker = TransferWorker(
      deviceId: deviceId,
      sourceFolderPath: sourceFolderPath,
      files: files,
      channel: channel,
      repository: repository,
      logger: logger,
      transportManager: transportManager,
    );

    return worker;
  }

  void registerReceiverSession(String sessionId, String deviceId, String destFolderPath) {
    final channel = transportManager.getChannel(deviceId);
    if (channel == null) return;

    final session = TransferSession(
      sessionId: sessionId,
      deviceId: deviceId,
      channel: channel,
      isSender: false,
      baseFolderPath: destFolderPath,
      repository: repository,
      logger: logger,
      transportManager: transportManager,
    );

    _activeSessions[sessionId] = session;
    session.start();
  }
}

final transferManagerProvider = Provider<TransferManager>((ref) {
  final transport = ref.watch(transportManagerProvider);
  final repo = ref.watch(transferRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final db = ref.watch(databaseProvider);
  
  return TransferManager(
    transportManager: transport,
    repository: repo,
    logger: logger,
    db: db,
  );
});
