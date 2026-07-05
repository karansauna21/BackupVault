import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'security_models.dart';

class SecurityRepository {
  final String? storagePath;

  SecurityRepository({this.storagePath});

  SecurityConfig _config = const SecurityConfig();
  final List<EncryptionKey> _keys = [];
  final List<AuditReport> _audits = [];

  SecurityConfig get config => _config;
  List<EncryptionKey> get keys => List.unmodifiable(_keys);
  List<AuditReport> get audits => List.unmodifiable(_audits);

  Future<void> init() async {
    await loadConfig();
    await loadKeys();
    await loadAudits();
  }

  Future<File> _getFile(String fileName) async {
    final String basePath;
    if (storagePath != null) {
      basePath = storagePath!;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      basePath = dir.path;
    }
    final path = p.join(basePath, 'backup_vault', 'security');
    await Directory(path).create(recursive: true);
    return File(p.join(path, fileName));
  }

  // --- Configuration persistence ---
  Future<void> loadConfig() async {
    try {
      final file = await _getFile('security_config.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonMap = json.decode(content) as Map<String, dynamic>;
        _config = SecurityConfig.fromJson(jsonMap);
      }
    } catch (_) {
      _config = const SecurityConfig();
    }
  }

  Future<void> saveConfig(SecurityConfig config) async {
    _config = config;
    final file = await _getFile('security_config.json');
    final content = json.encode(config.toJson());
    await file.writeAsString(content);
  }

  // --- Keys persistence ---
  Future<void> loadKeys() async {
    try {
      _keys.clear();
      final file = await _getFile('encryption_keys.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = json.decode(content) as List;
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _keys.add(EncryptionKey.fromJson(item));
          }
        }
      }
    } catch (_) {
      _keys.clear();
    }
  }

  Future<void> saveKeys() async {
    final file = await _getFile('encryption_keys.json');
    final content = json.encode(_keys.map((k) => k.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<void> addKey(EncryptionKey key) async {
    _keys.add(key);
    await saveKeys();
  }

  Future<void> deleteKey(String id) async {
    _keys.removeWhere((k) => k.id == id);
    await saveKeys();
  }

  Future<void> rotateKeys(String activeId) async {
    for (int i = 0; i < _keys.length; i++) {
      final key = _keys[i];
      _keys[i] = key.copyWith(isActive: key.id == activeId);
    }
    await saveKeys();
  }

  // --- Audits persistence ---
  Future<void> loadAudits() async {
    try {
      _audits.clear();
      final file = await _getFile('security_audits.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = json.decode(content) as List;
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _audits.add(AuditReport.fromJson(item));
          }
        }
      }
    } catch (_) {
      _audits.clear();
    }
  }

  Future<void> saveAudits() async {
    final file = await _getFile('security_audits.json');
    final content = json.encode(_audits.map((a) => a.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<void> addAuditReport(AuditReport report) async {
    _audits.add(report);
    await saveAudits();
  }

  Future<void> clearAudits() async {
    _audits.clear();
    await saveAudits();
  }
}
