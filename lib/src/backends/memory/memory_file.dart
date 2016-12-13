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
  File copySync(String newPath) {
    _FileNode sourceNode = backing;
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
            if (_isLink(child)) {
              StringBuffer ledger = new StringBuffer();
              child = _resolveLinks(child, () => newPath, ledger: ledger);
              _checkExists(child, () => newPath);
              parent = child.parent;
              childName = fileSystem._context.basename(ledger.toString());
              assert(parent.children.containsKey(childName));
            }
            if (child.type != expectedType) {
              throw new io.FileSystemException(
                  'Is a ${child.type.toString().toLowerCase()}', newPath);
            }
            parent.children.remove(childName);
          }
          _FileNode newNode = new _FileNode(parent);
          newNode.copyFrom(sourceNode);
          parent.children[childName] = newNode;
        }
        return child;
      },
    );
    return _clone(newPath);
  }

  @override
  Future<int> length() async => lengthSync();

  @override
  int lengthSync() => (backing as _FileNode).size;

  @override
  File get absolute => super.absolute;

  @override
  Future<DateTime> lastModified() async => lastModifiedSync();

  @override
  DateTime lastModifiedSync() => (backing as _FileNode).stat.modified;

  @override
  Future<io.RandomAccessFile> open(
          {io.FileMode mode: io.FileMode.READ}) async =>
      openSync(mode: mode);

  @override
  io.RandomAccessFile openSync({io.FileMode mode: io.FileMode.READ}) =>
      throw new UnimplementedError('TODO');

  @override
  Stream<List<int>> openRead([int start, int end]) {
    _FileNode node = backing;
    return new Stream.fromIterable(<List<int>>[node.content]);
  }

  @override
  io.IOSink openWrite({
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
  }) {
    _checkWriteMode(mode);
    createSync();
    _FileNode node = backing;
    _truncateFileIfNecessary(node, mode);
    return new _FileSink(node, encoding);
  }

  @override
  Future<List<int>> readAsBytes() async => readAsBytesSync();

  @override
  List<int> readAsBytesSync() => (backing as _FileNode).content;

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) async =>
      readAsStringSync(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding: UTF8}) =>
      encoding.decode(readAsBytesSync());

  @override
  Future<List<String>> readAsLines({Encoding encoding: UTF8}) async =>
      readAsLinesSync(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding: UTF8}) =>
      readAsStringSync(encoding: encoding).split('\n');

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode: io.FileMode.WRITE,
    bool flush: false,
  }) async {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode: io.FileMode.WRITE,
    bool flush: false,
  }) {
    _checkWriteMode(mode);
    createSync();
    _FileNode node = backing;
    _truncateFileIfNecessary(node, mode);
    node.content.addAll(bytes);
  }

  @override
  Future<File> writeAsString(
    String contents, {
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) async {
    writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
    return this;
  }

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) =>
      writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);

  @override
  File _clone(String path) => new _MemoryFile(fileSystem, path);

  void _checkWriteMode(io.FileMode mode) {
    if (mode != io.FileMode.WRITE &&
        mode != io.FileMode.APPEND &&
        mode != io.FileMode.WRITE_ONLY &&
        mode != io.FileMode.WRITE_ONLY_APPEND) {
      throw new ArgumentError.value(mode, 'mode',
          'Must be either WRITE, APPEND, WRITE_ONLY, or WRITE_ONLY_APPEND');
    }
  }

  void _truncateFileIfNecessary(_FileNode node, io.FileMode mode) {
    if (mode == io.FileMode.WRITE || mode == io.FileMode.WRITE_ONLY) {
      node.content.clear();
    }
  }
}

/// Implementation of an [io.IOSink] that's backed by a [_FileNode].
class _FileSink implements io.IOSink {
  final _FileNode _node;
  final Completer<Null> _completer = new Completer<Null>();

  Completer<Null> _streamCompleter;
  Encoding _encoding;

  _FileSink(this._node, this._encoding) {
    _checkNotNull(_encoding);
  }

  bool get isClosed => _completer.isCompleted;

  bool get isStreaming => !(_streamCompleter?.isCompleted ?? true);

  @override
  Encoding get encoding => _encoding;

  @override
  set encoding(Encoding encoding) => _encoding = _checkNotNull(encoding);

  @override
  void add(List<int> data) {
    _checkNotStreaming();
    if (!isClosed) {
      _node.content.addAll(data);
    }
  }

  @override
  void write(Object obj) => add(encoding.encode(obj?.toString() ?? 'null'));

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    bool firstIter = true;
    for (dynamic obj in objects) {
      if (!firstIter && separator != null) {
        write(separator);
      }
      firstIter = false;
      write(obj);
    }
  }

  @override
  void writeln([Object obj = '']) {
    write(obj);
    write('\n');
  }

  @override
  void writeCharCode(int charCode) => write(new String.fromCharCode(charCode));

  @override
  void addError(error, [StackTrace stackTrace]) {
    _checkNotStreaming();
    _completer.completeError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    _checkNotStreaming();
    _streamCompleter = new Completer<Null>();
    var finish = () {
      _streamCompleter.complete();
      _streamCompleter = null;
    };
    stream.listen(
      (List<int> data) => _node.content.addAll(data),
      cancelOnError: true,
      onError: (error, StackTrace stackTrace) {
        _completer.completeError(error, stackTrace);
        finish();
      },
      onDone: finish,
    );
    return _streamCompleter.future;
  }

  @override
  Future flush() {
    _checkNotStreaming();
    return new Future.value();
  }

  @override
  Future close() {
    _checkNotStreaming();
    _completer.complete();
    return _completer.future;
  }

  @override
  Future get done => _completer.future;

  dynamic _checkNotNull(dynamic value) {
    if (value == null) {
      throw new ArgumentError.notNull();
    }
    return value;
  }

  void _checkNotStreaming() {
    if (isStreaming) {
      throw new StateError('StreamSink is bound to a stream');
    }
  }
}
