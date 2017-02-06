// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'mutable_recording.dart';
import 'recording_file_system.dart';
import 'recording_file_system_entity.dart';
import 'recording_io_sink.dart';
import 'recording_random_access_file.dart';
import 'result_reference.dart';

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

  StreamReference<List<int>> _openRead([int start, int end]) =>
      new _ByteArrayStreamReference(
        recording,
        'openRead',
        delegate.openRead(start, end),
      );

  IOSink _openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8}) {
    return new RecordingIOSink(
      fileSystem,
      delegate.openWrite(mode: mode, encoding: encoding),
    );
  }

  FutureReference<List<int>> _readAsBytes() => new _ByteArrayFutureReference(
        recording,
        'readAsBytes',
        delegate.readAsBytes(),
      );

  ResultReference<List<int>> _readAsBytesSync() => new _ByteArrayReference(
        recording,
        'readAsBytesSync',
        delegate.readAsBytesSync(),
      );

  FutureReference<String> _readAsString({Encoding encoding: UTF8}) =>
      new _FileContentFutureReference(
        recording,
        'readAsString',
        delegate.readAsString(encoding: encoding),
      );

  ResultReference<String> _readAsStringSync({Encoding encoding: UTF8}) =>
      new _FileContentReference(
        recording,
        'readAsStringSync',
        delegate.readAsStringSync(encoding: encoding),
      );

  FutureReference<List<String>> _readAsLines({Encoding encoding: UTF8}) =>
      new _LinesFutureReference(
        recording,
        'readAsLines',
        delegate.readAsLines(encoding: encoding),
      );

  ResultReference<List<String>> _readAsLinesSync({Encoding encoding: UTF8}) =>
      new _LinesReference(
        recording,
        'readAsLinesSync',
        delegate.readAsLinesSync(encoding: encoding),
      );

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

abstract class _ExternalReference<T> extends ResultReference<T> {
  final File file;
  final T _value;

  _ExternalReference(MutableRecording recording, String name, this._value)
      : file = recording.newFile(name);

  @protected
  void writeDataToFile(T value);

  @override
  T get value {
    writeDataToFile(_value);
    return _value;
  }

  @override
  T get recordedValue => _value;

  @override
  dynamic get serializedValue => '!${file.basename}';
}

abstract class _ExternalFutureReference<T> extends FutureReference<T> {
  final File file;

  _ExternalFutureReference(
      MutableRecording recording, String name, Future<T> future)
      : file = recording.newFile(name),
        super(future);

  @protected
  Future<Null> writeDataToFile(T value);

  @override
  Future<T> get value {
    return super.value.then((T value) async {
      await writeDataToFile(value);
      return value;
    });
  }

  @override
  dynamic get serializedValue => '!${file.basename}';
}

class _ByteArrayStreamReference extends StreamReference<List<int>> {
  final File file;
  IOSink _sink;

  _ByteArrayStreamReference(
      MutableRecording recording, String name, Stream<List<int>> stream)
      : file = recording.newFile(name)..createSync(),
        super(stream);

  @override
  void onData(List<int> event) {
    if (_sink == null) {
      _sink = file.openWrite();
    }
    _sink.add(event);
  }

  @override
  void onDone() {
    if (_sink != null) {
      _sink.close();
    }
  }

  @override
  dynamic get serializedValue => '!${file.basename}';

  // TODO(tvolkert): remove `.then()` once Dart 1.22 is in stable
  @override
  Future<Null> get complete =>
      Future.wait(<Future<dynamic>>[super.complete, _sink.done]).then((_) {});
}

class _ByteArrayFutureReference extends _ExternalFutureReference<List<int>> {
  _ByteArrayFutureReference(
      MutableRecording recording, String name, Future<List<int>> future)
      : super(recording, name, future);

  @override
  Future<Null> writeDataToFile(List<int> bytes) async {
    await file.writeAsBytes(bytes, flush: true);
  }
}

class _ByteArrayReference extends _ExternalReference<List<int>> {
  _ByteArrayReference(MutableRecording recording, String name, List<int> bytes)
      : super(recording, name, bytes);

  @override
  void writeDataToFile(List<int> bytes) {
    file.writeAsBytesSync(bytes, flush: true);
  }
}

class _FileContentFutureReference extends _ExternalFutureReference<String> {
  _FileContentFutureReference(
      MutableRecording recording, String name, Future<String> future)
      : super(recording, name, future);

  @override
  Future<Null> writeDataToFile(String content) async {
    await file.writeAsString(content, flush: true);
  }
}

class _FileContentReference extends _ExternalReference<String> {
  _FileContentReference(MutableRecording recording, String name, String content)
      : super(recording, name, content);

  @override
  void writeDataToFile(String content) {
    file.writeAsStringSync(content, flush: true);
  }
}

class _LinesFutureReference extends _ExternalFutureReference<List<String>> {
  _LinesFutureReference(
      MutableRecording recording, String name, Future<List<String>> future)
      : super(recording, name, future);

  @override
  Future<Null> writeDataToFile(List<String> lines) async {
    await file.writeAsString(lines.join('\n'), flush: true);
  }
}

class _LinesReference extends _ExternalReference<List<String>> {
  _LinesReference(MutableRecording recording, String name, List<String> lines)
      : super(recording, name, lines);

  @override
  void writeDataToFile(List<String> lines) {
    file.writeAsStringSync(lines.join('\n'), flush: true);
  }
}
