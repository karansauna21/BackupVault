import 'dart:io';

class NetworkMonitor {
  /// Verify internet availability via lookup diagnostics (future-ready)
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
