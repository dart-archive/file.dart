part of file.src.backends.memory;

abstract class _MemoryFileSystemEntity extends SyncFileSystemEntity {
  @override
  final SyncMemoryFileSystem fileSystem;

  @override
  final String path;

  _MemoryFileSystemEntity(this.fileSystem, this.path);

  @override
  SyncFileSystemEntity copy(String newPath) {
    if (fileSystem.type(newPath) != FileSystemEntityType.NOT_FOUND) {
      throw new FileSystemEntityException(
          'Unable to copy or move to an existing path',
          newPath);
    }
    var parent = _resolve(false);
    if (parent != null) {
      var reference = _resolve(true, newPath);
      Object clone = parent[name];
      if (clone is! String) {
        clone = cloneSafe(clone as Map<String, Object>);
      }
      reference[newPath.substring(newPath.lastIndexOf('/') + 1)] = clone;
      if (_type == FileSystemEntityType.FILE) {
        return new _MemoryFile(fileSystem, newPath);
      } else {
        return new _MemoryDirectory(fileSystem, newPath);
      }
    }
    throw new FileSystemEntityException('Not found', path);
  }

  @override
  SyncFileSystemEntity create({bool recursive: false}) {
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
  SyncFileSystemEntity delete({bool recursive: false}) {
    var parent = _resolve(recursive);
    if (parent == null) {
      throw new FileSystemEntityException('Not found', path);
    }
    if (_type == FileSystemEntityType.FILE ||
        recursive ||
        (parent[name] as Map).isEmpty) {
      parent.remove(name);
      return this;
    }
    throw new FileSystemEntityException(
        'Cannot non-recursively delete a non-empty directory',
        path);
  }

  @override
  SyncDirectory get parent {
    var parentPath = getParentPath(path);
    if (parentPath != null) {
      return new _MemoryDirectory(
          fileSystem,
          parentPath == '' ? '/' : parentPath);
    }
    return null;
  }

  // TODO: Consider promoting to SyncFileSystemEntity.
  String get name => path.substring(path.lastIndexOf('/') + 1);

  @override
  SyncFileSystemEntity rename(String newPath) {
    var copied = copy(newPath);
    delete(recursive: true);
    return copied;
  }

  Map<String, Object> _resolve(bool recursive, [String path]) {
    path ??= this.path;
    if (path == '') {
      return fileSystem._data;
    }
    return resolvePath(fileSystem._data, getParentPath(path).split('/'),
        recursive: recursive);
  }

  /// Return what this type is.
  FileSystemEntityType get _type;
}
