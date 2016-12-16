part of file.src.backends.chroot;

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
/// being provided.
class ChrootFileSystem extends FileSystem {
  final FileSystem delegate;
  final String root;

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
  String get _localRoot => _context.rootPrefix(root);

  @override
  Directory directory(String path) => new _ChrootDirectory(this, path);

  @override
  File file(String path) => new _ChrootFile(this, path);

  @override
  Link link(String path) => new _ChrootLink(this, path);

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

    value = directory(value).absolute.resolveSymbolicLinksSync();
    switch (typeSync(value, followLinks: false)) {
      case FileSystemEntityType.DIRECTORY:
        break;
      case FileSystemEntityType.NOT_FOUND:
        throw new FileSystemException('No such file or directory');
      default:
        throw new FileSystemException('Not a directory');
    }
    assert(p.isAbsolute(value) && value == p.canonicalize(value));
    _cwd = value;
  }

  @override
  Future<FileStat> stat(String path) => delegate.stat(_real(path));

  @override
  FileStat statSync(String path) => delegate.statSync(_real(path));

  @override
  Future<bool> identical(String path1, String path2) =>
      delegate.identical(_real(path1), _real(path2));

  @override
  bool identicalSync(String path1, String path2) =>
      delegate.identicalSync(_real(path1), _real(path2));

  @override
  bool get isWatchSupported => false;

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) =>
      delegate.type(_real(path), followLinks: followLinks);

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks: true}) =>
      delegate.typeSync(_real(path), followLinks: followLinks);

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
  String _real(String localPath) {
    localPath = _context.absolute(localPath);
    return '$root$localPath';
  }
}

/// Exception thrown when a real path is encountered that exists outside of
/// this file system's root.
class _ChrootJailException implements IOException {}
