part of file.src.backends.chroot;

abstract class _ChrootFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {
  @override
  final ChrootFileSystem fileSystem;

  @override
  final String path;

  _ChrootFileSystemEntity(this.fileSystem, this.path);

  /// Gets the path of this entity in the underlying delegate file system.
  String get _realPath => fileSystem._real(path);

  /// Gets the path of this entity as an absolute path (unchanged if the
  /// entity already specifies an absolute path).
  String get _absolutePath => fileSystem._context.absolute(path);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      new _ChrootDirectory.wrapped(fileSystem, delegate, relative: !isAbsolute);

  @override
  File wrapFile(io.File delegate) =>
      new _ChrootFile.wrapped(fileSystem, delegate, relative: !isAbsolute);

  @override
  Link wrapLink(io.Link delegate) =>
      new _ChrootLink.wrapped(fileSystem, delegate, relative: !isAbsolute);

  @override
  Uri get uri => new Uri.file(path);

  @override
  Future<T> rename(String newPath) async =>
      wrap(await delegate.rename(fileSystem._real(newPath)) as D);

  @override
  T renameSync(String newPath) =>
      wrap(delegate.renameSync(fileSystem._real(newPath)) as D);

  // Note: technically, this could be implemented using underlying async
  // methods, but the implementation is complex enough that having two
  // basically identical implementations seems like a bad idea (the two will
  // diverge if we're not careful).
  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  String resolveSymbolicLinksSync() {
    p.Context context = fileSystem._context;
    List<String> ledger = context.split(fileSystem.root);
    int leading = ledger.length;
    if (!isAbsolute) {
      ledger.addAll(context.split(fileSystem._cwd).sublist(1));
    }

    List<String> segments = context.split(path);
    if (isAbsolute) {
      segments = segments.sublist(1);
    }

    String subpath() => context.joinAll(ledger);
    FileSystemEntityType getType() =>
        fileSystem.delegate.typeSync(subpath(), followLinks: false);

    for (String segment in segments) {
      ledger.add(segment);

      FileSystemEntityType type = getType();
      if (type == FileSystemEntityType.LINK) {
        Set<String> breadcrumbs = new Set<String>();
        while (type == FileSystemEntityType.LINK) {
          String target = fileSystem.delegate.link(subpath()).targetSync();
          if (context.isAbsolute(target)) {
            ledger.clear();
          } else {
            ledger.removeLast();
          }
          ledger.addAll(context.split(target));

          String resolved = context.normalize(subpath());
          if (!breadcrumbs.add(resolved)) {
            throw new FileSystemException('Too many levels of symbolic links');
          }

          if (!resolved.startsWith(fileSystem.root)) {
            // The symlink target leads outside the chroot jail.
            type = FileSystemEntityType.NOT_FOUND;
            break;
          }

          type = getType();
        }
      }

      if (type == FileSystemEntityType.NOT_FOUND) {
        throw new FileSystemException('No such file or directory');
      }
    }

    // Strip the chroot context
    ledger.removeRange(1, leading);

    return context.normalize(context.joinAll(ledger));
  }

  @override
  Stream<FileSystemEvent> watch({
    int events: FileSystemEvent.ALL,
    bool recursive: false,
  }) =>
      throw new UnsupportedError('watch is not supported on ChrootFileSystem');

  @override
  bool get isAbsolute => fileSystem._context.isAbsolute(path);
}
