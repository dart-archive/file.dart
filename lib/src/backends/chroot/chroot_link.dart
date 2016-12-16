part of file.src.backends.chroot;

class _ChrootLink extends _ChrootFileSystemEntity<Link, io.Link>
    with ForwardingLink {
  factory _ChrootLink.wrapped(
    ChrootFileSystem fs,
    io.Link delegate, {
    bool relative: false,
  }) {
    String localPath = fs._local(delegate.path, relative: relative);
    return new _ChrootLink(fs, localPath);
  }

  _ChrootLink(ChrootFileSystem fs, String path) : super(fs, path);

  @override
  io.Link get delegate => fileSystem.delegate.link(_realPath);

  @override
  Future<Link> create(String target, {bool recursive: false}) async {
    if (fileSystem._context.isAbsolute(target)) {
      // Relative targets are left untouched.
      target = fileSystem._real(target);
    }
    return wrap(await delegate.create(target, recursive: recursive));
  }

  @override
  void createSync(String target, {bool recursive: false}) {
    if (fileSystem._context.isAbsolute(target)) {
      // Relative targets are left untouched.
      target = fileSystem._real(target);
    }
    return delegate.createSync(target, recursive: recursive);
  }

  @override
  Future<String> target() async {
    String realTarget = await delegate.target();
    return fileSystem._local(
      realTarget,
      relative: fileSystem._context.isRelative(realTarget),
    );
  }

  @override
  String targetSync() {
    String realTarget = delegate.targetSync();
    return fileSystem._local(
      realTarget,
      relative: fileSystem._context.isRelative(realTarget),
    );
  }

  @override
  Link get absolute => new _ChrootLink(fileSystem, _absolutePath);
}
