part of file.src.backends.in_memory;

abstract class _InMemoryFileSystemEntity extends FileSystemEntity {
  @override
  final InMemoryFileSystem fileSystem;

  @override
  final String path;

  _InMemoryFileSystemEntity(this.fileSystem, this.path);

  @override
  Future<FileSystemEntity> create({bool recursive: false}) async {
    var parent = _resolve(recursive);
    if (parent == null) {
      throw new FileSystemEntityException('Not found', getParentPath(path));
    }
    parent.putIfAbsent(name, _createImpl);
    return this;
  }

  /// Override to return a new blank object representing this entity.
  Object _createImpl();

  @override
  Future<FileSystemEntity> delete({bool recursive: false}) async {
    var parent = _resolve(recursive);
    if (parent == null) {
      throw new FileSystemEntityException('Not found', path);
    }
    if (_type == FileSystemEntityType.FILE ||
        recursive ||
        parent[name].isEmpty) {
      parent.remove(name);
      return this;
    }
    throw new FileSystemEntityException(
        'Cannot non-recursively delete a non-empty directory',
        path);
  }

  @override
  Directory get parent {
    var parentPath = getParentPath(path);
    if (parentPath != null) {
      return new _InMemoryDirectory(
          fileSystem,
          parentPath == '' ? '/' : parentPath);
    }
    return null;
  }

  // TODO: Consider promoting to FileSystemEntity.
  String get name => path.substring(path.lastIndexOf('/') + 1);

  Map<String, Object> _resolve(bool recursive) =>
      fileSystem._resolvePath(getParentPath(path).split('/'), recursive: recursive);

  /// Return what this type is.
  FileSystemEntityType get _type;
}
