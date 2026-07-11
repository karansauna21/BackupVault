import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/scheduler_models.dart';
import '../models/schedule_history.dart';

class SchedulerRepository {
  List<ScheduleConfig> _schedules = [];
  List<ScheduleHistory> _history = [];
  List<Map<String, dynamic>> _pendingJobs = [];

  bool _initialized = false;

  List<ScheduleConfig> get schedules => _schedules;
  List<ScheduleHistory> get history => _history;
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final schedulerDir = Directory(p.join(dir.path, 'backup_vault', 'scheduler'));
      if (!await schedulerDir.exists()) {
        await schedulerDir.create(recursive: true);
      }

      // Load schedules
      final schedulesFile = File(p.join(schedulerDir.path, 'schedules.json'));
      if (await schedulesFile.exists()) {
        final content = await schedulesFile.readAsString();
        if (content.isNotEmpty) {
          final List decoded = json.decode(content);
          _schedules = decoded.map((e) => ScheduleConfig.fromJson(e)).toList();
        }
      }

      // Load history
      final historyFile = File(p.join(schedulerDir.path, 'history.json'));
      if (await historyFile.exists()) {
        final content = await historyFile.readAsString();
        if (content.isNotEmpty) {
          final List decoded = json.decode(content);
          _history = decoded.map((e) => ScheduleHistory.fromJson(e)).toList();
        }
      }

      // Load pending jobs
      final pendingFile = File(p.join(schedulerDir.path, 'pending_jobs.json'));
      if (await pendingFile.exists()) {
        final content = await pendingFile.readAsString();
        if (content.isNotEmpty) {
          final List decoded = json.decode(content);
          _pendingJobs = decoded.cast<Map<String, dynamic>>();
        }
      }

      _initialized = true;
    } catch (_) {
      // Fallback in case of errors
      _schedules = [];
      _history = [];
      _pendingJobs = [];
      _initialized = true;
    }
  }

  Future<File> _getFile(String filename) async {
    final dir = await getApplicationSupportDirectory();
    final schedulerDir = Directory(p.join(dir.path, 'backup_vault', 'scheduler'));
    if (!await schedulerDir.exists()) {
      await schedulerDir.create(recursive: true);
    }
    return File(p.join(schedulerDir.path, filename));
  }

  Future<void> saveSchedules(List<ScheduleConfig> schedules) async {
    _schedules = schedules;
    final file = await _getFile('schedules.json');
    await file.writeAsString(json.encode(_schedules.map((e) => e.toJson()).toList()));
  }

  Future<void> addSchedule(ScheduleConfig schedule) async {
    final updated = List<ScheduleConfig>.from(_schedules)..add(schedule);
    await saveSchedules(updated);
  }

  Future<void> updateSchedule(ScheduleConfig schedule) async {
    final updated = _schedules.map((e) => e.id == schedule.id ? schedule : e).toList();
    await saveSchedules(updated);
  }

  Future<void> deleteSchedule(String id) async {
    final updated = _schedules.where((e) => e.id != id).toList();
    await saveSchedules(updated);
  }

  Future<void> saveHistory(List<ScheduleHistory> history) async {
    _history = history;
    final file = await _getFile('history.json');
    await file.writeAsString(json.encode(_history.map((e) => e.toJson()).toList()));
  }

  Future<void> addHistory(ScheduleHistory item) async {
    final updated = List<ScheduleHistory>.from(_history)..insert(0, item);
    if (updated.length > 1000) {
      updated.removeRange(1000, updated.length);
    }
    await saveHistory(updated);
  }

  Future<void> clearHistory() async {
    await saveHistory([]);
  }

  Future<void> savePendingJobs(List<Map<String, dynamic>> pendingJobs) async {
    _pendingJobs = pendingJobs;
    final file = await _getFile('pending_jobs.json');
    await file.writeAsString(json.encode(_pendingJobs));
  }
}
