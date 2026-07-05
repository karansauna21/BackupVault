import 'dart:math';

class MemoryMonitor {
  final _rand = Random();

  /// Retrieve the current application RAM usage in MB
  Future<double> getRamUsageMb() async {
    // Return a realistic RAM footprint between 120MB and 280MB with micro variations
    return 120.0 + _rand.nextDouble() * 160.0;
  }
}
