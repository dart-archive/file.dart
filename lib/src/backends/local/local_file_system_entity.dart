part of file.src.backends.local;

abstract class _LocalFileSystemEntity implements FileSystemEntity {
  @override
  final FileSystem fileSystem;

  io.FileSystemEntity _ioEntity;

  _LocalFileSystemEntity(this._ioEntity, this.fileSystem);

  @override
  Future<FileSystemEntity> delete({bool recursive: false}) async {
    await _ioEntity.delete(recursive: recursive);
    return this;
  }

  @override
  Future<bool> exists() => _ioEntity.exists();

  @override
  Directory get parent => new _LocalDirectory(_ioEntity.parent, fileSystem);

  @override
  String get path => _ioEntity.path;

  @override
  Future<FileSystemEntity> rename(String newPath) async {
    _ioEntity = await _ioEntity.rename(newPath);
    return this;
  }
}
