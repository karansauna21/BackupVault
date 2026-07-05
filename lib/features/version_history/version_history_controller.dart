import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'version_models.dart';
import 'version_history_provider.dart';
import 'version_exporter.dart';

class VersionHistoryController {
  final WidgetRef ref;

  VersionHistoryController(this.ref);

  /// Select file target for rendering version timelines
  void selectFile(int? fileId) {
    ref.read(selectedFileIdProvider.notifier).select(fileId);
    ref.read(selectedVersionProvider.notifier).select(null);
  }

  /// Select a single version snapshot for inspection or compare purposes
  void selectVersion(VersionDetail? version) {
    ref.read(selectedVersionProvider.notifier).select(version);
  }

  /// Change active filter constraints
  void updateFilterType(VersionFilterType type) {
    final current = ref.read(versionFiltersProvider);
    ref.read(versionFiltersProvider.notifier).updateFilter(current.copyWith(type: type));
  }

  /// Filter versions by parent folder ID
  void updateFolderId(int? folderId) {
    final current = ref.read(versionFiltersProvider);
    ref.read(versionFiltersProvider.notifier).updateFilter(current.copyWith(folderId: folderId));
  }

  /// Search versions containing specified prefix
  void updateSearchPrefix(String prefix) {
    final current = ref.read(versionFiltersProvider);
    ref.read(versionFiltersProvider.notifier).updateFilter(current.copyWith(searchPrefix: prefix));
  }

  /// Reset all version search filters
  void resetFilters() {
    ref.read(versionFiltersProvider.notifier).reset();
  }

  /// Safely restore version(s) in background
  Future<void> restoreSelectedVersions({
    required List<VersionDetail> versions,
    required String conflictPolicy,
    required BuildContext context,
  }) async {
    final service = ref.read(versionServiceProvider);
    try {
      final paths = await service.restoreVersions(
        versions: versions,
        conflictPolicy: conflictPolicy,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully restored ${paths.length} file(s).'),
            backgroundColor: Colors.green,
          ),
        );
      }
      ref.invalidate(versionListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restoration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Export version history records
  Future<void> exportHistory({
    required List<VersionDetail> versions,
    required String format,
    required BuildContext context,
  }) async {
    try {
      File file;
      switch (format.toLowerCase()) {
        case 'json':
          file = await VersionExporter.exportToJSON(versions);
          break;
        case 'csv':
          file = await VersionExporter.exportToCSV(versions);
          break;
        case 'txt':
          file = await VersionExporter.exportToTXT(versions);
          break;
        case 'pdf':
          file = await VersionExporter.exportToPDF(versions);
          break;
        default:
          throw Exception('Unsupported export format: $format');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported history successfully to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
