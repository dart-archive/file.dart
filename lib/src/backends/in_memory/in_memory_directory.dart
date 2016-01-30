part of file.src.backends.in_memory;

class _InMemoryDirectory
    extends _InMemoryFileSystemEntity
    with Directory {
  _InMemoryDirectory(InMemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);
  // Create an object representing a directory with no files.
  @override
  Object _createImpl() => {};

  @override
  Stream<FileSystemEntity> list({bool recursive: false}) async* {
    var directory = _resolve(false);
    if (directory == null) {
      throw new FileSystemEntityException('Not found', path);
    }
    if (name != '') {
      directory = directory[name] as Map<String, Object>;
    }
    // This could be optimized heavily, right now it makes a lot of extra
    // lookups and gets more and more expensive as you traverse downwards.
    for (var name in directory.keys) {
      var entityPath = '$path/$name';
      if (await fileSystem.type(entityPath) == FileSystemEntityType.FILE) {
        yield fileSystem.file(entityPath);
      } else if (recursive) {
        yield* fileSystem.directory(entityPath).list(recursive: true);
      } else {
        yield fileSystem.directory(entityPath);
      }
    }
  }

  @override
  final FileSystemEntityType _type = FileSystemEntityType.DIRECTORY;
}
