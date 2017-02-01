// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.memory;

const String _separator = '/';
const String _thisDir = '.';
const String _parentDir = '..';

/// Visitor callback for use with `_findNode`.
///
/// [parent] is the parent node of the current path segment and is guaranteed
/// to be non-null.
///
/// [childName] is the basename of the entity at the current path segment. It
/// is guaranteed to be non-null.
///
/// [childNode] is the node at the current path segment. It will be
/// non-null only if such an entity exists. The return value of this callback
/// will be used as the value of this node, which allows this callback to
/// do things like recursively create or delete folders.
///
/// [currentSegment] is the index of the current segment within the overall
/// path that's being walked by `_findNode`.
///
/// [finalSegment] is the index of the final segment that will be walked by
/// `_findNode`.
typedef _Node _SegmentVisitor(
  _DirectoryNode parent,
  String childName,
  _Node childNode,
  int currentSegment,
  int finalSegment,
);

/// An implementation of [FileSystem] that exists entirely in memory with an
/// internal representation loosely based on the Filesystem Hierarchy Standard.
/// Notably, this means that this implementation will not look like a Windows
/// file system even if it's being run on a Windows host operating system.
///
/// [MemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
///
/// This implementation of the [FileSystem] interface does not directly use
/// any `dart:io` APIs; it merely uses the library's enum values and deals in
/// the library types. As such, it is suitable for use in the browser as soon
/// as [#28078](https://github.com/dart-lang/sdk/issues/28078) is resolved.
class MemoryFileSystem extends FileSystem {
  _RootNode _root;
  String _systemTemp;
  String _cwd = _separator;

  /// Creates a new `MemoryFileSystem`.
  ///
  /// The file system will be empty, and the current directory will be the
  /// root directory.
  MemoryFileSystem() {
    _root = new _RootNode(this);
  }

  @override
  Directory directory(dynamic path) =>
      new _MemoryDirectory(this, common.getPath(path));

  @override
  File file(dynamic path) => new _MemoryFile(this, common.getPath(path));

  @override
  Link link(dynamic path) => new _MemoryLink(this, common.getPath(path));

  @override
  p.Context get path => new p.Context(style: p.Style.posix, current: _cwd);

  /// Gets the system temp directory. This directory will be created on-demand
  /// in the root of the file system. Once created, its location is fixed for
  /// the life of the process.
  @override
  Directory get systemTempDirectory {
    _systemTemp ??= directory(_separator).createTempSync('.tmp_').path;
    return directory(_systemTemp)..createSync();
  }

  @override
  Directory get currentDirectory => directory(_cwd);

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

    value = directory(value).resolveSymbolicLinksSync();
    _Node node = _findNode(value);
    _checkExists(node, () => value);
    _checkIsDir(node, () => value);
    assert(_isAbsolute(value));
    _cwd = value;
  }

  @override
  Future<io.FileStat> stat(String path) async => statSync(path);

  @override
  io.FileStat statSync(String path) {
    try {
      return _findNode(path)?.stat ?? _MemoryFileStat._notFound;
    } on io.FileSystemException {
      return _MemoryFileStat._notFound;
    }
  }

  @override
  Future<bool> identical(String path1, String path2) async =>
      identicalSync(path1, path2);

  @override
  bool identicalSync(String path1, String path2) {
    _Node node1 = _findNode(path1);
    _checkExists(node1, () => path1);
    _Node node2 = _findNode(path2);
    _checkExists(node2, () => path2);
    return node1 != null && node1 == node2;
  }

  @override
  bool get isWatchSupported => false;

  @override
  Future<io.FileSystemEntityType> type(
    String path, {
    bool followLinks: true,
  }) async =>
      typeSync(path, followLinks: followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks: true}) {
    _Node node;
    try {
      node = _findNode(path, followTailLink: followLinks);
    } on io.FileSystemException {
      node = null;
    }
    if (node == null) {
      return io.FileSystemEntityType.NOT_FOUND;
    }
    return node.type;
  }

  /// Gets the node backing for the current working directory. Note that this
  /// can return null if the directory has been deleted or moved from under our
  /// feet.
  _DirectoryNode get _current => _findNode(_cwd);

  /// Gets the backing node of the entity at the specified path. If the tail
  /// element of the path does not exist, this will return null. If the tail
  /// element cannot be reached because its directory does not exist, a
  /// [io.FileSystemException] will be thrown.
  ///
  /// If [path] is a relative path, it will be resolved relative to
  /// [reference], or the current working directory if [reference] is null.
  /// If [path] is an absolute path, [reference] will be ignored.
  ///
  /// If the last element in [path] represents a symbolic link, this will
  /// return the [_LinkNode] node for the link (it will not return the
  /// node to which the link points), unless [followTailLink] is true.
  /// Directory links in the middle of the path will be followed in order to
  /// find the node regardless of the value of [followTailLink].
  ///
  /// If [segmentVisitor] is specified, it will be invoked for every path
  /// segment visited along the way starting where the reference (root folder
  /// if the path is absolute) is the parent. For each segment, the return value
  /// of [segmentVisitor] will be used as the backing node of that path
  /// segment, thus allowing callers to create nodes on demand in the
  /// specified path. Note that `..` and `.` segments may cause the visitor to
  /// get invoked with the same node multiple times. When [segmentVisitor] is
  /// invoked, for each path segment that resolves to a link node, the visitor
  /// will visit the actual link node if [visitLinks] is true; otherwise it
  /// will visit the target of the link node.
  ///
  /// If [pathWithSymlinks] is specified, the path to the node with symbolic
  /// links explicitly broken out will be appended to the buffer. `..` and `.`
  /// path segments will *not* be resolved and are left to the caller.
  _Node _findNode(
    String path, {
    _Node reference,
    _SegmentVisitor segmentVisitor,
    bool visitLinks: false,
    List<String> pathWithSymlinks,
    bool followTailLink: false,
  }) {
    if (path == null) {
      throw new ArgumentError.notNull('path');
    }

    if (_isAbsolute(path)) {
      reference = _root;
    } else {
      reference ??= _current;
    }

    List<String> parts = path.split(_separator)..removeWhere(_isEmpty);
    _DirectoryNode directory = reference.directory;
    _Node child = directory;

    int finalSegment = parts.length - 1;
    for (int i = 0; i <= finalSegment; i++) {
      String basename = parts[i];
      assert(basename.isNotEmpty);

      switch (basename) {
        case _thisDir:
          child = directory;
          break;
        case _parentDir:
          child = directory.parent;
          directory = directory.parent;
          break;
        default:
          child = directory.children[basename];
      }

      if (pathWithSymlinks != null) {
        pathWithSymlinks.add(basename);
      }

      _PathGenerator subpath = _subpath(parts, 0, i);
      if (_isLink(child) && (i < finalSegment || followTailLink)) {
        if (visitLinks || segmentVisitor == null) {
          if (segmentVisitor != null) {
            child = segmentVisitor(directory, basename, child, i, finalSegment);
          }
          child = _resolveLinks(child, subpath, ledger: pathWithSymlinks);
        } else {
          child = _resolveLinks(
            child,
            subpath,
            ledger: pathWithSymlinks,
            tailVisitor:
                (_DirectoryNode parent, String childName, _Node child) {
              return segmentVisitor(parent, childName, child, i, finalSegment);
            },
          );
        }
      } else if (segmentVisitor != null) {
        child = segmentVisitor(directory, basename, child, i, finalSegment);
      }

      if (i < finalSegment) {
        _checkExists(child, subpath);
        _checkIsDir(child, subpath);
        directory = child;
      }
    }
    return child;
  }
}
