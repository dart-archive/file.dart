// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

class _RecordingFile extends _RecordingFileSystemEntity<File, io.File>
    implements File {
  _RecordingFile(RecordingFileSystem fileSystem, io.File delegate)
      : super(fileSystem, delegate) {
    methods.addAll(<Symbol, Function>{
      #create: _create,
      #createSync: delegate.createSync,
      #copy: _copy,
      #copySync: _copySync,
      #length: delegate.length,
      #lengthSync: delegate.lengthSync,
      #lastModified: delegate.lastModified,
      #lastModifiedSync: delegate.lastModifiedSync,
      #open: _open,
      #openSync: _openSync,
      #openRead: delegate.openRead,
      #openWrite: _openWrite,
      #readAsBytes: delegate.readAsBytes,
      #readAsBytesSync: delegate.readAsBytesSync,
      #readAsString: delegate.readAsString,
      #readAsStringSync: delegate.readAsStringSync,
      #readAsLines: delegate.readAsLines,
      #readAsLinesSync: delegate.readAsLinesSync,
      #writeAsBytes: _writeAsBytes,
      #writeAsBytesSync: delegate.writeAsBytesSync,
      #writeAsString: _writeAsString,
      #writeAsStringSync: delegate.writeAsStringSync,
    });
  }

  @override
  File _wrap(io.File delegate) => super._wrap(delegate) ?? _wrapFile(delegate);

  RandomAccessFile _wrapRandomAccessFile(RandomAccessFile delegate) =>
      new _RecordingRandomAccessFile(fileSystem, delegate);

  Future<File> _create({bool recursive: false}) =>
      delegate.create(recursive: recursive).then(_wrap);

  Future<File> _copy(String newPath) => delegate.copy(newPath).then(_wrap);

  File _copySync(String newPath) => _wrap(delegate.copySync(newPath));

  Future<RandomAccessFile> _open({FileMode mode: FileMode.READ}) =>
      delegate.open(mode: mode).then(_wrapRandomAccessFile);

  RandomAccessFile _openSync({FileMode mode: FileMode.READ}) =>
      _wrapRandomAccessFile(delegate.openSync(mode: mode));

  IOSink _openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8}) {
    IOSink sink = delegate.openWrite(mode: mode, encoding: encoding);
    return new _RecordingIOSink(fileSystem, sink);
  }

  Future<File> _writeAsBytes(List<int> bytes,
          {FileMode mode: FileMode.WRITE, bool flush: false}) =>
      delegate.writeAsBytes(bytes, mode: mode, flush: flush).then(_wrap);

  Future<File> _writeAsString(
    String contents, {
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) =>
      delegate
          .writeAsString(contents, mode: mode, encoding: encoding, flush: flush)
          .then(_wrap);
}
