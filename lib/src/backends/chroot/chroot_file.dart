part of file.src.backends.chroot;

class _ChrootFile extends _ChrootFileSystemEntity<File, io.File>
    with ForwardingFile {
  factory _ChrootFile.wrapped(
    ChrootFileSystem fs,
    io.File delegate, {
    bool relative: false,
  }) {
    String localPath = fs._local(delegate.path, relative: relative);
    return new _ChrootFile(fs, localPath);
  }

  _ChrootFile(ChrootFileSystem fs, String path) : super(fs, path);

  @override
  io.File get delegate => fileSystem.delegate.file(_realPath);

  @override
  File get absolute => new _ChrootFile(fileSystem, _absolutePath);

  @override
  Future<File> copy(String newPath) async =>
      wrap(await delegate.copy(fileSystem._real(newPath)));

  @override
  File copySync(String newPath) =>
      wrap(delegate.copySync(fileSystem._real(newPath)));
}
