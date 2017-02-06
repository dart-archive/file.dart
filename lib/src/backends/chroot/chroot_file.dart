// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.chroot;

typedef dynamic _SetupCallback();

class _ChrootFile extends _ChrootFileSystemEntity<File, io.File>
    with ForwardingFile {
  _ChrootFile(ChrootFileSystem fs, String path) : super(fs, path);

  factory _ChrootFile.wrapped(
    ChrootFileSystem fs,
    io.File delegate, {
    bool relative: false,
  }) {
    String localPath = fs._local(delegate.path, relative: relative);
    return new _ChrootFile(fs, localPath);
  }

  @override
  FileSystemEntityType get expectedType => FileSystemEntityType.FILE;

  @override
  io.File _rawDelegate(String path) => fileSystem.delegate.file(path);

  @override
  Future<File> rename(String newPath) async {
    _SetupCallback setUp = () {};

    if (await fileSystem.type(newPath, followLinks: false) ==
        FileSystemEntityType.LINK) {
      // The delegate file system will ensure that the link target references
      // an actual file before allowing the rename, but we want the link target
      // to be resolved with respect to this file system. Thus, we perform that
      // validation here instead.
      switch (await fileSystem.type(newPath)) {
        case FileSystemEntityType.FILE:
        case FileSystemEntityType.NOT_FOUND:
          // Validation passed; delete the link to keep the delegate file
          // system's validation from getting in the way.
          setUp = () async {
            await fileSystem.link(newPath).delete();
          };
          break;
        case FileSystemEntityType.DIRECTORY:
          throw new FileSystemException('Is a directory', newPath);
        default:
          // Should never happen.
          throw new AssertionError();
      }
    }

    if (_isLink) {
      switch (await fileSystem.type(path)) {
        case FileSystemEntityType.NOT_FOUND:
          throw new FileSystemException('No such file or directory', path);
        case FileSystemEntityType.DIRECTORY:
          throw new FileSystemException('Is a directory', path);
        case FileSystemEntityType.FILE:
          await setUp();
          await fileSystem.delegate
              .link(fileSystem._real(path))
              .rename(fileSystem._real(newPath));
          return new _ChrootFile(fileSystem, newPath);
          break;
        default:
          throw new AssertionError();
      }
    } else {
      await setUp();
      return wrap(await delegate.rename(fileSystem._real(newPath)));
    }
  }

  @override
  File renameSync(String newPath) {
    _SetupCallback setUp = () {};

    if (fileSystem.typeSync(newPath, followLinks: false) ==
        FileSystemEntityType.LINK) {
      // The delegate file system will ensure that the link target references
      // an actual file before allowing the rename, but we want the link target
      // to be resolved with respect to this file system. Thus, we perform that
      // validation here instead.
      switch (fileSystem.typeSync(newPath)) {
        case FileSystemEntityType.FILE:
        case FileSystemEntityType.NOT_FOUND:
          // Validation passed; delete the link to keep the delegate file
          // system's validation from getting in the way.
          setUp = () {
            fileSystem.link(newPath).deleteSync();
          };
          break;
        case FileSystemEntityType.DIRECTORY:
          throw new FileSystemException('Is a directory', newPath);
        default:
          // Should never happen.
          throw new AssertionError();
      }
    }

    if (_isLink) {
      switch (fileSystem.typeSync(path)) {
        case FileSystemEntityType.NOT_FOUND:
          throw new FileSystemException('No such file or directory', path);
        case FileSystemEntityType.DIRECTORY:
          throw new FileSystemException('Is a directory', path);
        case FileSystemEntityType.FILE:
          setUp();
          fileSystem.delegate
              .link(fileSystem._real(path))
              .renameSync(fileSystem._real(newPath));
          return new _ChrootFile(fileSystem, newPath);
          break;
        default:
          throw new AssertionError();
      }
    } else {
      setUp();
      return wrap(delegate.renameSync(fileSystem._real(newPath)));
    }
  }

  @override
  File get absolute => new _ChrootFile(fileSystem, _absolutePath);

  @override
  Future<File> create({bool recursive: false}) async {
    String path = fileSystem._resolve(
      this.path,
      followLinks: false,
      notFound: recursive ? _NotFoundBehavior.mkdir : _NotFoundBehavior.allow,
    );

    String real() => fileSystem._real(path, resolve: false);
    Future<FileSystemEntityType> type() =>
        fileSystem.delegate.type(real(), followLinks: false);

    if (await type() == FileSystemEntityType.LINK) {
      path = fileSystem._resolve(p.basename(path),
          from: p.dirname(path), notFound: _NotFoundBehavior.allowAtTail);
      switch (await type()) {
        case FileSystemEntityType.NOT_FOUND:
          await _rawDelegate(real()).create();
          return this;
        case FileSystemEntityType.FILE:
          // Nothing to do.
          return this;
        case FileSystemEntityType.DIRECTORY:
          throw new FileSystemException('Is a directory', path);
        default:
          throw new AssertionError();
      }
    } else {
      return wrap(await _rawDelegate(real()).create());
    }
  }

  @override
  void createSync({bool recursive: false}) {
    String path = fileSystem._resolve(
      this.path,
      followLinks: false,
      notFound: recursive ? _NotFoundBehavior.mkdir : _NotFoundBehavior.allow,
    );

    String real() => fileSystem._real(path, resolve: false);
    FileSystemEntityType type() =>
        fileSystem.delegate.typeSync(real(), followLinks: false);

    if (type() == FileSystemEntityType.LINK) {
      path = fileSystem._resolve(p.basename(path),
          from: p.dirname(path), notFound: _NotFoundBehavior.allowAtTail);
      switch (type()) {
        case FileSystemEntityType.NOT_FOUND:
          _rawDelegate(real()).createSync();
          return;
        case FileSystemEntityType.FILE:
          // Nothing to do.
          return;
        case FileSystemEntityType.DIRECTORY:
          throw new FileSystemException('Is a directory', path);
        default:
          throw new AssertionError();
      }
    } else {
      _rawDelegate(real()).createSync();
    }
  }

  @override
  Future<File> copy(String newPath) async {
    return wrap(await getDelegate(followLinks: true)
        .copy(fileSystem._real(newPath, followLinks: true)));
  }

  @override
  File copySync(String newPath) {
    return wrap(getDelegate(followLinks: true)
        .copySync(fileSystem._real(newPath, followLinks: true)));
  }

  @override
  Future<int> length() => getDelegate(followLinks: true).length();

  @override
  int lengthSync() => getDelegate(followLinks: true).lengthSync();

  @override
  Future<DateTime> lastModified() =>
      getDelegate(followLinks: true).lastModified();

  @override
  DateTime lastModifiedSync() =>
      getDelegate(followLinks: true).lastModifiedSync();

  @override
  Future<RandomAccessFile> open({
    FileMode mode: FileMode.READ,
  }) async =>
      getDelegate(followLinks: true).open(mode: mode);

  @override
  RandomAccessFile openSync({FileMode mode: FileMode.READ}) =>
      getDelegate(followLinks: true).openSync(mode: mode);

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      getDelegate(followLinks: true).openRead(start, end);

  @override
  IOSink openWrite({
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
  }) =>
      getDelegate(followLinks: true).openWrite(mode: mode, encoding: encoding);

  @override
  Future<List<int>> readAsBytes() =>
      getDelegate(followLinks: true).readAsBytes();

  @override
  List<int> readAsBytesSync() =>
      getDelegate(followLinks: true).readAsBytesSync();

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      getDelegate(followLinks: true).readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding: UTF8}) =>
      getDelegate(followLinks: true).readAsStringSync(encoding: encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding: UTF8}) =>
      getDelegate(followLinks: true).readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding: UTF8}) =>
      getDelegate(followLinks: true).readAsLinesSync(encoding: encoding);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode: FileMode.WRITE,
    bool flush: false,
  }) async =>
      wrap(await getDelegate(followLinks: true).writeAsBytes(
        bytes,
        mode: mode,
        flush: flush,
      ));

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode: FileMode.WRITE,
    bool flush: false,
  }) =>
      getDelegate(followLinks: true)
          .writeAsBytesSync(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) async =>
      wrap(await getDelegate(followLinks: true).writeAsString(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      ));

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) =>
      getDelegate(followLinks: true).writeAsStringSync(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      );
}
