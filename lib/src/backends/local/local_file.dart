part of file.src.backends.local;

class _LocalFile extends _LocalFileSystemEntity<File, io.File> implements File {
  _LocalFile(FileSystem fileSystem, io.File delegate)
      : super(fileSystem, delegate);

  @override
  _LocalFile _createNew(io.File delegate) =>
      new _LocalFile(fileSystem, delegate);

  @override
  Future<File> create({bool recursive: false}) async =>
      _createNew(await _delegate.create(recursive: recursive));

  @override
  void createSync({bool recursive: false}) =>
      _delegate.createSync(recursive: recursive);

  @override
  Future<File> copy(String newPath) async =>
      _createNew(await _delegate.copy(newPath));

  @override
  File copySync(String newPath) => _createNew(_delegate.copySync(newPath));

  @override
  Future<int> length() => _delegate.length();

  @override
  int lengthSync() => _delegate.lengthSync();

  @override
  Future<DateTime> lastModified() => _delegate.lastModified();

  @override
  DateTime lastModifiedSync() => _delegate.lastModifiedSync();

  @override
  Future<io.RandomAccessFile> open({
    io.FileMode mode: io.FileMode.READ,
  }) async =>
      _delegate.open(mode: mode);

  @override
  io.RandomAccessFile openSync({io.FileMode mode: io.FileMode.READ}) =>
      _delegate.openSync(mode: mode);

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      _delegate.openRead(start, end);

  @override
  io.IOSink openWrite({
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
  }) =>
      _delegate.openWrite(mode: mode, encoding: encoding);

  @override
  Future<List<int>> readAsBytes() => _delegate.readAsBytes();

  @override
  List<int> readAsBytesSync() => _delegate.readAsBytesSync();

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      _delegate.readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding: UTF8}) =>
      _delegate.readAsStringSync(encoding: encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding: UTF8}) =>
      _delegate.readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding: UTF8}) =>
      _delegate.readAsLinesSync(encoding: encoding);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode: io.FileMode.WRITE,
    bool flush: false,
  }) async =>
      _createNew(await _delegate.writeAsBytes(
        bytes,
        mode: mode,
        flush: flush,
      ));

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode: io.FileMode.WRITE,
    bool flush: false,
  }) =>
      _delegate.writeAsBytesSync(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) async =>
      _createNew(await _delegate.writeAsString(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      ));

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode: io.FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) =>
      _delegate.writeAsStringSync(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      );
}
