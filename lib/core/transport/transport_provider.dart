import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/settings_provider.dart';
import '../../shared/providers/device_provider.dart';
import '../services/logging_service.dart';
import '../database/database_provider.dart';
import 'transport_manager.dart';
import 'transport_repository.dart';

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  return TransportRepository(db);
});

final transportManagerProvider = Provider<TransportManager>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final appDb = ref.watch(databaseProvider);
  return TransportManager(db, deviceRepo, logger, appDb);
});
