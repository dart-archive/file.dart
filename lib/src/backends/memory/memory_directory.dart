// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.memory;

class _MemoryDirectory extends _MemoryFileSystemEntity implements Directory {
  static int _tempCounter = 0;

  _MemoryDirectory(MemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.DIRECTORY;

  @override
  Uri get uri => new Uri.directory(path);

  @override
  bool existsSync() => _backingOrNull?.stat?.type == expectedType;

  @override
  Future<Directory> create({bool recursive: false}) async {
    createSync(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive: false}) {
    _Node node = _createSync(
      followTailLink: true,
      visitLinks: true,
      createChild: (_DirectoryNode parent, bool isFinalSegment) {
        if (recursive || isFinalSegment) {
          return new _DirectoryNode(parent);
        }
        return null;
      },
    );
    if (node.type != expectedType) {
      // There was an existing non-directory node at this object's path
      String msg = 'File exists';
      throw new io.FileSystemException(
          msg, path, new OSError(msg, ErrorCodes.ENOTDIR));
    }
  }

  @override
  Future<Directory> createTemp([String prefix]) async => createTempSync(prefix);

  @override
  Directory createTempSync([String prefix]) {
    prefix = (prefix ?? '') + 'rand';
    String fullPath = fileSystem.path.join(path, prefix);
    String dirname = fileSystem.path.dirname(fullPath);
    String basename = fileSystem.path.basename(fullPath);
    _DirectoryNode node = fileSystem._findNode(dirname);
    _checkExists(node, () => dirname);
    _checkIsDir(node, () => dirname);
    String name() => '$basename$_tempCounter';
    while (node.children.containsKey(name())) {
      _tempCounter++;
    }
    _DirectoryNode tempDir = new _DirectoryNode(node);
    node.children[name()] = tempDir;
    return new _MemoryDirectory(
        fileSystem, fileSystem.path.join(dirname, name()));
  }

  @override
  Future<Directory> rename(String newPath) async => renameSync(newPath);

  @override
  Directory renameSync(String newPath) => _renameSync(
        newPath,
        validateOverwriteExistingEntity: (_DirectoryNode existingNode) {
          if (existingNode.children.isNotEmpty) {
            String msg = 'Directory not empty';
            throw new io.FileSystemException(
                msg, newPath, new OSError(msg, ErrorCodes.ENOTEMPTY));
          }
        },
      );

  @override
  Directory get parent =>
      (_backingOrNull?.isRoot ?? false) ? this : super.parent;

  @override
  Directory get absolute => super.absolute;

  @override
  Stream<FileSystemEntity> list({
    bool recursive: false,
    bool followLinks: true,
  }) =>
      new Stream<FileSystemEntity>.fromIterable(listSync(
        recursive: recursive,
        followLinks: followLinks,
      ));

  @override
  List<FileSystemEntity> listSync({
    bool recursive: false,
    bool followLinks: true,
  }) {
    _DirectoryNode node = _backing;
    List<FileSystemEntity> listing = <FileSystemEntity>[];
    List<_PendingListTask> tasks = <_PendingListTask>[
      new _PendingListTask(
        node,
        path.endsWith(_separator) ? path.substring(0, path.length - 1) : path,
        new Set<_LinkNode>(),
      ),
    ];
    while (tasks.isNotEmpty) {
      _PendingListTask task = tasks.removeLast();
      task.dir.children.forEach((String name, _Node child) {
        Set<_LinkNode> breadcrumbs = new Set<_LinkNode>.from(task.breadcrumbs);
        String childPath = fileSystem.path.join(task.path, name);
        while (followLinks && _isLink(child) && breadcrumbs.add(child)) {
          _Node referent = (child as _LinkNode).referentOrNull;
          if (referent != null) {
            child = referent;
          }
        }
        if (_isDirectory(child)) {
          listing.add(new _MemoryDirectory(fileSystem, childPath));
          if (recursive) {
            tasks.add(new _PendingListTask(child, childPath, breadcrumbs));
          }
        } else if (_isLink(child)) {
          listing.add(new _MemoryLink(fileSystem, childPath));
        } else if (_isFile(child)) {
          listing.add(new _MemoryFile(fileSystem, childPath));
        }
      });
    }
    return listing;
  }

  @override
  Directory _clone(String path) => new _MemoryDirectory(fileSystem, path);

  @override
  String toString() => "MemoryDirectory: '$path'";
}

class _PendingListTask {
  final _DirectoryNode dir;
  final String path;
  final Set<_LinkNode> breadcrumbs;
  _PendingListTask(this.dir, this.path, this.breadcrumbs);
}
