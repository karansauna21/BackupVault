import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'configuration_models.dart';

class ConfigurationRepository {
  List<HistoryRecord> _history = [];
  bool _initialized = false;
  late final File _historyFile;

  List<HistoryRecord> get history => List.unmodifiable(_history);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docDir.path, 'backup_vault'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _historyFile = File(p.join(dir.path, 'configuration_history.json'));
      if (await _historyFile.exists()) {
        final content = await _historyFile.readAsString();
        final list = json.decode(content) as List;
        _history = list.map((item) => HistoryRecord.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        _history = [];
        await _save();
      }
    } catch (_) {
      _history = [];
    }
    _initialized = true;
  }

  Future<void> addHistoryRecord(HistoryRecord record) async {
    await init();
    _history.insert(0, record);
    await _save();
  }

  Future<void> clearHistory() async {
    await init();
    _history.clear();
    await _save();
  }

  Future<void> _save() async {
    try {
      final jsonString = json.encode(_history.map((h) => h.toJson()).toList());
      await _historyFile.writeAsString(jsonString);
    } catch (_) {
      // ignored
    }
  }
}
