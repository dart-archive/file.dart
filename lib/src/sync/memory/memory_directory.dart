part of file.src.backends.memory;

class _MemoryDirectory
    extends _MemoryFileSystemEntity
    with SyncDirectory {
  _MemoryDirectory(SyncMemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);
  // Create an object representing a directory with no files.
  @override
  Object _createImpl() => {};

  @override
  List<SyncFileSystemEntity> list({bool recursive: false}) {
    var directory = _resolve(false);
    if (directory == null) {
      throw new FileSystemEntityException('Not found', path);
    }
    if (name != '') {
      directory = directory[name] as Map<String, Object>;
    }
    // This could be optimized heavily, right now it makes a lot of extra
    // lookups and gets more and more expensive as you traverse downwards.
    var result = <SyncFileSystemEntity>[];
    for (var name in directory.keys) {
      var entityPath = '$path/$name';
      if (fileSystem.type(entityPath) == FileSystemEntityType.FILE) {
        result.add(fileSystem.file(entityPath));
      } else {
        result.add(fileSystem.directory(entityPath));
        if (recursive) {
          result.addAll(fileSystem.directory(entityPath).list(recursive: true));
        }
      }
    }
    return result;
  }

  @override
  final FileSystemEntityType _type = FileSystemEntityType.DIRECTORY;
}
