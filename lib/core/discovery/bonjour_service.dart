// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import '../services/logging_service.dart';
import 'mdns_service.dart';

class BonjourService {
  final LoggingService _logger;
  final MdnsService _mdnsService;

  BonjourService({
    required LoggingService logger,
    required MdnsService mdnsService,
  })  : _logger = logger,
        _mdnsService = mdnsService;

  Future<void> registerService() async {
    _logger.info('BonjourService', 'Registering BackupVault Zeroconf Service');
    await _mdnsService.start();
  }

  Future<void> unregisterService() async {
    _logger.info('BonjourService', 'Unregistering BackupVault Zeroconf Service');
    _mdnsService.stop();
  }

  Stream<Map<String, dynamic>> discoverServices() {
    _logger.info('BonjourService', 'Initiating Bonjour Service Discovery query');
    _mdnsService.query();
    return _mdnsService.onDeviceDiscovered;
  }
}
