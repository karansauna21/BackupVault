import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/folder_picker.dart';

class WindowsFolderPickerImpl implements FolderPicker {
  const WindowsFolderPickerImpl();

  @override
  Future<String?> pickFolder(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const WindowsFolderPickerWidget(),
    );
  }
}

class WindowsFolderPickerWidget extends StatefulWidget {
  const WindowsFolderPickerWidget({super.key});

  @override
  State<WindowsFolderPickerWidget> createState() => _WindowsFolderPickerWidgetState();
}

class _WindowsFolderPickerWidgetState extends State<WindowsFolderPickerWidget> {
  late Directory _currentDirectory;
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    try {
      if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE'] ?? 'C:\\';
        _currentDirectory = Directory(home);
      } else {
        final home = Platform.environment['HOME'] ?? '/';
        _currentDirectory = Directory(home);
      }
      await _loadDirectoryContents();
    } catch (_) {
      setState(() {
        _isLoading = false;
        _entities = [];
      });
    }
  }

  Future<void> _loadDirectoryContents() async {
    setState(() => _isLoading = true);
    try {
      final list = await _currentDirectory.list().toList();
      // Filter directories only
      final dirs = list.whereType<Directory>().toList()
        ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
      
      setState(() {
        _entities = dirs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _entities = [];
        _isLoading = false;
      });
    }
  }

  void _navigateUp() {
    final parent = _currentDirectory.parent;
    if (parent.path != _currentDirectory.path) {
      setState(() {
        _currentDirectory = parent;
      });
      _loadDirectoryContents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_open_rounded, color: Colors.amber),
          SizedBox(width: 8),
          Text('Select Folder'),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded),
                  onPressed: _navigateUp,
                  tooltip: 'Up One Level',
                ),
                Expanded(
                  child: Text(
                    _currentDirectory.path,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _entities.isEmpty
                      ? const Center(child: Text('No directories or permission denied'))
                      : ListView.builder(
                          itemCount: _entities.length,
                          itemBuilder: (context, index) {
                            final dir = _entities[index] as Directory;
                            final name = p.basename(dir.path);
                            return ListTile(
                              leading: const Icon(Icons.folder, color: Colors.amber),
                              title: Text(name),
                              onTap: () {
                                setState(() {
                                  _currentDirectory = dir;
                                });
                                _loadDirectoryContents();
                              },
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_currentDirectory.path);
          },
          child: const Text('Select Current'),
        ),
      ],
    );
  }
}
