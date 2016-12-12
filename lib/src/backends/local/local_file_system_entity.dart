part of file.src.backends.local;

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> implements FileSystemEntity {
  @override
  final FileSystem fileSystem;

  final D _delegate;

  _LocalFileSystemEntity(this.fileSystem, this._delegate);

  /// Creates a new entity with the same file system as this entity but backed
  /// by the specified delegate.
  T _createNew(D delegate);

  @override
  Uri get uri => _delegate.uri;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  Future<T> rename(String newPath) async =>
      _createNew(await _delegate.rename(newPath) as D);

  @override
  T renameSync(String newPath) =>
      _createNew(_delegate.renameSync(newPath) as D);

  @override
  Future<String> resolveSymbolicLinks() => _delegate.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => _delegate.resolveSymbolicLinksSync();

  @override
  Future<io.FileStat> stat() => _delegate.stat();

  @override
  io.FileStat statSync() => _delegate.statSync();

  @override
  Future<T> delete({bool recursive: false}) async =>
      _createNew(await _delegate.delete(recursive: recursive) as D);

  @override
  void deleteSync({bool recursive: false}) =>
      _delegate.deleteSync(recursive: recursive);

  @override
  Stream<io.FileSystemEvent> watch({
    int events: io.FileSystemEvent.ALL,
    bool recursive: false,
  }) =>
      _delegate.watch(events: events, recursive: recursive);

  @override
  bool get isAbsolute => _delegate.isAbsolute;

  @override
  T get absolute => _createNew(_delegate.absolute as D);

  @override
  Directory get parent => new _LocalDirectory(fileSystem, _delegate.parent);

  @override
  String get path => _delegate.path;
}
