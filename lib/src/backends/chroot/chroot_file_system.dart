part of file.src.backends.chroot;

const String _thisDir = '.';
const String _parentDir = '..';

/// A file system implementation that provides a view onto another file
/// system, taking a path in the underlying file system, and making that the
/// apparent root of the new file system. This is similar in concept to a
/// `chroot` operation on Linux operating systems. Such a modified file system
/// cannot name (and therefore normally cannot access) files outside the
/// designated directory tree.
///
/// This file system maintains its own [currentDirectory], distinct from that
/// of the underlying file system. This means that setting the current directory
/// of this file system will have no bearing on the current directory of the
/// underlying file system, and vice versa. When new instances of this file
/// system are created, their current directory is initialized to `/` (the root
/// of this file system).
///
/// Note that the implementation of this file system does *not* leverage any
/// underlying OS system calls (such as `chroot`), so the developer needs to
/// take care to not assume any more of a secure environment than is actually
/// being provided. Notably, users of this file system have direct access to
/// the underlying file system via the [delegate] property, which underscores
/// the fact that this file system is intended as a convenient abstraction,
/// not as a sucurity measure.
///
/// Also note that this file system *necessarily* carries a certain performance
/// overhead. This is due to the fact that symbolic links must be resolved
/// manually by this file system (link resolution may not be delegated to the
/// underlying file system). Thus, all paths must be walked to check for
/// symbolic links at every element of the path.
class ChrootFileSystem extends FileSystem {
  final FileSystem delegate;
  final String root;

  String _systemTemp;
  String _cwd;

  /// Creates a new `ChrootFileSystem` backed by the specified [delegate] file
  /// system, but making [root] the apparent root of the new file system.
  ///
  /// [root] must be a canonicalized path, or an [ArgumentError] will be thrown.
  ChrootFileSystem(this.delegate, this.root) {
    if (root != p.canonicalize(root)) {
      throw new ArgumentError.value(root, 'root', 'Must be canonical path');
    }
    _cwd = _localRoot;
  }

  /// Gets the path context for this file system given the current working dir.
  p.Context get _context => new p.Context(current: _cwd);

  /// Gets the root path, as seen by entities in this file system.
  String get _localRoot => p.rootPrefix(root);

  @override
  Directory directory(path) => new _ChrootDirectory(this, common.getPath(path));

  @override
  File file(path) => new _ChrootFile(this, common.getPath(path));

  @override
  Link link(path) => new _ChrootLink(this, common.getPath(path));

  @override
  String get pathSeparator => delegate.pathSeparator;

  /// Gets the system temp directory. This directory will be created on-demand
  /// in the local root of the file system. Once created, its location is fixed
  /// for the life of the process.
  @override
  Directory get systemTempDirectory {
    _systemTemp ??= directory(_localRoot).createTempSync('.tmp_').path;
    return directory(_systemTemp)..createSync();
  }

  /// Gets the current working directory for this file system. Note that this
  /// does *not* proxy to the underlying file system's current directory in
  /// any way; the state of this file system's current directory is local to
  /// this file system.
  @override
  Directory get currentDirectory => directory(_cwd);

  /// Sets the current working directory for this file system. Note that this
  /// does *not* proxy to the underlying file system's current directory in
  /// any way; the state of this file system's current directory is local to
  /// this file system.
  @override
  set currentDirectory(dynamic path) {
    String value;
    if (path is io.Directory) {
      value = path.path;
    } else if (path is String) {
      value = path;
    } else {
      throw new ArgumentError('Invalid type for "path": ${path?.runtimeType}');
    }

    value = _resolve(value, notFound: _NotFoundBehavior.THROW);
    String realPath = _real(value, resolve: false);
    switch (delegate.typeSync(realPath, followLinks: false)) {
      case FileSystemEntityType.DIRECTORY:
        break;
      case FileSystemEntityType.NOT_FOUND:
        throw new FileSystemException('No such file or directory');
      default:
        throw new FileSystemException('Not a directory');
    }
    assert(() => p.isAbsolute(value) && value == p.canonicalize(value));
    _cwd = value;
  }

  @override
  Future<FileStat> stat(String path) {
    try {
      path = _resolve(path);
    } on FileSystemException {
      return new Future.value(const _NotFoundFileStat());
    }
    return delegate.stat(_real(path, resolve: false));
  }

  @override
  FileStat statSync(String path) {
    try {
      path = _resolve(path);
    } on FileSystemException {
      return const _NotFoundFileStat();
    }
    return delegate.statSync(_real(path, resolve: false));
  }

  @override
  Future<bool> identical(String path1, String path2) => delegate.identical(
        _real(_resolve(path1, followLinks: false)),
        _real(_resolve(path2, followLinks: false)),
      );

  @override
  bool identicalSync(String path1, String path2) => delegate.identicalSync(
        _real(_resolve(path1, followLinks: false)),
        _real(_resolve(path2, followLinks: false)),
      );

  @override
  bool get isWatchSupported => false;

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) {
    String realPath;
    try {
      realPath = _real(path, followLinks: followLinks);
    } on FileSystemException {
      return new Future.value(FileSystemEntityType.NOT_FOUND);
    }
    return delegate.type(realPath, followLinks: false);
  }

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks: true}) {
    String realPath;
    try {
      realPath = _real(path, followLinks: followLinks);
    } on FileSystemException {
      return FileSystemEntityType.NOT_FOUND;
    }
    return delegate.typeSync(realPath, followLinks: false);
  }

  /// Converts a path in the underlying delegate file system to a local path
  /// in this file system. If [relative] is true, then the resulting
  /// path will be relative to [currentDirectory]; otherwise the resulting
  /// path will be absolute.
  ///
  /// If [realPath] represents a path outside of this file system's root, a
  /// [_ChrootJailException] will be thrown, unless [keepInJail] is true, in
  /// which case this will return the path of the root of this file system.
  String _local(String realPath, {relative: false, keepInJail: false}) {
    assert(_context.isAbsolute(realPath));
    if (!realPath.startsWith(root)) {
      if (keepInJail) {
        return _localRoot;
      }
      throw new _ChrootJailException();
    }
    // TODO: See if _context.relative() works here
    String result = realPath.substring(root.length);
    if (result.isEmpty) {
      result = _localRoot;
    }
    if (relative) {
      assert(result.startsWith(_cwd));
      result = _context.relative(result, from: _cwd);
    }
    return result;
  }

  /// Converts a local path in this file system to the underlying path in the
  /// delegate file system. The returned path will always be absolute.
  ///
  /// If [resolve] is true, symbolic links will be resolved in the local file
  /// system before converting the path to the delegate file system's namespace.
  /// This ensures that symbolic link resolution will work as intended. When
  /// [resolve] is true, if the tail element of the path is a symbolic link,
  /// it will only be resolved if [followLinks] is true (whereas symbolic links
  /// found in the middle of the path will always be resolved).
  String _real(
    String localPath, {
    bool resolve: true,
    bool followLinks: false,
  }) {
    if (resolve) {
      localPath = _resolve(localPath, followLinks: followLinks);
    } else {
      assert(() => _context.isAbsolute(localPath));
    }
    return '$root$localPath';
  }

  /// Resolves symbolic links on [path] and returns the resulting resolved
  /// path. The return value will always be an absolute path; if [path] is
  /// relative, it will be interpreted relative to [from] (or
  /// [currentDirectory] if [from] is null).
  ///
  /// If the tail element is a symbolic link, then the link will be resolved
  /// only if [followLinks] is true. Symbolic links found in the middle of the
  /// path will always be resolved.
  ///
  /// If [throwIfNotFound] is true and the path cannot be resolved to a valid
  /// file system entity, a [FileSystemException] will be thrown. If
  /// [throwIfNotFound] is false, then resolution will halt as soon as a
  /// non-existent path segment is encountered, and the partially resolved path
  /// will be returned.
  String _resolve(
    String path, {
    String from,
    bool followLinks: true,
    _NotFoundBehavior notFound: _NotFoundBehavior.ALLOW,
  }) {
    p.Context ctx = _context;
    String root = _localRoot;
    List<String> parts, ledger;
    if (ctx.isAbsolute(path)) {
      parts = ctx.split(path).sublist(1);
      ledger = <String>[];
    } else {
      from ??= _cwd;
      assert(ctx.isAbsolute(from));
      parts = ctx.split(path);
      ledger = ctx.split(from).sublist(1);
    }

    String getCurrentPath() => root + ctx.joinAll(ledger);
    Set<String> breadcrumbs = new Set<String>();
    while (parts.isNotEmpty) {
      String segment = parts.removeAt(0);
      if (segment == _thisDir) {
        continue;
      } else if (segment == _parentDir) {
        if (ledger.isNotEmpty) {
          ledger.removeLast();
        }
        continue;
      }

      ledger.add(segment);
      String currentPath = getCurrentPath();
      String realPath = _real(currentPath, resolve: false);

      switch (delegate.typeSync(realPath, followLinks: false)) {
        case FileSystemEntityType.DIRECTORY:
          breadcrumbs.clear();
          break;
        case FileSystemEntityType.FILE:
          breadcrumbs.clear();
          if (parts.isNotEmpty) {
            throw new FileSystemException('Not a directory', currentPath);
          }
          break;
        case FileSystemEntityType.NOT_FOUND:
          String returnEarly() {
            ledger.addAll(parts);
            return getCurrentPath();
          }

          FileSystemException notFoundException() {
            return new FileSystemException('No such file or directory', path);
          }

          switch (notFound) {
            case _NotFoundBehavior.MKDIR:
              if (parts.isNotEmpty) {
                delegate.directory(realPath).createSync();
              }
              break;
            case _NotFoundBehavior.ALLOW:
              return returnEarly();
            case _NotFoundBehavior.ALLOW_AT_TAIL:
              if (parts.isEmpty) {
                return returnEarly();
              }
              throw notFoundException();
            case _NotFoundBehavior.THROW:
              throw notFoundException();
          }
          break;
        case FileSystemEntityType.LINK:
          if (parts.isEmpty && !followLinks) {
            break;
          }
          if (!breadcrumbs.add(currentPath)) {
            throw new FileSystemException(
                'Too many levels of symbolic links', path);
          }
          String target = delegate.link(realPath).targetSync();
          if (ctx.isAbsolute(target)) {
            ledger.clear();
            parts.insertAll(0, ctx.split(target).sublist(1));
          } else {
            ledger.removeLast();
            parts.insertAll(0, ctx.split(target));
          }
          break;
        default:
          throw new AssertionError();
      }
    }

    return getCurrentPath();
  }
}

/// Exception thrown when a real path is encountered that exists outside of
/// this file system's root.
class _ChrootJailException implements IOException {}

/// Enum specifying the behavior to exhibit when ancountering `NOT_FOUND` paths
/// in [_resolve].
enum _NotFoundBehavior {
  ALLOW,
  ALLOW_AT_TAIL,
  THROW,
  MKDIR,
}

/// File stat representing a not found entity.
class _NotFoundFileStat implements FileStat {
  const _NotFoundFileStat();
  @override
  DateTime get changed => null;
  @override
  DateTime get modified => null;
  @override
  DateTime get accessed => null;
  @override
  FileSystemEntityType get type => FileSystemEntityType.NOT_FOUND;
  @override
  int get mode => 0;
  @override
  int get size => -1;
  @override
  String modeString() => '---------';
}
