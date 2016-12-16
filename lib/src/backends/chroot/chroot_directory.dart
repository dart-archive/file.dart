part of file.src.backends.chroot;

class _ChrootDirectory extends _ChrootFileSystemEntity<Directory, io.Directory>
    with ForwardingDirectory {
  factory _ChrootDirectory.wrapped(
    ChrootFileSystem fs,
    Directory delegate, {
    bool relative: false,
  }) {
    String localPath = fs._local(delegate.path, relative: relative);
    return new _ChrootDirectory(fs, localPath);
  }

  _ChrootDirectory(ChrootFileSystem fs, String path) : super(fs, path);

  @override
  io.Directory get delegate => fileSystem.delegate.directory(_realPath);

  @override
  Uri get uri => new Uri.directory(path);

  @override
  Directory get absolute => new _ChrootDirectory(fileSystem, _absolutePath);

  @override
  Directory get parent {
    try {
      return wrapDirectory(delegate.parent);
    } on _ChrootJailException {
      return this;
    }
  }
}
