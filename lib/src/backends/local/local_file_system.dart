part of file.src.backends.local;

/// A wrapper implementation around `dart:io`'s implementation.
class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  Directory directory(String path) => new _LocalDirectory(new io.Directory(path), this);

  @override
  File file(String path) => new _LocalFile(new io.File(path), this);

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) async {
    var type = await io.FileSystemEntity.type(path);
    if (type == io.FileSystemEntityType.FILE) {
      return FileSystemEntityType.FILE;
    } else if (type == io.FileSystemEntityType.DIRECTORY) {
      return FileSystemEntityType.DIRECTORY;
    } else {
      return FileSystemEntityType.NOT_FOUND;
    }
  }
}
