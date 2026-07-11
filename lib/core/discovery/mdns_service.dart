// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../services/logging_service.dart';

class MdnsService {
  static const String serviceName = '_backupvault._tcp.local';
  static const String multicastAddress = '224.0.0.251';
  static const int mdnsPort = 5353;

  final LoggingService _logger;
  final String _deviceId;
  final String _deviceName;
  final String _platform;
  final String _appVersion;
  final int _transportPort;

  RawDatagramSocket? _socket;
  bool _isListening = false;
  final StreamController<Map<String, dynamic>> _discoveredDeviceController = StreamController.broadcast();
  Timer? _queryTimer;

  Stream<Map<String, dynamic>> get onDeviceDiscovered => _discoveredDeviceController.stream;

  MdnsService({
    required LoggingService logger,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String appVersion,
    required int transportPort,
  })  : _logger = logger,
        _deviceId = deviceId,
        _deviceName = deviceName,
        _platform = platform,
        _appVersion = appVersion,
        _transportPort = transportPort;

  Future<void> start() async {
    if (_isListening) return;

    try {
      // Bind to any IPv4 address on mDNS port to listen to multicast
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        mdnsPort,
        reuseAddress: true,
        reusePort: true,
      );

      // Join multicast group
      _socket!.joinMulticast(InternetAddress(multicastAddress));
      _socket!.multicastLoopback = true;
      _isListening = true;

      _logger.info('MdnsService', 'Started mDNS listener on port $mdnsPort');

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handlePacket(datagram.data, datagram.address.address);
          }
        }
      });

      // Start periodic query
      startQuerying();
    } catch (e) {
      _logger.warning('MdnsService', 'Failed to bind to default mDNS port 5353 ($e). Falling back to client-only mode.');
      // Fallback: Bind to port 0 (ephemeral port) to allow sending queries and receiving unicast responses
      try {
        _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        _socket!.joinMulticast(InternetAddress(multicastAddress));
        _isListening = true;
        _socket!.listen((event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket!.receive();
            if (datagram != null) {
              _handlePacket(datagram.data, datagram.address.address);
            }
          }
        });
        startQuerying();
      } catch (ex) {
        _logger.error('MdnsService', 'Failed to bind fallback client socket: $ex');
      }
    }
  }

  void stop() {
    _queryTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isListening = false;
    _logger.info('MdnsService', 'Stopped mDNS listener');
  }

  void startQuerying() {
    _queryTimer?.cancel();
    _queryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      query();
    });
    query(); // Initial query
  }

  void query() {
    if (_socket == null) return;
    try {
      final bytes = _buildQueryPacket();
      _socket!.send(bytes, InternetAddress(multicastAddress), mdnsPort);
    } catch (e) {
      _logger.error('MdnsService', 'Error sending query: $e');
    }
  }

  void _handlePacket(Uint8List data, String senderIp) {
    try {
      if (data.length < 12) return;
      final byteData = ByteData.sublistView(data);
      final flags = byteData.getUint16(2);
      final isResponse = (flags & 0x8000) != 0;

      final questions = byteData.getUint16(4);
      final answers = byteData.getUint16(6);
      final authority = byteData.getUint16(8);
      final additional = byteData.getUint16(10);

      if (!isResponse) {
        // Query packet: respond if looking for our service
        _handleQuery(data, questions, senderIp);
      } else {
        // Response packet: parse device records
        _handleResponse(data, answers + authority + additional, senderIp);
      }
    } catch (e) {
      // Ignore packet parsing errors from noisy local networks
    }
  }

  void _handleQuery(Uint8List data, int questionsCount, String senderIp) {
    // Parse query names to check if they match ours
    int offset = 12;
    bool matches = false;

    for (int i = 0; i < questionsCount; i++) {
      final parsed = _readName(data, offset);
      if (parsed == null) break;
      final name = parsed.item1;
      offset = parsed.item2;

      // Skip Type (2 bytes) and Class (2 bytes)
      offset += 4;

      if (name.toLowerCase() == serviceName.toLowerCase() || 
          name.toLowerCase().contains('_backupvault')) {
        matches = true;
      }
    }

    if (matches) {
      _logger.info('MdnsService', 'Received query from $senderIp, sending response');
      _sendResponse(senderIp);
    }
  }

  void _sendResponse(String destinationIp) {
    if (_socket == null) return;
    try {
      final responseBytes = _buildResponsePacket();
      // Send to multicast group or directly to sender
      _socket!.send(responseBytes, InternetAddress(multicastAddress), mdnsPort);
    } catch (e) {
      _logger.error('MdnsService', 'Error sending response: $e');
    }
  }

  void _handleResponse(Uint8List data, int recordsCount, String senderIp) {
    int offset = 12;

    // First skip question section if present
    final byteData = ByteData.sublistView(data);
    final questions = byteData.getUint16(4);
    for (int i = 0; i < questions; i++) {
      final parsed = _readName(data, offset);
      if (parsed == null) return;
      offset = parsed.item2 + 4; // name + type + class
    }

    // Now parse answers/additionals
    String? discoveredId;
    String? discoveredName;
    String? discoveredPlatform;
    String? discoveredVersion;
    int? discoveredPort;

    for (int i = 0; i < recordsCount; i++) {
      if (offset >= data.length) break;
      final parsed = _readName(data, offset);
      if (parsed == null) break;
      offset = parsed.item2;

      if (offset + 10 > data.length) break;
      final type = byteData.getUint16(offset);
      final rdLength = byteData.getUint16(offset + 8);
      offset += 10;

      if (offset + rdLength > data.length) break;
      final rData = data.sublist(offset, offset + rdLength);
      offset += rdLength;

      if (type == 16) {
        // TXT Record: Contains platform, id, name, version
        final txtMap = _parseTxtRecord(rData);
        if (txtMap.containsKey('id')) discoveredId = txtMap['id'];
        if (txtMap.containsKey('name')) discoveredName = txtMap['name'];
        if (txtMap.containsKey('platform')) discoveredPlatform = txtMap['platform'];
        if (txtMap.containsKey('version')) discoveredVersion = txtMap['version'];
      } else if (type == 33) {
        // SRV Record: Contains port (offset 4 of rdata)
        if (rData.length >= 6) {
          final srvData = ByteData.sublistView(rData);
          discoveredPort = srvData.getUint16(4);
        }
      }
    }

    if (discoveredId != null && discoveredId != _deviceId) {
      _discoveredDeviceController.add({
        'id': discoveredId,
        'name': discoveredName ?? 'Unknown Device',
        'platform': discoveredPlatform ?? 'Unknown',
        'version': discoveredVersion ?? '1.0.0',
        'ip': senderIp,
        'port': discoveredPort ?? _transportPort,
        'capabilities': ['Transport', 'Backup'],
        'status': 'Online'
      });
    }
  }

  // --- DNS Helper Functions ---

  Uint8List _buildQueryPacket() {
    final builder = BytesBuilder();
    // Transaction ID (0x0000)
    builder.add([0x00, 0x00]);
    // Flags: Standard query (0x0000)
    builder.add([0x00, 0x00]);
    // Questions (1)
    builder.add([0x00, 0x01]);
    // Answer RRs (0), Authority RRs (0), Additional RRs (0)
    builder.add([0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);

    // Name: _backupvault._tcp.local
    _writeDnsName(builder, serviceName);

    // Type: PTR (12)
    builder.add([0x00, 0x0c]);
    // Class: IN (1)
    builder.add([0x00, 0x01]);

    return builder.toBytes();
  }

  Uint8List _buildResponsePacket() {
    final builder = BytesBuilder();
    // Transaction ID (0x0000)
    builder.add([0x00, 0x00]);
    // Flags: Response, Authoritative (0x8400)
    builder.add([0x84, 0x00]);
    // Questions (0)
    builder.add([0x00, 0x00]);
    // Answer RRs (1)
    builder.add([0x00, 0x01]);
    // Authority RRs (0)
    builder.add([0x00, 0x00]);
    // Additional RRs (2) - TXT and SRV
    builder.add([0x00, 0x02]);

    // 1. Answer: PTR Record (serviceName -> instanceName)
    _writeDnsName(builder, serviceName);
    builder.add([0x00, 0x0c]); // Type: PTR
    builder.add([0x00, 0x01]); // Class: IN
    builder.add([0x00, 0x00, 0x0e, 0x10]); // TTL: 3600s
    
    final instanceName = '$_deviceId.$serviceName';
    final instanceNameBytes = _encodeDnsName(instanceName);
    builder.add([0x00, instanceNameBytes.length]); // RDLength
    builder.add(instanceNameBytes);

    // 2. Additional: SRV Record
    _writeDnsName(builder, instanceName);
    builder.add([0x00, 0x21]); // Type: SRV
    builder.add([0x00, 0x01]); // Class: IN
    builder.add([0x00, 0x00, 0x0e, 0x10]); // TTL
    // Priority (0), Weight (0), Port (transportPort), Target (deviceName.local)
    final targetBytes = _encodeDnsName('$_deviceName.local');
    final srvPayloadLength = 6 + targetBytes.length;
    builder.add([0x00, srvPayloadLength]); // RDLength
    builder.add([0x00, 0x00]); // Priority
    builder.add([0x00, 0x00]); // Weight
    final portBytes = ByteData(2)..setUint16(0, _transportPort);
    builder.add(portBytes.buffer.asUint8List());
    builder.add(targetBytes);

    // 3. Additional: TXT Record
    _writeDnsName(builder, instanceName);
    builder.add([0x00, 0x10]); // Type: TXT
    builder.add([0x00, 0x01]); // Class: IN
    builder.add([0x00, 0x00, 0x0e, 0x10]); // TTL
    
    final txtParts = [
      'id=$_deviceId',
      'name=$_deviceName',
      'platform=$_platform',
      'version=$_appVersion',
    ];
    final txtPayload = BytesBuilder();
    for (final part in txtParts) {
      final partBytes = utf8.encode(part);
      txtPayload.addByte(partBytes.length);
      txtPayload.add(partBytes);
    }
    final txtBytes = txtPayload.toBytes();
    builder.add([0x00, txtBytes.length]); // RDLength
    builder.add(txtBytes);

    return builder.toBytes();
  }

  void _writeDnsName(BytesBuilder builder, String name) {
    builder.add(_encodeDnsName(name));
  }

  Uint8List _encodeDnsName(String name) {
    final builder = BytesBuilder();
    final parts = name.split('.');
    for (final part in parts) {
      if (part.isEmpty) continue;
      final bytes = utf8.encode(part);
      builder.addByte(bytes.length);
      builder.add(bytes);
    }
    builder.addByte(0);
    return builder.toBytes();
  }

  // Parses DNS label/pointer strings
  _Tuple2<String, int>? _readName(Uint8List data, int offset, [int depth = 0]) {
    if (depth > 5 || offset >= data.length) return null;

    final parts = <String>[];
    int currentOffset = offset;

    while (currentOffset < data.length) {
      final len = data[currentOffset];
      if (len == 0) {
        currentOffset++;
        break;
      }

      // Check if pointer (top 2 bits are 11)
      if ((len & 0xc0) == 0xc0) {
        if (currentOffset + 1 >= data.length) return null;
        final pointerOffset = ((len & 0x3f) << 8) | data[currentOffset + 1];
        final pointerResult = _readName(data, pointerOffset, depth + 1);
        if (pointerResult == null) return null;
        parts.add(pointerResult.item1);
        currentOffset += 2;
        return _Tuple2(parts.join('.'), currentOffset);
      } else {
        currentOffset++;
        if (currentOffset + len > data.length) return null;
        final label = utf8.decode(data.sublist(currentOffset, currentOffset + len));
        parts.add(label);
        currentOffset += len;
      }
    }

    return _Tuple2(parts.join('.'), currentOffset);
  }

  Map<String, String> _parseTxtRecord(Uint8List data) {
    final result = <String, String>{};
    int offset = 0;
    while (offset < data.length) {
      final len = data[offset];
      offset++;
      if (offset + len > data.length) break;
      final part = utf8.decode(data.sublist(offset, offset + len));
      offset += len;

      final eqIdx = part.indexOf('=');
      if (eqIdx != -1) {
        final key = part.substring(0, eqIdx);
        final value = part.substring(eqIdx + 1);
        result[key] = value;
      }
    }
    return result;
  }
}

class _Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  _Tuple2(this.item1, this.item2);
}
