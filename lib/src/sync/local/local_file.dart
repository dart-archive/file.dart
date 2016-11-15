part of file.src.backends.local;

class _LocalFile extends _LocalFileSystemEntity implements SyncFile {
  _LocalFile(io.File entity, SyncFileSystem system) : super(entity, system);

  @override
  SyncFile copy(String newPath) {
    return new _LocalFile((_ioEntity as io.File).copySync(newPath), fileSystem);
  }

  @override
  SyncFile create({bool recursive: false}) {
    (_ioEntity as io.File).createSync(recursive: recursive);
    return this;
  }

  @override
  List<int> readAsBytes() => (_ioEntity as io.File).readAsBytesSync();

  @override
  String readAsString() => (_ioEntity as io.File).readAsStringSync();

  @override
  SyncFile writeAsBytes(List<int> contents) {
    (_ioEntity as io.File).writeAsBytesSync(contents);
    return this;
  }

  @override
  SyncFile writeAsString(String contents) {
    (_ioEntity as io.File).writeAsStringSync(contents);
    return this;
  }
}
