import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'version_models.dart';

class VersionExporter {
  /// Export version details to a JSON file
  static Future<File> exportToJSON(List<VersionDetail> list) async {
    final Map<String, dynamic> data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRecords': list.length,
      'versions': list.map((v) => {
        'versionNumber': v.version.versionNumber,
        'fileName': v.parentFile.fileName,
        'extension': v.parentFile.extension,
        'originalPath': v.parentFile.originalPath,
        'backupPath': v.version.backupPath,
        'sizeBytes': v.sizeBytes,
        'sha256': v.sha256,
        'createdAt': v.createdAt.toIso8601String(),
        'modifiedAt': v.modifiedAt.toIso8601String(),
        'backupDate': v.version.createdAt.toIso8601String(),
        'worker': v.backupWorker,
        'durationMs': v.backupDuration.inMilliseconds,
        'verificationStatus': v.verificationStatus,
        'notes': v.notes,
      }).toList(),
    };

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/version_history_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  /// Export version details to a CSV file
  static Future<File> exportToCSV(List<VersionDetail> list) async {
    final StringBuffer csv = StringBuffer();
    // CSV Header row
    csv.writeln('Version,File Name,Original Path,Backup Path,Size (Bytes),SHA-256,Created At,Modified At,Backup Date,Worker,Verification Status');

    for (final v in list) {
      csv.writeln(
        '${v.version.versionNumber},'
        '"${v.parentFile.fileName}",'
        '"${v.parentFile.originalPath}",'
        '"${v.version.backupPath}",'
        '${v.sizeBytes},'
        '${v.sha256},'
        '${v.createdAt.toIso8601String()},'
        '${v.modifiedAt.toIso8601String()},'
        '${v.version.createdAt.toIso8601String()},'
        '"${v.backupWorker}",'
        '"${v.verificationStatus}"'
      );
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/version_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv.toString());
    return file;
  }

  /// Export version details to a plain text log file
  static Future<File> exportToTXT(List<VersionDetail> list) async {
    final StringBuffer txt = StringBuffer();
    txt.writeln('==================================================');
    txt.writeln('BACKUPVAULT FILE VERSION HISTORY EXPORT');
    txt.writeln('Export Date: ${DateTime.now()}');
    txt.writeln('Total Versions Listed: ${list.length}');
    txt.writeln('==================================================\n');

    for (final v in list) {
      txt.writeln('Version #${v.version.versionNumber}');
      txt.writeln('--------------------------------------------------');
      txt.writeln('File Name:           ${v.parentFile.fileName}');
      txt.writeln('Extension:           ${v.parentFile.extension}');
      txt.writeln('Original Path:       ${v.parentFile.originalPath}');
      txt.writeln('Backup Store Path:   ${v.version.backupPath}');
      txt.writeln('File Size:           ${v.sizeBytes} bytes');
      txt.writeln('SHA-256 Hash:        ${v.sha256}');
      txt.writeln('Created Date:        ${v.createdAt}');
      txt.writeln('Modified Date:       ${v.modifiedAt}');
      txt.writeln('Backup Completed:    ${v.version.createdAt}');
      txt.writeln('Backup Worker:       ${v.backupWorker}');
      txt.writeln('Verification Status: ${v.verificationStatus.toUpperCase()}');
      if (v.notes != null) txt.writeln('Notes:               ${v.notes}');
      txt.writeln('==================================================\n');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/version_history_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(txt.toString());
    return file;
  }

  /// Export version details to a basic PDF file format
  static Future<File> exportToPDF(List<VersionDetail> list) async {
    final StringBuffer pdfText = StringBuffer();
    pdfText.writeln('%PDF-1.4');
    pdfText.writeln('% BackupVault Version History Document');
    pdfText.writeln('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj');
    pdfText.writeln('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj');
    pdfText.writeln('3 0 obj\n<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 4 0 R >>\nendobj');

    final StringBuffer body = StringBuffer();
    body.writeln('BT');
    body.writeln('/F1 12 Tf');
    body.writeln('70 750 Td');
    body.writeln('(BackupVault Version History Report) Tj');
    body.writeln('0 -20 Td');
    body.writeln('(Total Versions: ${list.length}) Tj');
    body.writeln('0 -20 Td');

    for (var i = 0; i < list.length && i < 15; i++) {
      final v = list[i];
      body.writeln('(v${v.version.versionNumber} | ${v.parentFile.fileName} | Size: ${v.sizeBytes} bytes | Status: ${v.verificationStatus}) Tj');
      body.writeln('0 -15 Td');
    }
    body.writeln('ET');

    final bytes = utf8.encode(body.toString());
    pdfText.writeln('4 0 obj\n<< /Length ${bytes.length} >>\nstream\n${body.toString()}endstream\nendobj');
    pdfText.writeln('xref\n0 5\n0000000000 65535 f \n0000000050 00000 n \n0000000100 00000 n \n0000000150 00000 n \n0000000250 00000 n \ntrailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n350\n%%EOF');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/version_history_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(utf8.encode(pdfText.toString()));
    return file;
  }
}
