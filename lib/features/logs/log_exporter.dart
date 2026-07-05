import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'logs_models.dart';

class LogExporter {
  /// Exports list of logs to a file in TXT, CSV, JSON, or ZIP format.
  /// Returns the absolute path of the generated export file.
  static Future<String> exportLogs({
    required List<LogEntry> logs,
    required String format,
    required String targetDirectory,
    String? customFileName,
  }) async {
    final dir = Directory(targetDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final baseName = customFileName ?? 'backupvault_logs_$dateStr';
    
    // Determine export string content
    String content = '';
    String fileExt = '';

    switch (format.toLowerCase()) {
      case 'csv':
        fileExt = '.csv';
        content = _generateCsv(logs);
        break;
      case 'json':
        fileExt = '.json';
        content = _generateJson(logs);
        break;
      case 'txt':
      default:
        fileExt = '.txt';
        content = _generateTxt(logs);
        break;
    }

    final String exportFilePath = p.join(targetDirectory, '$baseName$fileExt');
    final File exportFile = File(exportFilePath);
    await exportFile.writeAsString(content);

    // If ZIP format is requested, compress the exported file
    if (format.toLowerCase() == 'zip') {
      final zipFilePath = p.join(targetDirectory, '$baseName.zip');
      
      // We will compress the txt representation of logs inside the ZIP file
      final txtContent = _generateTxt(logs);
      final archive = Archive();
      final archiveFile = ArchiveFile(
        '$baseName.txt',
        txtContent.length,
        utf8.encode(txtContent),
      );
      archive.addFile(archiveFile);
      
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(zipData);
        
        // Clean up the temporary txt/csv file that was generated
        if (await exportFile.exists()) {
          await exportFile.delete();
        }
        return zipFilePath;
      }
    }

    return exportFilePath;
  }

  static String _generateTxt(List<LogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('======================================================================');
    buffer.writeln('BACKUPVAULT LOG EXPORT');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Total Entries: ${logs.length}');
    buffer.writeln('======================================================================\n');

    for (final log in logs) {
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp);
      buffer.writeln('[$timeStr] [${log.level.name.toUpperCase()}] [${log.module.displayName}] [${log.category.displayName}]');
      buffer.writeln('Message: ${log.message}');
      if (log.sourceFile != null && log.sourceFile!.isNotEmpty) {
        buffer.writeln('Source: ${log.sourceFile}');
      }
      if (log.destinationFile != null && log.destinationFile!.isNotEmpty) {
        buffer.writeln('Destination: ${log.destinationFile}');
      }
      if (log.durationMs != null) {
        buffer.writeln('Duration: ${log.durationMs} ms');
      }
      if (log.fileSize != null) {
        buffer.writeln('File Size: ${log.fileSize} bytes');
      }
      if (log.sha256 != null) {
        buffer.writeln('SHA-256: ${log.sha256}');
      }
      if (log.workerId != null) {
        buffer.writeln('Worker ID: ${log.workerId}');
      }
      if (log.status != null) {
        buffer.writeln('Status: ${log.status}');
      }
      if (log.errorCode != null) {
        buffer.writeln('Error Code: ${log.errorCode}');
      }
      if (log.exceptionDetails != null && log.exceptionDetails!.isNotEmpty) {
        buffer.writeln('Exception/Stacktrace:\n${log.exceptionDetails}');
      }
      buffer.writeln('----------------------------------------------------------------------');
    }
    return buffer.toString();
  }

  static String _generateCsv(List<LogEntry> logs) {
    final csvRows = <List<String>>[];
    
    // Headers
    csvRows.add([
      'ID',
      'Timestamp',
      'LogLevel',
      'Module',
      'Category',
      'Message',
      'SourceFile',
      'DestinationFile',
      'DurationMs',
      'WorkerId',
      'FileSize',
      'SHA-256',
      'Status',
      'ErrorCode',
      'ExceptionDetails',
    ]);

    for (final log in logs) {
      csvRows.add([
        log.id.toString(),
        DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp),
        log.level.name.toUpperCase(),
        log.module.name,
        log.category.displayName,
        _escapeCsvField(log.message),
        _escapeCsvField(log.sourceFile ?? ''),
        _escapeCsvField(log.destinationFile ?? ''),
        (log.durationMs ?? '').toString(),
        log.workerId ?? '',
        (log.fileSize ?? '').toString(),
        log.sha256 ?? '',
        log.status ?? '',
        log.errorCode ?? '',
        _escapeCsvField(log.exceptionDetails ?? ''),
      ]);
    }

    return csvRows.map((row) => row.join(',')).join('\n');
  }

  static String _generateJson(List<LogEntry> logs) {
    final list = logs.map((log) => {
      'id': log.id,
      'timestamp': log.timestamp.toIso8601String(),
      'level': log.level.name,
      'module': log.module.name,
      'category': log.category.name,
      'categoryDisplayName': log.category.displayName,
      'message': log.message,
      'sourceFile': log.sourceFile,
      'destinationFile': log.destinationFile,
      'durationMs': log.durationMs,
      'workerId': log.workerId,
      'fileSize': log.fileSize,
      'sha256': log.sha256,
      'status': log.status,
      'errorCode': log.errorCode,
      'exceptionDetails': log.exceptionDetails,
      'isPinned': log.isPinned,
      'isImportant': log.isImportant,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert(list);
  }

  static String _escapeCsvField(String field) {
    if (field.isEmpty) return '';
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
