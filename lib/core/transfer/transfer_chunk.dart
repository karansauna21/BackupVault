import 'dart:typed_data';

class TransferChunk {
  final int index;
  final int offset;
  final int size;
  final Uint8List data;
  final String sha256;

  TransferChunk({
    required this.index,
    required this.offset,
    required this.size,
    required this.data,
    required this.sha256,
  });
}
