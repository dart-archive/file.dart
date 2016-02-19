part of file.src.backends.local;

abstract class _LocalFileSystemEntity implements SyncFileSystemEntity {
  @override
  final SyncFileSystem fileSystem;

  io.FileSystemEntity _ioEntity;

  _LocalFileSystemEntity(this._ioEntity, this.fileSystem);

  @override
  SyncFileSystemEntity delete({bool recursive: false}) {
    _ioEntity.deleteSync(recursive: recursive);
    return this;
  }

  @override
  bool exists() => _ioEntity.existsSync();

  @override
  SyncDirectory get parent => new _LocalDirectory(_ioEntity.parent, fileSystem);

  @override
  String get path => _ioEntity.path;

  @override
  SyncFileSystemEntity rename(String newPath) {
    _ioEntity = _ioEntity.renameSync(newPath);
    return this;
  }
}
