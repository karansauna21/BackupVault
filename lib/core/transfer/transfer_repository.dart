import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database/database_provider.dart';

abstract class TransferRepository {
  Future<List<FileTransfer>> getAllTransfers();
  Future<FileTransfer?> getTransferById(String id);
  Future<List<FileTransfer>> getTransfersBySession(String sessionId);
  Future<void> saveTransfer(FileTransfer transfer);
  Future<void> updateTransferProgress(String id, int transferredBytes, String status, {DateTime? completedAt});
}

class TransferRepositoryImpl implements TransferRepository {
  final AppDatabase _db;

  TransferRepositoryImpl(this._db);

  @override
  Future<List<FileTransfer>> getAllTransfers() => _db.fileTransfersDao.getAllTransfers();

  @override
  Future<FileTransfer?> getTransferById(String id) => _db.fileTransfersDao.getTransferById(id);

  @override
  Future<List<FileTransfer>> getTransfersBySession(String sessionId) => _db.fileTransfersDao.getTransfersBySession(sessionId);

  @override
  Future<void> saveTransfer(FileTransfer transfer) async {
    final companion = FileTransfersCompanion(
      id: Value(transfer.id),
      sessionId: Value(transfer.sessionId),
      fileName: Value(transfer.fileName),
      relativePath: Value(transfer.relativePath),
      fileSize: Value(transfer.fileSize),
      hash: Value(transfer.hash),
      status: Value(transfer.status),
      transferredBytes: Value(transfer.transferredBytes),
      startedAt: Value(transfer.startedAt),
      completedAt: Value(transfer.completedAt),
    );
    await _db.fileTransfersDao.insertTransfer(companion);
  }

  @override
  Future<void> updateTransferProgress(String id, int transferredBytes, String status, {DateTime? completedAt}) async {
    final existing = await getTransferById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        transferredBytes: transferredBytes,
        status: status,
        completedAt: Value(completedAt ?? existing.completedAt),
      );
      await _db.fileTransfersDao.updateTransfer(updated);
    }
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransferRepositoryImpl(db);
});
