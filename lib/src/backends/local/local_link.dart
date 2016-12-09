part of file.src.backends.local;

class _LocalLink extends _LocalFileSystemEntity<Link, io.Link> implements Link {
  _LocalLink(FileSystem fileSystem, io.Link delegate)
      : super(fileSystem, delegate);

  @override
  _LocalLink _createNew(io.Link delegate) =>
      new _LocalLink(fileSystem, delegate);

  @override
  Future<Link> create(String target, {bool recursive: false}) async =>
      _createNew(await _delegate.create(target, recursive: recursive));

  @override
  void createSync(String target, {bool recursive: false}) =>
      _delegate.createSync(target, recursive: recursive);

  @override
  Future<Link> update(String target) async =>
      _createNew(await _delegate.update(target));

  @override
  void updateSync(String target) => _delegate.updateSync(target);

  @override
  Future<String> target() => _delegate.target();

  @override
  String targetSync() => _delegate.targetSync();
}
