// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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
typedef void _BlobDataSyncWriter<T>(File file, T data);

/// Callback responsible for asynchronously writing result [data] to the
/// specified [file].
///
/// See also:
///   - [_BlobFutureReference]
typedef Future<Null> _BlobDataAsyncWriter<T>(File file, T data);

/// Callback responsible writing streaming result [data] to the specified
/// [sink].
///
/// See also:
///   - [_BlobStreamReference]
typedef void _BlobDataStreamWriter<T>(IOSink sink, T data);

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
      #lastModified: delegate.lastModified,
      #lastModifiedSync: delegate.lastModifiedSync,
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
      new RecordingRandomAccessFile(fileSystem, delegate);

  Future<File> _create({bool recursive: false}) =>
      delegate.create(recursive: recursive).then(wrap);

  Future<File> _copy(String newPath) => delegate.copy(newPath).then(wrap);

  File _copySync(String newPath) => wrap(delegate.copySync(newPath));

  Future<RandomAccessFile> _open({FileMode mode: FileMode.READ}) =>
      delegate.open(mode: mode).then(_wrapRandomAccessFile);

  RandomAccessFile _openSync({FileMode mode: FileMode.READ}) =>
      _wrapRandomAccessFile(delegate.openSync(mode: mode));

  StreamReference<List<int>> _openRead([int start, int end]) {
    return new _BlobStreamReference<List<int>>(
      file: _newRecordingFile(),
      stream: delegate.openRead(start, end),
      writer: (IOSink sink, List<int> bytes) {
        sink.add(bytes);
      },
    );
  }

  IOSink _openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8}) {
    return new RecordingIOSink(
      fileSystem,
      delegate.openWrite(mode: mode, encoding: encoding),
    );
  }

  FutureReference<List<int>> _readAsBytes() {
    return new _BlobFutureReference<List<int>>(
      file: _newRecordingFile(),
      future: delegate.readAsBytes(),
      writer: (File file, List<int> bytes) async {
        await file.writeAsBytes(bytes, flush: true);
      },
    );
  }

  ResultReference<List<int>> _readAsBytesSync() {
    return new _BlobReference<List<int>>(
      file: _newRecordingFile(),
      value: delegate.readAsBytesSync(),
      writer: (File file, List<int> bytes) {
        file.writeAsBytesSync(bytes, flush: true);
      },
    );
  }

  FutureReference<String> _readAsString({Encoding encoding: UTF8}) {
    return new _BlobFutureReference<String>(
      file: _newRecordingFile(),
      future: delegate.readAsString(encoding: encoding),
      writer: (File file, String content) async {
        await file.writeAsString(content, flush: true);
      },
    );
  }

  ResultReference<String> _readAsStringSync({Encoding encoding: UTF8}) {
    return new _BlobReference<String>(
      file: _newRecordingFile(),
      value: delegate.readAsStringSync(encoding: encoding),
      writer: (File file, String content) {
        file.writeAsStringSync(content, flush: true);
      },
    );
  }

  FutureReference<List<String>> _readAsLines({Encoding encoding: UTF8}) {
    return new _BlobFutureReference<List<String>>(
      file: _newRecordingFile(),
      future: delegate.readAsLines(encoding: encoding),
      writer: (File file, List<String> lines) async {
        await file.writeAsString(lines.join('\n'), flush: true);
      },
    );
  }

  ResultReference<List<String>> _readAsLinesSync({Encoding encoding: UTF8}) {
    return new _BlobReference<List<String>>(
      file: _newRecordingFile(),
      value: delegate.readAsLinesSync(encoding: encoding),
      writer: (File file, List<String> lines) {
        file.writeAsStringSync(lines.join('\n'), flush: true);
      },
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

/// A [ResultReference] that serializes its value data to a separate file.
class _BlobReference<T> extends ResultReference<T> {
  final File _file;
  final T _value;
  final _BlobDataSyncWriter<T> _writer;

  _BlobReference({
    @required File file,
    @required T value,
    @required _BlobDataSyncWriter<T> writer,
  })
      : _file = file,
        _value = value,
        _writer = writer;

  @override
  T get value {
    _writer(_file, _value);
    return _value;
  }

  @override
  T get recordedValue => _value;

  @override
  dynamic get serializedValue => '!${_file.basename}';
}

/// A [FutureReference] that serializes its value data to a separate file.
class _BlobFutureReference<T> extends FutureReference<T> {
  final File _file;
  final _BlobDataAsyncWriter<T> _writer;

  _BlobFutureReference({
    @required File file,
    @required Future<T> future,
    @required _BlobDataAsyncWriter<T> writer,
  })
      : _file = file,
        _writer = writer,
        super(future);

  @override
  Future<T> get value {
    return super.value.then((T value) async {
      await _writer(_file, value);
      return value;
    });
  }

  @override
  dynamic get serializedValue => '!${_file.basename}';
}

/// A [StreamReference] that serializes its value data to a separate file.
class _BlobStreamReference<T> extends StreamReference<T> {
  final File _file;
  final _BlobDataStreamWriter<T> _writer;
  IOSink _sink;

  _BlobStreamReference({
    @required File file,
    @required Stream<T> stream,
    @required _BlobDataStreamWriter<T> writer,
  })
      : _file = file,
        _writer = writer,
        super(stream) {
    _file.createSync();
  }

  @override
  void onData(T event) {
    if (_sink == null) {
      _sink = _file.openWrite();
    }
    _writer(_sink, event);
  }

  @override
  void onDone() {
    if (_sink != null) {
      _sink.close();
    }
  }

  @override
  dynamic get serializedValue => '!${_file.basename}';

  // TODO(tvolkert): remove `.then()` once Dart 1.22 is in stable
  @override
  Future<Null> get complete =>
      Future.wait(<Future<dynamic>>[super.complete, _sink.done]).then((_) {});
}
