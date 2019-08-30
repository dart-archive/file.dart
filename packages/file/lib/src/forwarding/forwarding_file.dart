// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';

/// A file that forwards all methods and properties to a delegate.
abstract class ForwardingFile
    implements ForwardingFileSystemEntity<File, io.File>, File {
  @override
  ForwardingFile wrap(io.File delegate) => wrapFile(delegate);

  @override
  Future<File> create({bool recursive = false}) async =>
      wrap(await delegate.create(recursive: recursive));

  @override
  void createSync({bool recursive = false}) =>
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
  Future<DateTime> lastAccessed() => delegate.lastAccessed();

  @override
  DateTime lastAccessedSync() => delegate.lastAccessedSync();

  @override
  Future<dynamic> setLastAccessed(DateTime time) =>
      delegate.setLastAccessed(time);

  @override
  void setLastAccessedSync(DateTime time) => delegate.setLastAccessedSync(time);

  @override
  Future<DateTime> lastModified() => delegate.lastModified();

  @override
  DateTime lastModifiedSync() => delegate.lastModifiedSync();

  @override
  Future<dynamic> setLastModified(DateTime time) =>
      delegate.setLastModified(time);

  @override
  void setLastModifiedSync(DateTime time) => delegate.setLastModifiedSync(time);

  @override
  Future<RandomAccessFile> open({
    FileMode mode = FileMode.read,
  }) async =>
      delegate.open(mode: mode);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      delegate.openSync(mode: mode);

  @override
  Stream<Uint8List> openRead([int start, int end]) => delegate
      .openRead(start, end)
      .cast<List<int>>()
      .transform(const _ToUint8List());

  @override
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) =>
      delegate.openWrite(mode: mode, encoding: encoding);

  @override
  Future<Uint8List> readAsBytes() {
    return delegate.readAsBytes().then<Uint8List>((List<int> bytes) {
      return Uint8List.fromList(bytes);
    });
  }

  @override
  Uint8List readAsBytesSync() => Uint8List.fromList(delegate.readAsBytesSync());

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      delegate.readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      delegate.readAsStringSync(encoding: encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      delegate.readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      delegate.readAsLinesSync(encoding: encoding);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async =>
      wrap(await delegate.writeAsBytes(
        bytes,
        mode: mode,
        flush: flush,
      ));

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) =>
      delegate.writeAsBytesSync(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
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
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) =>
      delegate.writeAsStringSync(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      );
}

class _ToUint8List extends Converter<List<int>, Uint8List> {
  const _ToUint8List();

  @override
  Uint8List convert(List<int> input) => Uint8List.fromList(input);

  @override
  Sink<List<int>> startChunkedConversion(Sink<Uint8List> sink) {
    return _Uint8ListConversionSink(sink);
  }
}

class _Uint8ListConversionSink implements Sink<List<int>> {
  const _Uint8ListConversionSink(this._target);

  final Sink<Uint8List> _target;

  @override
  void add(List<int> data) {
    _target.add(Uint8List.fromList(data));
  }

  @override
  void close() {
    _target.close();
  }
}
