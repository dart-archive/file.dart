part of file.src.backends.local;

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {
  @override
  final FileSystem fileSystem;

  @override
  final D delegate;

  _LocalFileSystemEntity(this.fileSystem, this.delegate);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      new _LocalDirectory(fileSystem, delegate);

  @override
  File wrapFile(io.File delegate) => new _LocalFile(fileSystem, delegate);

  @override
  Link wrapLink(io.Link delegate) => new _LocalLink(fileSystem, delegate);
}
