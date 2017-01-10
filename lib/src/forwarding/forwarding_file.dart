// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.forwarding;

abstract class ForwardingFile extends ForwardingFileSystemEntity<File, io.File>
    implements File {
  @override
  ForwardingFile wrap(io.File delegate) => wrapFile(delegate);

  @override
  Future<File> create({bool recursive: false}) async =>
      wrap(await delegate.create(recursive: recursive));

  @override
  void createSync({bool recursive: false}) =>
      delegate.createSync(recursive: recursive);

  @override
  Future<File> copy(String newPath) async => wrap(await delegate.copy(newPath));

  @override
  File copySync(String newPath) => wrap(delegate.copySync(newPath));

  @override
  Future<int> length() => delegate.length();

  @override
  int lengthSync() => delegate.lengthSync();

  @override
  Future<DateTime> lastModified() => delegate.lastModified();

  @override
  DateTime lastModifiedSync() => delegate.lastModifiedSync();

  @override
  Future<RandomAccessFile> open({
    FileMode mode: FileMode.READ,
  }) async =>
      delegate.open(mode: mode);

  @override
  RandomAccessFile openSync({FileMode mode: FileMode.READ}) =>
      delegate.openSync(mode: mode);

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      delegate.openRead(start, end);

  @override
  IOSink openWrite({
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
  }) =>
      delegate.openWrite(mode: mode, encoding: encoding);

  @override
  Future<List<int>> readAsBytes() => delegate.readAsBytes();

  @override
  List<int> readAsBytesSync() => delegate.readAsBytesSync();

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      delegate.readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding: UTF8}) =>
      delegate.readAsStringSync(encoding: encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding: UTF8}) =>
      delegate.readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding: UTF8}) =>
      delegate.readAsLinesSync(encoding: encoding);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode: FileMode.WRITE,
    bool flush: false,
  }) async =>
      wrap(await delegate.writeAsBytes(
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
      delegate.writeAsBytesSync(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) async =>
      wrap(await delegate.writeAsString(
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
      delegate.writeAsStringSync(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      );
}
