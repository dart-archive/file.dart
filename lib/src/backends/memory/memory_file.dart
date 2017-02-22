// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.memory;

class _MemoryFile extends _MemoryFileSystemEntity implements File {
  _MemoryFile(MemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);

  _FileNode get _resolvedBackingOrCreate {
    _Node node = _backingOrNull;
    if (node == null) {
      node = _doCreate();
    } else {
      node = _isLink(node) ? _resolveLinks(node, () => path) : node;
      _checkType(expectedType, node.type, () => path);
    }
    return node;
  }

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.FILE;

  @override
  bool existsSync() => _backingOrNull?.stat?.type == expectedType;

  @override
  Future<File> create({bool recursive: false}) async {
    createSync(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive: false}) {
    _doCreate(recursive: recursive);
  }

  _Node _doCreate({bool recursive: false}) {
    _Node node = _createSync(
      followTailLink: true,
      createChild: (_DirectoryNode parent, bool isFinalSegment) {
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
      assert(node.type == FileSystemEntityType.DIRECTORY);
      String msg = 'Is a directory';
      throw new io.FileSystemException(
          msg, path, new OSError(msg, ErrorCodes.EISDIR));
    }
    return node;
  }

  @override
  Future<File> rename(String newPath) async => renameSync(newPath);

  @override
  File renameSync(String newPath) => _renameSync(
        newPath,
        followTailLink: true,
        checkType: (_Node node) {
          FileSystemEntityType actualType = node.stat.type;
          if (actualType != expectedType) {
            String msg;
            int errorCode;
            if (actualType == FileSystemEntityType.NOT_FOUND) {
              msg = 'No such file or directory';
              errorCode = ErrorCodes.ENOENT;
            } else {
              msg = 'Is a directory';
              errorCode = ErrorCodes.EISDIR;
            }
            throw new FileSystemException(
                msg, path, new OSError(msg, errorCode));
          }
        },
      );

  @override
  Future<File> copy(String newPath) async => copySync(newPath);

  @override
  File copySync(String newPath) {
    _FileNode sourceNode = _resolvedBacking;
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
              List<String> ledger = <String>[];
              child = _resolveLinks(child, () => newPath, ledger: ledger);
              _checkExists(child, () => newPath);
              parent = child.parent;
              childName = ledger.last;
              assert(parent.children.containsKey(childName));
            }
            _checkType(expectedType, child.type, () => newPath);
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
  int lengthSync() => (_resolvedBacking as _FileNode).size;

  @override
  File get absolute => super.absolute;

  @override
  Future<DateTime> lastAccessed() async => lastAccessedSync();

  @override
  DateTime lastAccessedSync() => (_resolvedBacking as _FileNode).stat.accessed;

  @override
  Future<dynamic> setLastAccessed(DateTime time) async =>
      setLastAccessedSync(time);

  @override
  void setLastAccessedSync(DateTime time) {
    _FileNode node = _resolvedBacking;
    node.accessed = time.millisecondsSinceEpoch;
  }

  @override
  Future<DateTime> lastModified() async => lastModifiedSync();

  @override
  DateTime lastModifiedSync() => (_resolvedBacking as _FileNode).stat.modified;

  @override
  Future<dynamic> setLastModified(DateTime time) async =>
      setLastModifiedSync(time);

  @override
  void setLastModifiedSync(DateTime time) {
    _FileNode node = _resolvedBacking;
    node.modified = time.millisecondsSinceEpoch;
  }

  @override
  Future<io.RandomAccessFile> open(
          {io.FileMode mode: io.FileMode.READ}) async =>
      openSync(mode: mode);

  @override
  io.RandomAccessFile openSync({io.FileMode mode: io.FileMode.READ}) =>
      throw new UnimplementedError('TODO');

  @override
  Stream<List<int>> openRead([int start, int end]) {
    try {
      _FileNode node = _resolvedBacking;
      List<int> content = node.content;
      if (start != null) {
        content = end == null
            ? content.sublist(start)
            : content.sublist(start, min(end, content.length));
      }
      return new Stream<List<int>>.fromIterable(<List<int>>[content]);
    } catch (e) {
      return new Stream<List<int>>.fromFuture(new Future<List<int>>.error(e));
    }
  }

  @override
  io.IOSink openWrite({
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
  }) {
    if (!_isWriteMode(mode)) {
      throw new ArgumentError.value(mode, 'mode',
          'Must be either WRITE, APPEND, WRITE_ONLY, or WRITE_ONLY_APPEND');
    }
    return new _FileSink.fromFile(this, mode, encoding);
  }

  @override
  Future<List<int>> readAsBytes() async => readAsBytesSync();

  @override
  List<int> readAsBytesSync() => (_resolvedBacking as _FileNode).content;

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
  List<String> readAsLinesSync({Encoding encoding: UTF8}) {
    String str = readAsStringSync(encoding: encoding);
    return str.isEmpty ? <String>[] : str.split('\n');
  }

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
    if (!_isWriteMode(mode)) {
      String msg = 'Bad file descriptor';
      throw new FileSystemException(
          msg, path, new OSError(msg, ErrorCodes.EBADF));
    }
    _FileNode node = _resolvedBackingOrCreate;
    _truncateIfNecessary(node, mode);
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

  void _truncateIfNecessary(_FileNode node, io.FileMode mode) {
    if (mode == io.FileMode.WRITE || mode == io.FileMode.WRITE_ONLY) {
      node.content.clear();
    }
  }

  @override
  String toString() => "MemoryFile: '$path'";
}

/// Implementation of an [io.IOSink] that's backed by a [_FileNode].
class _FileSink implements io.IOSink {
  final Future<_FileNode> _node;
  final Completer<Null> _completer = new Completer<Null>();

  Future<_FileNode> _pendingWrites;
  Completer<Null> _streamCompleter;
  bool _isClosed = false;

  @override
  Encoding encoding;

  factory _FileSink.fromFile(
    _MemoryFile file,
    io.FileMode mode,
    Encoding encoding,
  ) {
    Future<_FileNode> node = new Future<_FileNode>.microtask(() {
      _FileNode node = file._resolvedBackingOrCreate;
      file._truncateIfNecessary(node, mode);
      return node;
    });
    return new _FileSink._(node, encoding);
  }

  _FileSink._(this._node, this.encoding) {
    _pendingWrites = _node;
  }

  bool get isStreaming => !(_streamCompleter?.isCompleted ?? true);

  @override
  void add(List<int> data) {
    _checkNotStreaming();
    if (!_isClosed) {
      _addData(data);
    }
  }

  @override
  void write(Object obj) => add(encoding.encode(obj?.toString() ?? 'null'));

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
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
  void addError(dynamic error, [StackTrace stackTrace]) {
    _checkNotStreaming();
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<Null> addStream(Stream<List<int>> stream) {
    _checkNotStreaming();
    _streamCompleter = new Completer<Null>();
    void finish() {
      _streamCompleter.complete();
      _streamCompleter = null;
    }

    stream.listen(
      (List<int> data) => _addData(data),
      cancelOnError: true,
      onError: (dynamic error, StackTrace stackTrace) {
        _completer.completeError(error, stackTrace);
        finish();
      },
      onDone: finish,
    );
    return _streamCompleter.future;
  }

  @override
  // TODO(tvolkert): Change to Future<Null> once Dart 1.22 is stable
  Future<dynamic> flush() {
    _checkNotStreaming();
    return _pendingWrites;
  }

  @override
  Future<Null> close() {
    _checkNotStreaming();
    if (!_isClosed) {
      _isClosed = true;
      _pendingWrites.then(
        (_) => _completer.complete(),
        onError: (dynamic error, StackTrace stackTrace) =>
            _completer.completeError(error, stackTrace),
      );
    }
    return _completer.future;
  }

  @override
  Future<Null> get done => _completer.future;

  void _addData(List<int> data) {
    _pendingWrites = _pendingWrites.then((_FileNode node) {
      node.content.addAll(data);
      return node;
    });
  }

  void _checkNotStreaming() {
    if (isStreaming) {
      throw new StateError('StreamSink is bound to a stream');
    }
  }
}
