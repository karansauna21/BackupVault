import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:backup_vault/features/folder_manager/folder_models.dart';
import 'package:backup_vault/features/folder_manager/folder_rule_engine.dart';
import 'package:backup_vault/features/folder_manager/folder_scanner.dart';
import 'package:backup_vault/features/folder_manager/folder_validator.dart';

class FakeFile implements File {
  @override
  final String path;
  final int fileLength;

  FakeFile(this.path, {this.fileLength = 100});

  @override
  int lengthSync() => fileLength;

  @override
  Future<int> length() => Future.value(fileLength);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FolderRuleEngine Tests', () {
    const rootPath = 'C:\\folder';

    test('extension filter includeOnly matches correct extensions', () {
      final rules = FolderRules(includeExtensions: ['pdf', 'docx']);
      final engine = FolderRuleEngine(rules);

      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\report.pdf')), isTrue);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\notes.docx')), isTrue);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\photo.jpg')), isFalse);
    });

    test('extension filter exclude matches correct extensions', () {
      final rules = FolderRules(excludeExtensions: ['exe', 'mp4']);
      final engine = FolderRuleEngine(rules);

      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\app.exe')), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\video.mp4')), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\document.pdf')), isTrue);
    });

    test('ignoreTemp skips temp files', () {
      final rules = FolderRules(ignoreTemp: true);
      final engine = FolderRuleEngine(rules);

      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\file.tmp')), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\~lock.docx')), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\regular.txt')), isTrue);
    });

    test('ignoreSystem skips OS files', () {
      final rules = FolderRules(ignoreSystem: true);
      final engine = FolderRuleEngine(rules);

      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\desktop.ini')), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\.DS_Store')), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\data.csv')), isTrue);
    });

    test('ignoreEmpty skips 0-byte files', () {
      final rules = FolderRules(ignoreEmpty: true);
      final engine = FolderRuleEngine(rules);

      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\empty.txt', fileLength: 0)), isFalse);
      expect(engine.evaluateFile(rootPath, FakeFile('C:\\folder\\content.txt', fileLength: 100)), isTrue);
    });
  });

  group('FolderScanner Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('folder_scanner_test');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('scans files correctly and applies rules', () async {
      // Create some test files in temporary directory
      final file1 = File(p.join(tempDir.path, 'doc1.pdf'));
      await file1.writeAsString('pdf content');

      final file2 = File(p.join(tempDir.path, 'doc2.tmp'));
      await file2.writeAsString('temp content');

      final rules = FolderRules(excludeExtensions: ['tmp']);
      final scanner = FolderScanner(path: tempDir.path, rules: rules);
      final result = await scanner.scan();

      // Only doc1.pdf should be counted (doc2.tmp excluded by extension rule)
      expect(result.fileCount, equals(1));
      expect(result.totalSize, greaterThan(0));
    });
  });

  group('FolderValidator Tests', () {
    test('checkHealth computes high score for valid folders', () async {
      final source = await Directory.systemTemp.createTemp('health_src');
      final dest = await Directory.systemTemp.createTemp('health_dst');

      try {
        final health = await FolderValidator.checkHealth(source.path, dest.path);
        
        expect(health.score, greaterThanOrEqualTo(90));
        expect(health.isReadable, isTrue);
        expect(health.isWritable, isTrue);
        expect(health.pathExists, isTrue);
        expect(health.warnings, isEmpty);
      } finally {
        await source.delete(recursive: true);
        await dest.delete(recursive: true);
      }
    });

    test('checkHealth detects missing directory', () async {
      final health = await FolderValidator.checkHealth('Z:\\NonExistentFolder123', 'Y:\\NonExistentFolder456');
      
      expect(health.score, equals(0));
      expect(health.isReadable, isFalse);
      expect(health.isWritable, isFalse);
      expect(health.pathExists, isFalse);
      expect(health.warnings, isNotEmpty);
    });
  });
}
