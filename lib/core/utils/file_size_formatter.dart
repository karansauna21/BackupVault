import 'dart:math';

class FileSizeFormatter {
  static String formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    // Clamp index to ensure we don't go out of bounds of suffixes
    i = max(0, min(i, suffixes.length - 1));
    final double value = bytes / pow(1024, i);
    return "${value.toStringAsFixed(1)} ${suffixes[i]}";
  }
}
