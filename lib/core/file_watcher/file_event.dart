enum FileEventType {
  newFile,
  modifiedFile,
  renamedFile,
  deletedFile,
  movedFile,
  copiedFile,
  folderCreated,
  folderDeleted,
  folderRenamed,
  folderMoved
}

class FileEvent {
  final int folderId;
  final FileEventType type;
  final String path;
  final String? destinationPath; // For moves/renames
  final DateTime timestamp;
  final bool isDir;

  FileEvent({
    required this.folderId,
    required this.type,
    required this.path,
    this.destinationPath,
    required this.timestamp,
    required this.isDir,
  });

  @override
  String toString() {
    return 'FileEvent(folderId: $folderId, type: $type, path: $path, dest: $destinationPath, time: $timestamp, isDir: $isDir)';
  }
}
