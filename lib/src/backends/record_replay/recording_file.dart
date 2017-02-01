// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'recording_file_system.dart';
import 'recording_file_system_entity.dart';
import 'recording_io_sink.dart';
import 'recording_random_access_file.dart';

/// [File] implementation that records all invocation activity to its file
/// system's recording.
class RecordingFile extends RecordingFileSystemEntity<File, io.File>
    implements File {
  /// Creates a new `RecordingFile`.
  RecordingFile(RecordingFileSystem fileSystem, io.File delegate)
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
  File wrap(io.File delegate) => super.wrap(delegate) ?? wrapFile(delegate);

  RandomAccessFile _wrapRandomAccessFile(RandomAccessFile delegate) =>
      new RecordingRandomAccessFile(fileSystem, delegate);

  Future<File> _create({bool recursive: false}) =>
      delegate.create(recursive: recursive).then(wrap);

  Future<File> _copy(String newPath) => delegate.copy(newPath).then(wrap);

  File _copySync(String newPath) => wrap(delegate.copySync(newPath));

  Future<RandomAccessFile> _open({FileMode mode: FileMode.READ}) =>
      delegate.open(mode: mode).then(_wrapRandomAccessFile);

  RandomAccessFile _openSync({FileMode mode: FileMode.READ}) =>
      _wrapRandomAccessFile(delegate.openSync(mode: mode));

  IOSink _openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8}) {
    return new RecordingIOSink(
      fileSystem,
      delegate.openWrite(mode: mode, encoding: encoding),
    );
  }

  Future<File> _writeAsBytes(
    List<int> bytes, {
    FileMode mode: FileMode.WRITE,
    bool flush: false,
  }) =>
      delegate.writeAsBytes(bytes, mode: mode, flush: flush).then(wrap);

  Future<File> _writeAsString(
    String contents, {
    FileMode mode: FileMode.WRITE,
    Encoding encoding: UTF8,
    bool flush: false,
  }) =>
      delegate
          .writeAsString(contents, mode: mode, encoding: encoding, flush: flush)
          .then(wrap);
}
