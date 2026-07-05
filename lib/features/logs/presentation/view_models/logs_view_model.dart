import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logs_models.dart';
import '../../logs_provider.dart';

// Maintain backward compatibility with existing logsProvider references
final logsProvider = Provider<AsyncValue<List<LogEntry>>>((ref) {
  return ref.watch(logsControllerProvider);
});
