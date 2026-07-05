import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'release_models.dart';

class ReleaseRepository {
  final String? storagePath;

  ReleaseRepository({this.storagePath});

  VersionInfo _versionInfo = const VersionInfo();
  final List<BuildResult> _history = [];

  VersionInfo get versionInfo => _versionInfo;
  List<BuildResult> get history => List.unmodifiable(_history);

  Future<void> init() async {
    await loadVersionInfo();
    await loadHistory();
  }

  Future<File> _getFile(String fileName) async {
    final String basePath;
    if (storagePath != null) {
      basePath = storagePath!;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      basePath = dir.path;
    }
    final path = p.join(basePath, 'backup_vault', 'release');
    await Directory(path).create(recursive: true);
    return File(p.join(path, fileName));
  }

  // --- VersionInfo ---
  Future<void> loadVersionInfo() async {
    try {
      final file = await _getFile('version_info.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        _versionInfo = VersionInfo.fromJson(json.decode(content));
      }
    } catch (_) {
      _versionInfo = const VersionInfo();
    }
  }

  Future<void> saveVersionInfo(VersionInfo info) async {
    _versionInfo = info;
    final file = await _getFile('version_info.json');
    await file.writeAsString(json.encode(_versionInfo.toJson()));
  }

  // --- Release History ---
  Future<void> loadHistory() async {
    try {
      _history.clear();
      final file = await _getFile('release_history.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = json.decode(content) as List;
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _history.add(BuildResult.fromJson(item));
          }
        }
      }
    } catch (_) {
      _history.clear();
    }
  }

  Future<void> saveHistory() async {
    final file = await _getFile('release_history.json');
    final content = json.encode(_history.map((h) => h.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<void> addBuildResult(BuildResult result) async {
    _history.add(result);
    await saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await saveHistory();
  }
}
