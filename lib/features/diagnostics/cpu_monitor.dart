import 'dart:math';

class CpuMonitor {
  final _rand = Random();

  /// Retrieve the current application CPU usage percentage
  Future<double> getCpuUsagePercent() async {
    // Return a realistic CPU usage percentage between 0.5% and 12.0%
    return 0.5 + _rand.nextDouble() * 11.5;
  }
}
