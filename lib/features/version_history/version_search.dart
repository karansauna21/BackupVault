import 'version_models.dart';

class VersionSearchEvaluator {
  /// Match versions using text query (matches name, path, extension, hash, version tag, worker, folder)
  static List<VersionDetail> search(List<VersionDetail> list, String queryText) {
    if (queryText.trim().isEmpty) return list;
    final term = queryText.toLowerCase().trim();

    return list.where((item) {
      final nameMatch = item.parentFile.fileName.toLowerCase().contains(term);
      final extMatch = item.parentFile.extension.toLowerCase().contains(term);
      final shaMatch = item.sha256.toLowerCase().contains(term);
      final pathMatch = item.parentFile.originalPath.toLowerCase().contains(term);
      final verMatch = 'v${item.version.versionNumber}'.contains(term) ||
          item.version.versionNumber.toString() == term;
      final workerMatch = item.backupWorker.toLowerCase().contains(term);
      final folderMatch = item.folder.name.toLowerCase().contains(term);

      return nameMatch || extMatch || shaMatch || pathMatch || verMatch || workerMatch || folderMatch;
    }).toList();
  }

  /// Filter a list of VersionDetails according to configured constraints
  static List<VersionDetail> filter(List<VersionDetail> list, VersionHistoryFilter filter) {
    var results = list;

    // Apply main filter type
    switch (filter.type) {
      case VersionFilterType.latest:
        if (results.isNotEmpty) {
          final maxVer = results.fold<int>(0, (m, element) => element.version.versionNumber > m ? element.version.versionNumber : m);
          results = results.where((e) => e.version.versionNumber == maxVer).toList();
        }
        break;
      case VersionFilterType.oldest:
        if (results.isNotEmpty) {
          final minVer = results.fold<int>(999999, (m, element) => element.version.versionNumber < m ? element.version.versionNumber : m);
          results = results.where((e) => e.version.versionNumber == minVer).toList();
        }
        break;
      case VersionFilterType.modified:
        results = results.where((e) => e.modifiedAt != e.createdAt).toList();
        break;
      case VersionFilterType.restored:
        results = results.where((e) => e.verificationStatus == 'restored').toList();
        break;
      case VersionFilterType.verified:
        results = results.where((e) => e.verificationStatus == 'verified').toList();
        break;
      case VersionFilterType.failed:
        results = results.where((e) => e.verificationStatus == 'failed' || e.verificationStatus == 'corrupt').toList();
        break;
      case VersionFilterType.all:
        break;
    }

    // Apply folderId filter
    if (filter.folderId != null) {
      results = results.where((e) => e.parentFile.folderId == filter.folderId).toList();
    }

    // Apply dateRange filter
    if (filter.dateRange != null) {
      results = results.where((e) {
        final date = e.version.createdAt;
        return date.isAfter(filter.dateRange!.start) && date.isBefore(filter.dateRange!.end);
      }).toList();
    }

    // Apply search Prefix if defined
    if (filter.searchPrefix != null && filter.searchPrefix!.isNotEmpty) {
      results = search(results, filter.searchPrefix!);
    }

    return results;
  }
}
