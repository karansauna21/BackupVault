import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/folder_picker.dart';
import '../../../core/database/app_database.dart';
import '../../../features/folder_manager/folder_manager_provider.dart';
import '../saf/android_storage.dart';

class AndroidFolderPickerImpl implements FolderPicker {
  const AndroidFolderPickerImpl();

  @override
  Future<String?> pickFolder(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const AndroidFolderPicker(),
    );
  }
}

class AndroidFolderPicker extends ConsumerStatefulWidget {
  const AndroidFolderPicker({super.key});

  @override
  ConsumerState<AndroidFolderPicker> createState() => _AndroidFolderPickerState();
}

class _AndroidFolderPickerState extends ConsumerState<AndroidFolderPicker> {
  final List<Map<String, dynamic>> _folders = [
    {
      'id': 'internal_storage',
      'name': 'Internal Storage',
      'icon': Icons.phone_android_rounded,
      'color': Colors.blueGrey,
      'description': 'Root directory of internal storage',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3A',
      'volumeType': 'primary',
    },
    {
      'id': 'sd_card',
      'name': 'SD Card',
      'icon': Icons.sd_card_rounded,
      'color': Colors.brown,
      'description': 'External SD Card storage',
      'uri': '', // Filled dynamically
      'volumeType': 'external',
    },
    {
      'id': 'downloads',
      'name': 'Downloads',
      'icon': Icons.download_rounded,
      'color': Colors.green,
      'description': 'Downloaded files and documents',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADownload',
      'volumeType': 'primary',
    },
    {
      'id': 'documents',
      'name': 'Documents',
      'icon': Icons.description_rounded,
      'color': Colors.orange,
      'description': 'Text files, PDFs and docs',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADocuments',
      'volumeType': 'primary',
    },
    {
      'id': 'pictures',
      'name': 'Pictures',
      'icon': Icons.image_rounded,
      'color': Colors.blue,
      'description': 'Saved pictures and images',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3APictures',
      'volumeType': 'primary',
    },
    {
      'id': 'movies',
      'name': 'Movies',
      'icon': Icons.movie_rounded,
      'color': Colors.red,
      'description': 'Videos and recorded movies',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3AMovies',
      'volumeType': 'primary',
    },
    {
      'id': 'music',
      'name': 'Music',
      'icon': Icons.music_note_rounded,
      'color': Colors.purple,
      'description': 'Audio tracks and music',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3AMusic',
      'volumeType': 'primary',
    },
    {
      'id': 'dcim',
      'name': 'DCIM (Camera)',
      'icon': Icons.camera_alt_rounded,
      'color': Colors.amber,
      'description': 'Camera photos and screenshots',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADCIM',
      'volumeType': 'primary',
    },
    {
      'id': 'whatsapp',
      'name': 'WhatsApp',
      'icon': Icons.chat_bubble_rounded,
      'color': Colors.teal,
      'description': 'WhatsApp received media files',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia%2Fcom.whatsapp',
      'volumeType': 'primary',
    },
    {
      'id': 'android_media',
      'name': 'Android/media',
      'icon': Icons.perm_media_rounded,
      'color': Colors.indigo,
      'description': 'App media folders',
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia',
      'volumeType': 'primary',
    },
    {
      'id': 'custom',
      'name': 'Choose Custom Folder',
      'icon': Icons.create_new_folder_rounded,
      'color': Colors.deepOrange,
      'description': 'Browse and select any folder',
      'uri': '',
      'volumeType': 'custom',
    },
  ];

  final Map<String, bool> _permissionState = {};
  List<Map<String, dynamic>> _storageVolumes = [];
  bool _loading = true;
  String? _sdCardUuid;

  @override
  void initState() {
    super.initState();
    _loadPickerData();
  }

  Future<void> _loadPickerData() async {
    try {
      _storageVolumes = await AndroidStorage.getStorageVolumes();
      
      // Determine external SD card UUID
      for (final vol in _storageVolumes) {
        if (vol['isPrimary'] == false && vol['uuid'] != 'primary') {
          _sdCardUuid = vol['uuid'] as String?;
          break;
        }
      }

      // Update SD card folder definition if SD card found
      if (_sdCardUuid != null) {
        for (var i = 0; i < _folders.length; i++) {
          if (_folders[i]['id'] == 'sd_card') {
            _folders[i]['uri'] = 'content://com.android.externalstorage.documents/tree/$_sdCardUuid%3A';
          }
        }
      }

      // Check URI permissions
      for (final folder in _folders) {
        final String uri = folder['uri'] as String? ?? '';
        if (uri.isNotEmpty) {
          final hasPerm = await AndroidStorage.isUriPermissionPersisted(uri);
          _permissionState[uri] = hasPerm;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _getStorageStats(String volumeType) {
    if (volumeType == 'custom') return '';
    
    final vol = _storageVolumes.firstWhere(
      (v) => volumeType == 'primary' ? (v['isPrimary'] == true) : (v['isPrimary'] == false),
      orElse: () => {},
    );

    if (vol.isEmpty) return 'Stats unavailable';

    final freeBytes = vol['freeSpace'] as int? ?? 0;
    final totalBytes = vol['totalSpace'] as int? ?? 0;

    final freeGB = (freeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final totalGB = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

    return '$freeGB GB free of $totalGB GB';
  }

  Future<void> _handleFolderSelection(Map<String, dynamic> folder) async {
    final String targetUri = folder['uri'] as String? ?? '';
    
    if (targetUri.isEmpty || folder['volumeType'] == 'custom') {
      // Custom picker
      final result = await AndroidStorage.pickDirectory();
      if (result != null && result['uri'] != null && result['uri']!.isNotEmpty) {
        if (mounted) Navigator.of(context).pop(result['uri']);
      }
      return;
    }

    if (folder['id'] == 'sd_card' && _sdCardUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No external SD Card detected on this device.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final hasPerm = _permissionState[targetUri] ?? false;
    if (hasPerm) {
      Navigator.of(context).pop(targetUri);
      return;
    }

    // Request new permission via SAF
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please tap "Use this folder" and "Allow" to authorize access.'),
        duration: Duration(seconds: 4),
      ),
    );

    final result = await AndroidStorage.pickDirectory(initialUri: targetUri);
    if (result != null && result['uri'] != null && result['uri']!.isNotEmpty) {
      if (mounted) Navigator.of(context).pop(result['uri']);
    }
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return 'Never scanned';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 750 ? 3 : (width > 480 ? 2 : 1);

    // Watch configured folders to map Last Sync
    final foldersAsync = ref.watch(folderManagerProvider);
    final List<BackupFolder> configuredFolders = foldersAsync.value ?? [];

    // Filter SD card option out if no SD card detected
    final displayFolders = _folders.where((f) {
      if (f['id'] == 'sd_card' && _sdCardUuid == null) return false;
      return true;
    }).toList();

    return AlertDialog(
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.android_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Select Android Folder',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a standard or custom path. Storage Access Framework (SAF) persistent permission will be requested.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 480,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.15,
                      ),
                      itemCount: displayFolders.length,
                      itemBuilder: (context, index) {
                        final folder = displayFolders[index];
                        final IconData icon = folder['icon'];
                        final Color color = folder['color'];
                        final String uri = folder['uri'];
                        final String volumeType = folder['volumeType'];

                        // Match configured backup folders
                        BackupFolder? matched;
                        if (uri.isNotEmpty) {
                          for (final f in configuredFolders) {
                            if (f.sourcePath == uri || f.destinationPath == uri) {
                              matched = f;
                              break;
                            }
                          }
                        }

                        final bool isAuthorized = _permissionState[uri] ?? false;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: matched != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: matched != null ? 1.8 : 1,
                            ),
                          ),
                          color: matched != null
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerLow,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _handleFolderSelection(folder),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 24),
                                      ),
                                      if (volumeType != 'custom')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isAuthorized
                                                ? Colors.green.withValues(alpha: 0.12)
                                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isAuthorized ? Icons.check_circle_rounded : Icons.lock_outline,
                                                color: isAuthorized ? Colors.green : theme.colorScheme.outline,
                                                size: 11,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isAuthorized ? 'Authorized' : 'Locked',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAuthorized ? Colors.green : theme.colorScheme.outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    folder['name'],
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    folder['description'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Divider(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          volumeType == 'custom' ? 'Any folder path' : _getStorageStats(volumeType),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 9,
                                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (matched != null)
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final stats = ref.watch(folderStatsProvider(matched!.id)).value;
                                            return Text(
                                              _formatLastSync(stats?.lastScanTime),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
