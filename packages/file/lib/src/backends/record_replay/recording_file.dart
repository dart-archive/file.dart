// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'recording_file_system.dart';
import 'recording_file_system_entity.dart';
import 'recording_io_sink.dart';
import 'recording_random_access_file.dart';
import 'result_reference.dart';

/// Callback responsible for synchronously writing result [data] to the
/// specified [file].
///
/// See also:
///   - [_BlobReference]
///   - [_BlobStreamReference]
typedef _BlobDataSyncWriter<T> = void Function(File file, T data);

/// Callback responsible for asynchronously writing result [data] to the
/// specified [file].
///
/// See also:
///   - [_BlobFutureReference]
typedef _BlobDataAsyncWriter<T> = Future<void> Function(File file, T data);

/// [File] implementation that records all invocation activity to its file
/// system's recording.
class RecordingFile extends RecordingFileSystemEntity<File> implements File {
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
      #lastAccessed: delegate.lastAccessed,
      #lastAccessedSync: delegate.lastAccessedSync,
      #setLastAccessed: delegate.setLastAccessed,
      #setLastAccessedSync: delegate.setLastAccessedSync,
      #lastModified: delegate.lastModified,
      #lastModifiedSync: delegate.lastModifiedSync,
      #setLastModified: delegate.setLastModified,
      #setLastModifiedSync: delegate.setLastModifiedSync,
      #open: _open,
      #openSync: _openSync,
      #openRead: _openRead,
      #openWrite: _openWrite,
      #readAsBytes: _readAsBytes,
      #readAsBytesSync: _readAsBytesSync,
      #readAsString: _readAsString,
      #readAsStringSync: _readAsStringSync,
      #readAsLines: _readAsLines,
      #readAsLinesSync: _readAsLinesSync,
      #writeAsBytes: _writeAsBytes,
      #writeAsBytesSync: delegate.writeAsBytesSync,
      #writeAsString: _writeAsString,
      #writeAsStringSync: delegate.writeAsStringSync,
    });
  }

  @override
  File wrap(File delegate) => super.wrap(delegate) ?? wrapFile(delegate);

  File _newRecordingFile() => recording.newFile(delegate.basename);

  RandomAccessFile _wrapRandomAccessFile(RandomAccessFile delegate) =>
      RecordingRandomAccessFile(fileSystem, delegate);

  Future<File> _create({bool recursive = false}) =>
      delegate.create(recursive: recursive).then(wrap);

  Future<File> _copy(String newPath) => delegate.copy(newPath).then(wrap);

  File _copySync(String newPath) => wrap(delegate.copySync(newPath));

  Future<RandomAccessFile> _open({FileMode mode = FileMode.read}) =>
      delegate.open(mode: mode).then(_wrapRandomAccessFile);

  RandomAccessFile _openSync({FileMode mode = FileMode.read}) =>
      _wrapRandomAccessFile(delegate.openSync(mode: mode));

  StreamReference<Uint8List> _openRead([int start, int end]) {
    return _BlobStreamReference<Uint8List>(
      file: _newRecordingFile(),
      stream: delegate.openRead(start, end),
      writer: (File file, Uint8List bytes) {
        file.writeAsBytesSync(bytes, mode: FileMode.append, flush: true);
      },
    );
  }

  IOSink _openWrite(
      {FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    return RecordingIOSink(
      fileSystem,
      delegate.openWrite(mode: mode, encoding: encoding),
    );
  }

  FutureReference<Uint8List> _readAsBytes() {
    return _BlobFutureReference<Uint8List>(
      file: _newRecordingFile(),
      future: delegate.readAsBytes(),
      writer: (File file, Uint8List bytes) async {
        await file.writeAsBytes(bytes, flush: true);
      },
    );
  }

  ResultReference<Uint8List> _readAsBytesSync() {
    return _BlobReference<Uint8List>(
      file: _newRecordingFile(),
      value: delegate.readAsBytesSync(),
      writer: (File file, Uint8List bytes) {
        file.writeAsBytesSync(bytes, flush: true);
      },
    );
  }

  FutureReference<String> _readAsString({Encoding encoding = utf8}) {
    return _BlobFutureReference<String>(
      file: _newRecordingFile(),
      future: delegate.readAsString(encoding: encoding),
      writer: (File file, String content) async {
        await file.writeAsString(content, flush: true);
      },
    );
  }

  ResultReference<String> _readAsStringSync({Encoding encoding = utf8}) {
    return _BlobReference<String>(
      file: _newRecordingFile(),
      value: delegate.readAsStringSync(encoding: encoding),
      writer: (File file, String content) {
        file.writeAsStringSync(content, flush: true);
      },
    );
  }

  FutureReference<List<String>> _readAsLines({Encoding encoding = utf8}) {
    return _BlobFutureReference<List<String>>(
      file: _newRecordingFile(),
      future: delegate.readAsLines(encoding: encoding),
      writer: (File file, List<String> lines) async {
        await file.writeAsString(_joinLines(lines), flush: true);
      },
    );
  }

  ResultReference<List<String>> _readAsLinesSync({Encoding encoding = utf8}) {
    return _BlobReference<List<String>>(
      file: _newRecordingFile(),
      value: delegate.readAsLinesSync(encoding: encoding),
      writer: (File file, List<String> lines) {
        file.writeAsStringSync(_joinLines(lines), flush: true);
      },
    );
  }

  Future<File> _writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) =>
      delegate.writeAsBytes(bytes, mode: mode, flush: flush).then(wrap);

  Future<File> _writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) =>
      delegate
          .writeAsString(contents, mode: mode, encoding: encoding, flush: flush)
          .then(wrap);
}

/// A [ResultReference] that serializes its value data to a separate file.
class _BlobReference<T> extends ResultReference<T> {
  _BlobReference({
    @required File file,
    @required T value,
    @required _BlobDataSyncWriter<T> writer,
  })  : _file = file,
        _value = value,
        _writer = writer;

  final File _file;
  final T _value;
  final _BlobDataSyncWriter<T> _writer;

  @override
  T get value {
    _writer(_file, _value);
    return _value;
  }

  @override
  T get recordedValue => _value;

  @override
  String get serializedValue => '!${_file.basename}';
}

/// A [FutureReference] that serializes its value data to a separate file.
class _BlobFutureReference<T> extends FutureReference<T> {
  _BlobFutureReference({
    @required File file,
    @required Future<T> future,
    @required _BlobDataAsyncWriter<T> writer,
  })  : _file = file,
        _writer = writer,
        super(future);

  final File _file;
  final _BlobDataAsyncWriter<T> _writer;

  @override
  Future<T> get value {
    return super.value.then((T value) async {
      await _writer(_file, value);
      return value;
    });
  }

  @override
  String get serializedValue => '!${_file.basename}';
}

/// A [StreamReference] that serializes its value data to a separate file.
class _BlobStreamReference<T> extends StreamReference<T> {
  _BlobStreamReference({
    @required File file,
    @required Stream<T> stream,
    @required _BlobDataSyncWriter<T> writer,
  })  : _file = file,
        _writer = writer,
        super(stream);

  final File _file;
  final _BlobDataSyncWriter<T> _writer;

  @override
  void onData(T event) {
    _writer(_file, event);
  }

  @override
  String get serializedValue => '!${_file.basename}';
}

/// Flattens a list of lines into a single, newline-delimited string.
///
/// Each element of [lines] is assumed to represent a complete line and will
/// be end with a newline in the resulting string.
String _joinLines(List<String> lines) =>
    lines.isEmpty ? '' : (lines.join('\n') + '\n');
