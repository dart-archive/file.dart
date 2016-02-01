part of file.src.backends.memory;

class _MemoryFile extends _MemoryFileSystemEntity with File {
  _MemoryFile(MemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);
  // Create an object representing a binary file with no data.
  @override
  Object _createImpl() => [];

  @override
  final FileSystemEntityType _type = FileSystemEntityType.FILE;

  @override
  Future<List<int>> readAsBytes() async {
    var dir = _resolve(false);
    if (dir != null) {
      var entity = dir[name] as List<int>;
      if (entity != null) {
        return entity;
      }
    }
    throw new FileSystemEntityException('Not found', path);
  }

  @override
  Future<String> readAsString() async {
    var dir = _resolve(false);
    if (dir != null) {
      var entity = dir[name] as String;
      if (entity != null) {
        return entity;
      }
    }
    throw new FileSystemEntityException('Not found', path);
  }

  @override
  Future<File> writeAsBytes(List<int> contents) {
    _resolve(true)[name] = contents;
    return new Future<File>.value(this);
  }

  @override
  Future<File> writeAsString(String contents) {
    _resolve(true)[name] = contents;
    return new Future<File>.value(this);
  }
}
