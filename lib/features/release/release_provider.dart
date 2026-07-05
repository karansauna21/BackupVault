import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'release_models.dart';
import 'release_repository.dart';
import 'release_manager.dart';

// Repository Provider
final releaseRepositoryProvider = Provider<ReleaseRepository>((ref) {
  return ReleaseRepository();
});

// Manager Provider
final releaseManagerProvider = Provider<ReleaseManager>((ref) {
  final repo = ref.watch(releaseRepositoryProvider);
  return ReleaseManager(ref, repo);
});

// Current Version Notifier
class VersionInfoNotifier extends Notifier<VersionInfo> {
  @override
  VersionInfo build() {
    final repo = ref.watch(releaseRepositoryProvider);
    return repo.versionInfo;
  }

  void refresh() {
    final repo = ref.read(releaseRepositoryProvider);
    state = repo.versionInfo;
  }

  Future<void> updateChannel(String channel) async {
    final manager = ref.read(releaseManagerProvider);
    final updated = await manager.versionManager.updateChannel(channel);
    state = updated;
  }

  Future<void> incrementVersion(String type) async {
    final manager = ref.read(releaseManagerProvider);
    final VersionInfo updated;
    if (type == 'major') {
      updated = await manager.versionManager.incrementMajor();
    } else if (type == 'minor') {
      updated = await manager.versionManager.incrementMinor();
    } else {
      updated = await manager.versionManager.incrementPatch();
    }
    state = updated;
  }
}

final versionInfoProvider = NotifierProvider<VersionInfoNotifier, VersionInfo>(() {
  return VersionInfoNotifier();
});

// Release History Notifier
class ReleaseHistoryNotifier extends Notifier<List<BuildResult>> {
  @override
  List<BuildResult> build() {
    final repo = ref.watch(releaseRepositoryProvider);
    return List<BuildResult>.from(repo.history);
  }

  void refresh() {
    final repo = ref.read(releaseRepositoryProvider);
    state = List<BuildResult>.from(repo.history);
  }

  Future<void> addBuild(BuildResult result) async {
    final repo = ref.read(releaseRepositoryProvider);
    await repo.addBuildResult(result);
    refresh();
  }
}

final releaseHistoryProvider = NotifierProvider<ReleaseHistoryNotifier, List<BuildResult>>(() {
  return ReleaseHistoryNotifier();
});

// Status State
enum PackagingStatus { idle, validating, building, exporting, success, error }

class ReleaseState {
  final PackagingStatus status;
  final String? errorMessage;
  final BuildResult? buildResult;

  const ReleaseState({
    this.status = PackagingStatus.idle,
    this.errorMessage,
    this.buildResult,
  });

  ReleaseState copyWith({
    PackagingStatus? status,
    String? errorMessage,
    BuildResult? buildResult,
  }) => ReleaseState(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    buildResult: buildResult ?? this.buildResult,
  );
}

class ReleaseWorkflowNotifier extends Notifier<ReleaseState> {
  @override
  ReleaseState build() => const ReleaseState();

  Future<void> createReleasePackage({
    required String profile,
    required List<String> features,
    required List<String> bugFixes,
    required List<String> migrations,
  }) async {
    state = const ReleaseState(status: PackagingStatus.validating);
    try {
      final manager = ref.read(releaseManagerProvider);
      state = const ReleaseState(status: PackagingStatus.building);
      final result = await manager.createRelease(
        profile: profile,
        features: features,
        bugFixes: bugFixes,
        migrations: migrations,
      );
      state = const ReleaseState(status: PackagingStatus.exporting);
      ref.read(releaseHistoryProvider.notifier).refresh();
      state = ReleaseState(status: PackagingStatus.success, buildResult: result);
    } catch (e) {
      state = ReleaseState(status: PackagingStatus.error, errorMessage: e.toString());
    }
  }

  void reset() {
    state = const ReleaseState();
  }
}

final releaseWorkflowProvider = NotifierProvider<ReleaseWorkflowNotifier, ReleaseState>(() {
  return ReleaseWorkflowNotifier();
});
