part of file.src.backends.memory;

/// A class that represents the actual storage of an existent file system
/// entity (whereas classes [File], [Directory], and [Link] represent less
/// concrete entities that may or may not yet exist).
///
/// This data structure is loosely based on a Unix-style file system inode
/// (hence the name).
abstract class _Node {
  _DirectoryNode _parent;

  _Node(this._parent) {
    if (_parent == null && !isRoot) {
      throw new io.FileSystemException('All nodes must have a parent.');
    }
  }

  /// Gets the directory that holds this node.
  _DirectoryNode get parent => _parent;

  /// Reparents this node to live in the specified directory.
  set parent(_DirectoryNode parent) {
    assert(parent != null);
    _DirectoryNode ancestor = parent;
    while (!ancestor.isRoot) {
      if (ancestor == this) {
        throw new io.FileSystemException(
            'A directory cannot be its own ancestor.');
      }
      ancestor = ancestor.parent;
    }
    _parent = parent;
  }

  /// Returns the type of the file system entity that this node represents.
  io.FileSystemEntityType get type;

  /// Returns the POSIX stat information for this file system object.
  io.FileStat get stat;

  /// Returns the closest directory in the ancestry hierarchy starting with
  /// this node. For directory nodes, it returns the node itself; for other
  /// nodes, it returns the parent node.
  _DirectoryNode get directory => _parent;

  /// Tells if this node is a root node.
  bool get isRoot => false;

  // Returns the file system responsible for this node.
  MemoryFileSystem get fs => _parent.fs;
}

/// Base class that represents the backing for those nodes that have
/// substance (namely, node types that will not redirect to other types when
/// you call [stat] on them).
abstract class _RealNode extends _Node {
  int changed;
  int modified;
  int accessed;
  int mode = 0x777;

  _RealNode(_DirectoryNode parent) : super(parent) {
    int now = new DateTime.now().millisecondsSinceEpoch;
    changed = now;
    modified = now;
    accessed = now;
  }

  @override
  io.FileStat get stat {
    return new _MemoryFileStat(
      new DateTime.fromMillisecondsSinceEpoch(changed),
      new DateTime.fromMillisecondsSinceEpoch(modified),
      new DateTime.fromMillisecondsSinceEpoch(accessed),
      type,
      mode,
      size,
    );
  }

  /// The size of the file system entity in bytes.
  int get size;
}

/// Class that represents the backing for an in-memory directory.
class _DirectoryNode extends _RealNode {
  final Map<String, _Node> children = <String, _Node>{};

  _DirectoryNode(_DirectoryNode parent) : super(parent);

  @override
  io.FileSystemEntityType get type => io.FileSystemEntityType.DIRECTORY;

  @override
  _DirectoryNode get directory => this;

  @override
  int get size => 0;
}

/// Class that represents the backing for the root of the in-memory file system.
class _RootNode extends _DirectoryNode {
  final MemoryFileSystem _fs;

  _RootNode(this._fs) : super(null) {
    assert(_fs != null);
    assert(_fs._root == null);
  }

  @override
  _DirectoryNode get parent => this;

  @override
  bool get isRoot => true;

  @override
  set parent(_DirectoryNode parent) => throw new UnsupportedError(
      'Cannot set the parent of the root directory.');

  @override
  MemoryFileSystem get fs => _fs;
}

/// Class that represents the backing for an in-memory regular file.
class _FileNode extends _RealNode {
  List<int> content = <int>[];

  _FileNode(_DirectoryNode parent) : super(parent);

  @override
  io.FileSystemEntityType get type => io.FileSystemEntityType.FILE;

  @override
  int get size => content.length;
}

/// Class that represents the backing for an in-memory symbolic link.
class _LinkNode extends _Node {
  String target;
  bool reentrant = false;

  _LinkNode(_DirectoryNode parent, this.target) : super(parent) {
    assert(target != null && target.isNotEmpty);
  }

  /// Gets the node backing for this link's target, or null if this link
  /// references a non-existent file system entity.
  _Node get referent => fs._findNode(target, reference: this);

  @override
  io.FileSystemEntityType get type => io.FileSystemEntityType.LINK;

  @override
  io.FileStat get stat {
    if (reentrant) {
      return _MemoryFileStat._notFound;
    }
    reentrant = true;
    try {
      _Node node = referent;
      return node == null ? _MemoryFileStat._notFound : node.stat;
    } finally {
      reentrant = false;
    }
  }
}
