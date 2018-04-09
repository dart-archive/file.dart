// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'common.dart';
import 'memory_file_stat.dart';
import 'style.dart';

/// Visitor callback for use with [NodeBasedFileSystem.findNode].
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
/// path that's being walked by [NodeBasedFileSystem.findNode].
///
/// [finalSegment] is the index of the final segment that will be walked by
/// [NodeBasedFileSystem.findNode].
typedef Node SegmentVisitor(
  DirectoryNode parent,
  String childName,
  Node childNode,
  int currentSegment,
  int finalSegment,
);

/// A [FileSystem] whose internal structure is made up of a tree of [Node]
/// instances, rooted at a single node.
abstract class NodeBasedFileSystem implements StyleableFileSystem {
  /// The root node.
  RootNode get root;

  /// The path of the current working directory.
  String get cwd;

  /// Gets the backing node of the entity at the specified path. If the tail
  /// element of the path does not exist, this will return null. If the tail
  /// element cannot be reached because its directory does not exist, a
  /// [io.FileSystemException] will be thrown.
  ///
  /// If [path] is a relative path, it will be resolved relative to
  /// [reference], or the current working directory ([cwd]) if [reference] is
  /// null. If [path] is an absolute path, [reference] will be ignored.
  ///
  /// If the last element in [path] represents a symbolic link, this will
  /// return the [LinkNode] node for the link (it will not return the
  /// node to which the link points), unless [followTailLink] is true.
  /// Directory links in the _middle_ of the path will be followed in order to
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
  Node findNode(
    String path, {
    Node reference,
    SegmentVisitor segmentVisitor,
    bool visitLinks: false,
    List<String> pathWithSymlinks,
    bool followTailLink: false,
  });
}

/// A class that represents the actual storage of an existent file system
/// entity (whereas classes [File], [Directory], and [Link] represent less
/// concrete entities that may or may not yet exist).
///
/// This data structure is loosely based on a Unix-style file system inode
/// (hence the name).
abstract class Node {
  DirectoryNode _parent;

  /// Constructs a new [Node] as a child of the specified parent.
  Node(this._parent) {
    if (_parent == null && !isRoot) {
      throw new io.FileSystemException('All nodes must have a parent.');
    }
  }

  /// Gets the directory that holds this node.
  DirectoryNode get parent => _parent;

  /// Reparents this node to live in the specified directory.
  set parent(DirectoryNode parent) {
    assert(parent != null);
    DirectoryNode ancestor = parent;
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
  DirectoryNode get directory => _parent;

  /// Tells if this node is a root node.
  bool get isRoot => false;

  /// Returns the file system responsible for this node.
  NodeBasedFileSystem get fs => _parent.fs;
}

/// Base class that represents the backing for those nodes that have
/// substance (namely, node types that will not redirect to other types when
/// you call [stat] on them).
abstract class RealNode extends Node {
  /// Last changed time in milliseconds since the Epoch.
  int changed;

  /// Last modified time in milliseconds since the Epoch.
  int modified;

  /// Last accessed time in milliseconds since the Epoch.
  int accessed;

  /// Bitmask representing the file read/write/execute mode.
  int mode = 0x777;

  /// Constructs a new [RealNode] as a child of the specified [parent].
  RealNode(DirectoryNode parent) : super(parent) {
    int now = new DateTime.now().millisecondsSinceEpoch;
    changed = now;
    modified = now;
    accessed = now;
  }

  @override
  io.FileStat get stat {
    return new MemoryFileStat(
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

  /// Updates the last modified time of the node.
  void touch() {
    modified = new DateTime.now().millisecondsSinceEpoch;
  }
}

/// Class that represents the backing for an in-memory directory.
class DirectoryNode extends RealNode {
  /// Child nodes, indexed by their basename.
  final Map<String, Node> children = <String, Node>{};

  /// Constructs a new [DirectoryNode] as a child of the specified [parent].
  DirectoryNode(DirectoryNode parent) : super(parent);

  @override
  io.FileSystemEntityType get type => io.FileSystemEntityType.DIRECTORY;

  @override
  DirectoryNode get directory => this;

  @override
  int get size => 0;
}

/// Class that represents the backing for the root of the in-memory file system.
class RootNode extends DirectoryNode {
  /// Constructs a new [RootNode] tied to the specified file system.
  RootNode(this.fs) : super(null) {
    assert(fs != null);
    assert(fs.root == null);
  }

  @override
  final NodeBasedFileSystem fs;

  @override
  DirectoryNode get parent => this;

  @override
  bool get isRoot => true;

  @override
  set parent(DirectoryNode parent) => throw new UnsupportedError(
      'Cannot set the parent of the root directory.');
}

/// Class that represents the backing for an in-memory regular file.
class FileNode extends RealNode {
  /// File contents in bytes.
  List<int> content = <int>[];

  /// Constructs a new [FileNode] as a child of the specified [parent].
  FileNode(DirectoryNode parent) : super(parent);

  @override
  io.FileSystemEntityType get type => io.FileSystemEntityType.FILE;

  @override
  int get size => content.length;

  /// Copies data from [source] into this node. The [modified] and [changed]
  /// fields will be reset as opposed to copied to indicate that this file
  /// has been modified and changed.
  void copyFrom(FileNode source) {
    modified = changed = new DateTime.now().millisecondsSinceEpoch;
    accessed = source.accessed;
    mode = source.mode;
    content = new List<int>.from(source.content);
  }
}

/// Class that represents the backing for an in-memory symbolic link.
class LinkNode extends Node {
  /// The path to which this link points.
  String target;

  /// A marker used to detect circular link references.
  bool _reentrant = false;

  /// Constructs a new [LinkNode] as a child of the specified [parent] and
  /// linking to the specified [target] path.
  LinkNode(DirectoryNode parent, this.target) : super(parent) {
    assert(target != null && target.isNotEmpty);
  }

  /// Gets the node backing for this link's target. Throws a
  /// [FileSystemException] if this link references a non-existent file
  /// system entity.
  ///
  /// If [tailVisitor] is specified, it will be invoked for the tail path
  /// segment of this link's target, and its return value will be used as the
  /// return value of this method. If the tail path segment of this link's
  /// target cannot be traversed into, a [FileSystemException] will be thrown,
  /// and [tailVisitor] will not be invoked.
  Node getReferent({
    Node tailVisitor(DirectoryNode parent, String childName, Node child),
  }) {
    Node referent = fs.findNode(
      target,
      reference: this,
      segmentVisitor: (
        DirectoryNode parent,
        String childName,
        Node child,
        int currentSegment,
        int finalSegment,
      ) {
        if (tailVisitor != null && currentSegment == finalSegment) {
          child = tailVisitor(parent, childName, child);
        }
        return child;
      },
    );
    checkExists(referent, () => target);
    return referent;
  }

  /// Gets the node backing for this link's target, or null if this link
  /// references a non-existent file system entity.
  Node get referentOrNull {
    try {
      return getReferent();
    } on io.FileSystemException {
      return null;
    }
  }

  @override
  io.FileSystemEntityType get type => io.FileSystemEntityType.LINK;

  @override
  io.FileStat get stat {
    if (_reentrant) {
      return MemoryFileStat.notFound;
    }
    _reentrant = true;
    try {
      Node node = referentOrNull;
      return node == null ? MemoryFileStat.notFound : node.stat;
    } finally {
      _reentrant = false;
    }
  }
}
