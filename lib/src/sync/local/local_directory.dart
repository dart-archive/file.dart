part of file.src.backends.local;

class _LocalDirectory extends _LocalFileSystemEntity implements SyncDirectory {
  _LocalDirectory(io.Directory entity, SyncFileSystem system) : super(entity, system);

  @override
  SyncDirectory copy(String newPath) {
    throw new UnsupportedError('Not a supported operation');
  }

  @override
  SyncDirectory create({bool recursive: false}) {
    (_ioEntity as io.Directory).createSync(recursive: recursive);
    return this;
  }

  @override
  List<SyncFileSystemEntity> list({bool recursive: false}) {
    return (_ioEntity as io.Directory)
        .listSync(recursive: recursive)
        .map((ioEntity) {
      if (ioEntity is io.File) {
        return new _LocalFile(ioEntity, fileSystem);
      }
      if (ioEntity is io.Directory) {
        return new _LocalDirectory(ioEntity, fileSystem);
      }
      return null;
    }).where((e) => e != null) as List<SyncFileSystemEntity>;
  }
}
