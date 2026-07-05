// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/file_version_repository.dart';
import '../repositories/repository_providers.dart';
import 'hash_service.dart';
import 'package:path/path.dart' as p;

class VersionManager {
  final FileVersionRepository _versionRepository;
  final HashService _hashService;

  VersionManager({
    required FileVersionRepository versionRepository,
    required HashService hashService,
  })  : _versionRepository = versionRepository,
        _hashService = hashService;

  Future<bool> hasFileChanged(File sourceFile, String existingSha256) async {
    final currentSha256 = await _hashService.calculateSha256(sourceFile);
    return currentSha256 != existingSha256;
  }

  Future<int> getNextVersionNumber(int fileId) async {
    final versions = await _versionRepository.getVersionsByFileId(fileId);
    if (versions.isEmpty) {
      return 2; // version 1 is the original file
    }
    final maxVersion = versions.fold<int>(1, (max, v) => v.versionNumber > max ? v.versionNumber : max);
    return maxVersion + 1;
  }

  String calculateVersionedPath(String baseBackupPath, int versionNumber) {
    if (versionNumber <= 1) {
      return baseBackupPath;
    }
    final directory = p.dirname(baseBackupPath);
    final filename = p.basename(baseBackupPath);
    return p.join(directory, '$filename.v$versionNumber');
  }
}

final versionManagerProvider = Provider<VersionManager>((ref) {
  final versionRepo = ref.watch(fileVersionRepositoryProvider);
  final hashService = ref.watch(hashServiceProvider);
  return VersionManager(
    versionRepository: versionRepo,
    hashService: hashService,
  );
});
