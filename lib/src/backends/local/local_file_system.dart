part of file.src.backends.local;

/// A wrapper implementation around `dart:io`'s implementation.
///
/// Since this implementation of the [FileSystem] interface delegates to
/// `dart:io`, is is not suitable for use in the browser.
class LocalFileSystem extends FileSystem {
  const LocalFileSystem();

  @override
  Directory directory(String path) =>
      new _LocalDirectory(this, new io.Directory(path));

  @override
  File file(String path) => new _LocalFile(this, new io.File(path));

  @override
  Link link(String path) => new _LocalLink(this, new io.Link(path));

  @override
  Directory get currentDirectory => directory(io.Directory.current.path);

  @override
  set currentDirectory(dynamic path) => io.Directory.current = path;

  @override
  Future<io.FileStat> stat(String path) => io.FileStat.stat(path);

  @override
  io.FileStat statSync(String path) => io.FileStat.statSync(path);

  @override
  Future<bool> identical(String path1, String path2) =>
      io.FileSystemEntity.identical(path1, path2);

  @override
  bool identicalSync(String path1, String path2) =>
      io.FileSystemEntity.identicalSync(path1, path2);

  @override
  bool get isWatchSupported => io.FileSystemEntity.isWatchSupported;

  @override
  Future<io.FileSystemEntityType> type(String path, {bool followLinks: true}) =>
      io.FileSystemEntity.type(path, followLinks: followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks: true}) =>
      io.FileSystemEntity.typeSync(path, followLinks: followLinks);
}
