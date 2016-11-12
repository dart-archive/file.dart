part of file.src.backends.local;

/// A wrapper implementation around `dart:io`'s implementation.
class SyncLocalFileSystem implements SyncFileSystem {
  const SyncLocalFileSystem();

  @override
  SyncDirectory directory(String path) =>
      new _LocalDirectory(new io.Directory(path), this);

  @override
  SyncFile file(String path) => new _LocalFile(new io.File(path), this);

  @override
  FileSystemEntityType type(String path, {bool followLinks: true}) {
    var type = io.FileSystemEntity.typeSync(path);
    if (type == io.FileSystemEntityType.FILE) {
      return FileSystemEntityType.FILE;
    } else if (type == io.FileSystemEntityType.DIRECTORY) {
      return FileSystemEntityType.DIRECTORY;
    } else {
      return FileSystemEntityType.NOT_FOUND;
    }
  }
}
