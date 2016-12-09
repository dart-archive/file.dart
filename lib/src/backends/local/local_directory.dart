part of file.src.backends.local;

class _LocalDirectory extends _LocalFileSystemEntity<
    _LocalDirectory,
    io.Directory> implements Directory {

  _LocalDirectory(FileSystem fileSystem, io.Directory delegate)
      : super(fileSystem, delegate);

  @override
  _LocalDirectory _createNew(io.Directory delegate) =>
      new _LocalDirectory(fileSystem, delegate);

  @override
  Future<Directory> create({bool recursive: false}) async =>
      _createNew(await _delegate.create(recursive: recursive));

  @override
  void createSync({bool recursive: false}) =>
      _delegate.createSync(recursive: recursive);

  @override
  Future<Directory> createTemp([String prefix]) async =>
      _createNew(await _delegate.createTemp(prefix));

  @override
  Directory createTempSync([String prefix]) =>
      _createNew(_delegate.createTempSync(prefix));

  @override
  Stream<FileSystemEntity> list({
    bool recursive: false,
    bool followLinks: true,
  }) => _delegate.list(recursive: recursive, followLinks: followLinks)
      .map(_wrap);

  @override
  List<FileSystemEntity> listSync({
    bool recursive: false,
    bool followLinks: true,
  }) => _delegate.listSync(recursive: recursive, followLinks: followLinks)
      .map((io.FileSystemEntity entity) => _wrap(entity))
      .toList();

  FileSystemEntity _wrap(io.FileSystemEntity entity) {
    if (entity is io.File) {
      return new _LocalFile(fileSystem, entity);
    } else if (entity is io.Directory) {
      return new _LocalDirectory(fileSystem, entity);
    } else if (entity is io.Link) {
      return new _LocalLink(fileSystem, entity);
    }
    throw new io.FileSystemException('Unsupported type: $entity');
  }
}
