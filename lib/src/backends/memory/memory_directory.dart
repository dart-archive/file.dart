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
  bool existsSync() => backingOrNull?.stat?.type == expectedType;

  @override
  Future<Directory> create({bool recursive: false}) async {
    createSync(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive: false}) {
    _Node node = _createSync(
      (_DirectoryNode parent, bool isFinalSegment) {
        if (recursive || isFinalSegment) {
          return new _DirectoryNode(parent);
        }
        return null;
      },
    );
    if (node.type != expectedType) {
      // There was an existing non-directory node at this object's path
      throw new io.FileSystemException('Creation failed', path);
    }
  }

  @override
  Future<Directory> createTemp([String prefix]) async => createTempSync(prefix);

  @override
  Directory createTempSync([String prefix]) {
    prefix ??= '';
    String fullPath = '$path$_separator$prefix';
    String dirname = fileSystem._context.dirname(fullPath);
    String basename = fileSystem._context.basename(fullPath);
    _DirectoryNode node = fileSystem._findNode(dirname);
    _checkExists(node, () => dirname);
    var name = () => '$basename$_tempCounter';
    while (node.children.containsKey(name())) {
      _tempCounter++;
    }
    _DirectoryNode tempDir = new _DirectoryNode(node);
    node.children[name()] = tempDir;
    return new _MemoryDirectory(fileSystem, '$dirname$_separator${name()}');
  }

  @override
  Future<Directory> rename(String newPath) async => renameSync(newPath);

  @override
  Directory renameSync(String newPath) => _renameSync(
        newPath,
        validateOverwriteExistingEntity: (_DirectoryNode existingNode) {
          if (existingNode.children.isNotEmpty) {
            throw new io.FileSystemException('Directory not empty', newPath);
          }
        },
      );

  @override
  Directory get parent =>
      (backingOrNull?.isRoot ?? false) ? this : super.parent;

  @override
  Directory get absolute => super.absolute;

  @override
  Stream<FileSystemEntity> list({
    bool recursive: false,
    bool followLinks: true,
  }) =>
      new Stream.fromIterable(listSync(
        recursive: recursive,
        followLinks: followLinks,
      ));

  @override
  List<FileSystemEntity> listSync({
    bool recursive: false,
    bool followLinks: true,
  }) {
    _DirectoryNode node = backing;
    List<FileSystemEntity> listing = <FileSystemEntity>[];
    Set<_LinkNode> visitedLinks = new Set<_LinkNode>();
    List<_PendingListTask> tasks = <_PendingListTask>[
      new _PendingListTask(
        node,
        path.endsWith(_separator) ? path.substring(0, path.length - 1) : path,
      ),
    ];
    while (tasks.isNotEmpty) {
      _PendingListTask task = tasks.removeLast();
      task.dir.children.forEach((String name, _Node child) {
        String childPath = '${task.path}$_separator$name';
        if (followLinks && _isLink(child) && visitedLinks.add(child)) {
          child = (child as _LinkNode).referent;
        }
        if (_isDirectory(child)) {
          listing.add(new _MemoryDirectory(fileSystem, childPath));
          if (recursive) {
            tasks.add(new _PendingListTask(child, childPath));
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
}

class _PendingListTask {
  final _DirectoryNode dir;
  final String path;
  _PendingListTask(this.dir, this.path);
}
