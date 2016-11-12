part of file.src.backends.local;

class _LocalDirectory extends _LocalFileSystemEntity implements Directory {
  _LocalDirectory(io.Directory entity, FileSystem system)
      : super(entity, system);

  @override
  Future<Directory> copy(String newPath) async {
    throw new UnsupportedError('Not a supported operation');
  }

  @override
  Future<Directory> create({bool recursive: false}) async {
    return new _LocalDirectory(
        await (_ioEntity as io.Directory).create(recursive: recursive),
        fileSystem);
  }

  @override
  Stream<FileSystemEntity> list({bool recursive: false}) {
    io.Directory directory = _ioEntity;
    return directory.list(recursive: recursive).map((entity) {
      if (entity is io.File) {
        return new _LocalFile(entity, fileSystem);
      }
      if (entity is io.Directory) {
        return new _LocalDirectory(entity, fileSystem);
      }
      return null;
    }).where((e) => e != null);
  }
}
