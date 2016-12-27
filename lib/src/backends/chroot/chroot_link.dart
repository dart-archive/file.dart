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
  Future<Link> create(String target, {bool recursive: false}) async =>
      wrap(await delegate.create(_realTarget(target), recursive: recursive));

  @override
  void createSync(String target, {bool recursive: false}) =>
      delegate.createSync(_realTarget(target), recursive: recursive);

  @override
  Future<Link> update(String target) async =>
      wrap(await delegate.update(_realTarget(target)));

  @override
  void updateSync(String target) => delegate.updateSync(_realTarget(target));

  @override
  Future<String> target() async => _localTarget(await delegate.target());

  @override
  String targetSync() => _localTarget(delegate.targetSync());

  @override
  Link get absolute => new _ChrootLink(fileSystem, _absolutePath);

  /// Converts a local symlink target to a real target in the underlying file
  /// system. Relative targets are relative to the location of the symbolic
  /// link, so they are left untouched, whereas absolute tagets are converted
  /// to their true absolute location in the underlying file system.
  String _realTarget(String localTarget) {
    return fileSystem._context.isRelative(localTarget)
        ? localTarget
        : fileSystem._real(localTarget);
  }

  /// Converts a real symbolic link target in the underlying file system to a
  /// local target. Relative targets are relative to the location of the
  /// symbolic link, so they are left untouched, whereas absolute tagets are
  /// converted from their real path to their path in this file system.
  String _localTarget(String realTarget) {
    return fileSystem._context.isRelative(realTarget)
        ? realTarget
        : fileSystem._local(realTarget);
  }
}
