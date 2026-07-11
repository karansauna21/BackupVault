class ScheduleHistory {
  final String id;
  final DateTime executionTime;
  final Duration duration;
  final String trigger;
  final String result; // 'success', 'failed', 'skipped', etc.
  final int retryCount;
  final String workerUsed; // e.g. 'BackupEngine'
  final String status; // 'completed', 'failed', 'paused', etc.
  final String? errors;

  ScheduleHistory({
    required this.id,
    required this.executionTime,
    required this.duration,
    required this.trigger,
    required this.result,
    required this.retryCount,
    required this.workerUsed,
    required this.status,
    this.errors,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'executionTime': executionTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'trigger': trigger,
      'result': result,
      'retryCount': retryCount,
      'workerUsed': workerUsed,
      'status': status,
      'errors': errors,
    };
  }

  factory ScheduleHistory.fromJson(Map<String, dynamic> json) {
    return ScheduleHistory(
      id: json['id'] as String,
      executionTime: DateTime.parse(json['executionTime'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      trigger: json['trigger'] as String,
      result: json['result'] as String,
      retryCount: json['retryCount'] as int,
      workerUsed: json['workerUsed'] as String,
      status: json['status'] as String,
      errors: json['errors'] as String?,
    );
  }
}
