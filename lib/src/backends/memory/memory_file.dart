part of file.src.backends.memory;

class _MemoryFile extends _MemoryFileSystemEntity implements File {
  _MemoryFile(MemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.FILE;

  @override
  bool existsSync() => backingOrNull?.stat?.type == expectedType;

  @override
  Future<File> create({bool recursive: false}) async {
    createSync(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive: false}) {
    _Node node = _createSync(
      (_DirectoryNode parent, bool isFinalSegment) {
        if (isFinalSegment) {
          return new _FileNode(parent);
        } else if (recursive) {
          return new _DirectoryNode(parent);
        }
        return null;
      },
    );
    if (node.type != expectedType) {
      // There was an existing non-file entity at this object's path
      throw new io.FileSystemException('Creation failed', path);
    }
  }

  @override
  Future<File> rename(String newPath) async => renameSync(newPath);

  @override
  File renameSync(String newPath) => _renameSync(newPath);

  @override
  Future<File> copy(String newPath) async => copySync(newPath);

  @override
  File copySync(String newPath) => throw new UnimplementedError('TODO');

  @override
  Future<int> length() async => lengthSync();

  @override
  int lengthSync() => throw new UnimplementedError('TODO');

  @override
  File get absolute => super.absolute;

  @override
  Future<DateTime> lastModified() async => lastModifiedSync();

  @override
  DateTime lastModifiedSync() => throw new UnimplementedError('TODO');

  @override
  Future<io.RandomAccessFile> open(
          {io.FileMode mode: io.FileMode.READ}) async =>
      openSync(mode: mode);

  @override
  io.RandomAccessFile openSync({io.FileMode mode: io.FileMode.READ}) =>
      throw new UnimplementedError('TODO');

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      throw new UnimplementedError('TODO');

  @override
  io.IOSink openWrite({
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
  }) =>
      throw new UnimplementedError('TODO');

  @override
  Future<List<int>> readAsBytes() {
    throw new UnimplementedError('TODO');
  }

  @override
  List<int> readAsBytesSync() {
    throw new UnimplementedError('TODO');
  }

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) {
    throw new UnimplementedError('TODO');
  }

  @override
  String readAsStringSync({Encoding encoding: UTF8}) {
    throw new UnimplementedError('TODO');
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding: UTF8}) {
    throw new UnimplementedError('TODO');
  }

  @override
  List<String> readAsLinesSync({Encoding encoding: UTF8}) {
    throw new UnimplementedError('TODO');
  }

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode: io.FileMode.WRITE,
    bool flush: false,
  }) {
    throw new UnimplementedError('TODO');
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode: io.FileMode.WRITE,
    bool flush: false,
  }) {
    throw new UnimplementedError('TODO');
  }

  @override
  Future<File> writeAsString(
    String contents, {
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) {
    throw new UnimplementedError('TODO');
  }

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) {
    throw new UnimplementedError('TODO');
  }

  @override
  File _clone(String path) => new _MemoryFile(fileSystem, path);
}
