part of file.src.backends.local;

class _LocalFile extends _LocalFileSystemEntity implements File {
  _LocalFile(io.File entity, FileSystem system) : super(entity, system);

  @override
  Future<File> copy(String newPath) async {
    return new _LocalFile(
        await (_ioEntity as io.File).copy(newPath), fileSystem);
  }

  @override
  Future<File> create({bool recursive: false}) async {
    return new _LocalFile(
        await (_ioEntity as io.File).create(recursive: recursive), fileSystem);
  }

  @override
  Future<List<int>> readAsBytes() => (_ioEntity as io.File).readAsBytes();

  @override
  Future<String> readAsString() => (_ioEntity as io.File).readAsString();

  @override
  Future<File> writeAsBytes(List<int> contents) async {
    return new _LocalFile(
        await (_ioEntity as io.File).writeAsBytes(contents), fileSystem);
  }

  @override
  Future<File> writeAsString(String contents) async {
    return new _LocalFile(
        await (_ioEntity as io.File).writeAsString(contents), fileSystem);
  }
}
