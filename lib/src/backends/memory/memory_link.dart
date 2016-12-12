part of file.src.backends.memory;

class _MemoryLink extends _MemoryFileSystemEntity implements Link {
  _MemoryLink(MemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.LINK;

  @override
  bool existsSync() => backingOrNull?.type == expectedType;

  @override
  Future<Link> rename(String newPath) async => renameSync(newPath);

  @override
  Link renameSync(String newPath) => _renameSync(newPath);

  @override
  Future<Link> create(String target, {bool recursive: false}) async {
    createSync(target, recursive: recursive);
    return this;
  }

  @override
  void createSync(String target, {bool recursive: false}) {
    bool preexisting = true;
    _createSync((_DirectoryNode parent, bool isFinalSegment) {
      if (isFinalSegment) {
        preexisting = false;
        return new _LinkNode(parent, target);
      } else if (recursive) {
        return new _DirectoryNode(parent);
      }
      return null;
    });
    if (preexisting) {
      // Per the spec, this is an error.
      throw new io.FileSystemException('Creation failed', path);
    }
  }

  @override
  Future<Link> update(String target) async {
    updateSync(target);
    return this;
  }

  @override
  void updateSync(String target) {
    _LinkNode node = backing;
    node.target = target;
  }

  @override
  Future<String> target() async => targetSync();

  @override
  String targetSync() {
    _LinkNode node = backing;
    return node.target;
  }

  @override
  Link get absolute => super.absolute;

  @override
  Link _clone(String path) => new _MemoryLink(fileSystem, path);
}
