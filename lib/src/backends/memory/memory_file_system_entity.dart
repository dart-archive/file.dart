part of file.src.backends.memory;

/// Validator function for use with [_renameSync]. This will be invoked if the
/// rename would overwrite an existing entity at the new path. If this operation
/// should not be allowed, this function is expected to throw a
/// [io.FileSystemException]. The lack of such an exception will be interpreted
/// as the overwrite being permissible.
typedef void _RenameOverwriteValidator<T extends _Node>(T existingNode);

/// Base class for all in-memory file system entity types.
abstract class _MemoryFileSystemEntity implements FileSystemEntity {
  @override
  final MemoryFileSystem fileSystem;

  @override
  final String path;

  _MemoryFileSystemEntity(this.fileSystem, this.path);

  /// Gets the part of this entity's path before the last separator.
  String get dirname => fileSystem._context.dirname(path);

  /// Gets the part of this entity's path after the last separator.
  String get basename => fileSystem._context.basename(path);

  /// Returns the expected type of this entity, which may differ from the type
  /// of the node that's found at the path specified by this entity.
  io.FileSystemEntityType get expectedType;

  /// Gets the node that backs this file system entity, or null if this
  /// entity does not exist.
  _Node get backingOrNull {
    try {
      return fileSystem._findNode(path);
    } on io.FileSystemException {
      return null;
    }
  }

  /// Gets the node that backs this file system entity. Throws a
  /// [io.FileSystemException] if this entity doesn't exist.
  ///
  /// The type of the node is not guaranteed to match [expectedType].
  _Node get backing {
    _Node node = fileSystem._findNode(path);
    _checkExists(node, () => path);
    return node;
  }

  @override
  Uri get uri => new Uri.file(path);

  @override
  Future<bool> exists() async => existsSync();

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  String resolveSymbolicLinksSync() {
    StringBuffer ledger = new StringBuffer();
    _Node node = fileSystem._findNode(path, pathWithSymlinks: ledger);
    if (_isLink(node)) {
      _resolveLinks(node, () => path, ledger: ledger);
    }
    String resolved = ledger.toString();
    if (!isAbsolute) {
      resolved = fileSystem._cwd + resolved;
    }
    return fileSystem._context.normalize(resolved);
  }

  @override
  Future<io.FileStat> stat() => fileSystem.stat(path);

  @override
  io.FileStat statSync() => fileSystem.statSync(path);

  @override
  Future<FileSystemEntity> delete({bool recursive: false}) async {
    deleteSync(recursive: recursive);
    return this;
  }

  @override
  void deleteSync({bool recursive: false}) {
    _Node node = backing;
    if (!recursive) {
      if (node is _DirectoryNode && node.children.isNotEmpty) {
        throw new io.FileSystemException('Directory not empty', path);
      }
      if (node.type != expectedType) {
        throw new io.FileSystemException(
            'Not a ${expectedType.toString().toLowerCase()}', path);
      }
    }
    // Once we remove this reference, the node and all its children will be
    // garbage collected; we don't need to explicitly delete all children in
    // the recursive:true case.
    node.parent.children.remove(basename);
  }

  @override
  Stream<io.FileSystemEvent> watch({
    int events: io.FileSystemEvent.ALL,
    bool recursive: false,
  }) =>
      throw new UnsupportedError('Watching not supported in MemoryFileSystem');

  @override
  bool get isAbsolute => _isAbsolute(path);

  @override
  FileSystemEntity get absolute {
    String absolutePath = path;
    if (!_isAbsolute(absolutePath)) {
      absolutePath = '${fileSystem._cwd}$_separator$absolutePath';
    }
    return _clone(absolutePath);
  }

  @override
  Directory get parent => new _MemoryDirectory(fileSystem, dirname);

  /// Helper method for subclasses wishing to synchronously create this entity.
  /// This method will traverse the path to this entity one segment at a time,
  /// calling [createChild] for each segment whose child does not already exist.
  ///
  /// When [createChild] is invoked:
  /// - [parent] will be the parent node for the current segment and is
  ///   guaranteed to be non-null.
  /// - [isFinalSegment] will indicate whether the current segment is the tail
  ///   segment, which in turn indicates that this is the segment into which to
  ///   create the node for this entity.
  ///
  /// This method returns with the backing node for the entity at this [path].
  /// If an entity already existed at this path, [createChild] will not be
  /// invoked at all, and this method will return with the backing node for the
  /// existing entity (whose type may differ from this entity's type).
  _Node _createSync(
    _Node createChild(_DirectoryNode parent, bool isFinalSegment),
  ) {
    return fileSystem._findNode(
      path,
      segmentVisitor: (
        _DirectoryNode parent,
        String childName,
        _Node child,
        int currentSegment,
        int finalSegment,
      ) {
        if (child == null) {
          assert(!parent.children.containsKey(childName));
          child = createChild(parent, currentSegment == finalSegment);
          if (child != null) {
            parent.children[childName] = child;
          }
        }
        return child;
      },
    );
  }

  /// Helper method for subclasses wishing to synchronously rename this entity.
  /// This method will look for an existing file system entity at the location
  /// identified by [newPath], and if it finds an existing entity, it will check
  /// the following:
  ///
  /// - If the entity is of a different type than this entity, the operation
  ///   will fail, and a [io.FileSystemException] will be thrown.
  /// - If the caller has specified [validateOverwriteExistingEntity], then that
  ///   method will be invoked and passed the node backing of the existing
  ///   entity that would overwritten by the rename action. That callback is
  ///   expected to throw a [io.FileSystemException] if overwriting the existing
  ///   entity is not allowed.
  ///
  /// If the previous two checks pass, or if there was no existing entity at
  /// the specified location, this will perform the rename.
  ///
  /// If [newPath] cannot be traversed to because its directory does not exist,
  /// a [io.FileSystemException] will be thrown.
  FileSystemEntity _renameSync(
    String newPath, {
    _RenameOverwriteValidator<dynamic> validateOverwriteExistingEntity,
  }) {
    _Node node = backing;
    fileSystem._findNode(
      newPath,
      segmentVisitor: (
        _DirectoryNode parent,
        String childName,
        _Node child,
        int currentSegment,
        int finalSegment,
      ) {
        if (currentSegment == finalSegment) {
          if (child != null) {
            if (child.type != expectedType) {
              throw new io.FileSystemException(
                  'Not a ${expectedType.toString().toLowerCase()}', newPath);
            } else if (validateOverwriteExistingEntity != null) {
              validateOverwriteExistingEntity(child);
            }
            parent.children.remove(childName);
          }
          node.parent.children.remove(basename);
          parent.children[childName] = node;
          node.parent = parent;
        }
        return child;
      },
    );
    return _clone(newPath);
  }

  /// Creates a new entity with the same type as this entity but with the
  /// specified path.
  FileSystemEntity _clone(String path);
}
