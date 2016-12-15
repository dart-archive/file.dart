part of file.src.forwarding;

abstract class ForwardingDirectory
    extends ForwardingFileSystemEntity<Directory, io.Directory>
    implements Directory {
  @override
  ForwardingDirectory wrap(io.Directory delegate) => wrapDirectory(delegate);

  @override
  Future<Directory> create({bool recursive: false}) async =>
      wrap(await delegate.create(recursive: recursive));

  @override
  void createSync({bool recursive: false}) =>
      delegate.createSync(recursive: recursive);

  @override
  Future<Directory> createTemp([String prefix]) async =>
      wrap(await delegate.createTemp(prefix));

  @override
  Directory createTempSync([String prefix]) =>
      wrap(delegate.createTempSync(prefix));

  @override
  Stream<FileSystemEntity> list({
    bool recursive: false,
    bool followLinks: true,
  }) =>
      delegate.list(recursive: recursive, followLinks: followLinks).map(_wrap);

  @override
  List<FileSystemEntity> listSync({
    bool recursive: false,
    bool followLinks: true,
  }) =>
      delegate
          .listSync(recursive: recursive, followLinks: followLinks)
          .map(_wrap)
          .toList();

  FileSystemEntity _wrap(io.FileSystemEntity entity) {
    if (entity is io.File) {
      return wrapFile(entity);
    } else if (entity is io.Directory) {
      return wrapDirectory(entity);
    } else if (entity is io.Link) {
      return wrapLink(entity);
    }
    throw new FileSystemException('Unsupported type: $entity', entity.path);
  }
}
