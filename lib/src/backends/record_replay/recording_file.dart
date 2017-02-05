// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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

  @override
  Future<Null> get complete =>
      Future.wait(<Future<dynamic>>[super.complete, _sink.done]);
}

class _ByteArrayFutureReference extends FutureReference<List<int>> {
  final File file;

  _ByteArrayFutureReference(
      MutableRecording recording, String name, Future<List<int>> future)
      : file = recording.newFile(name),
        super(future);

  @override
  Future<List<int>> get value => super.value.then((List<int> bytes) async {
        await file.writeAsBytes(bytes, flush: true);
        return bytes;
      });

  @override
  dynamic get serializedValue => '!${file.basename}';
}

class _ByteArrayReference extends ResultReference<List<int>> {
  final File file;
  final List<int> bytes;

  _ByteArrayReference(MutableRecording recording, String name, this.bytes)
      : file = recording.newFile(name);

  @override
  List<int> get value {
    file.writeAsBytesSync(bytes, flush: true);
    return bytes;
  }

  @override
  List<int> get recordedValue => bytes;

  @override
  dynamic get serializedValue => '!${file.basename}';
}

class _FileContentFutureReference extends FutureReference<String> {
  final File file;

  _FileContentFutureReference(
      MutableRecording recording, String name, Future<String> future)
      : file = recording.newFile(name),
        super(future);

  @override
  Future<String> get value => super.value.then((String content) async {
        await file.writeAsString(content, flush: true);
        return content;
      });

  @override
  dynamic get serializedValue => '!${file.basename}';
}

class _FileContentReference extends ResultReference<String> {
  final File file;
  final String content;

  _FileContentReference(MutableRecording recording, String name, this.content)
      : file = recording.newFile(name);

  @override
  String get value {
    file.writeAsStringSync(content, flush: true);
    return content;
  }

  @override
  String get recordedValue => content;

  @override
  dynamic get serializedValue => '!${file.basename}';
}

class _LinesFutureReference extends FutureReference<List<String>> {
  final File file;

  _LinesFutureReference(
      MutableRecording recording, String name, Future<List<String>> future)
      : file = recording.newFile(name),
        super(future);

  @override
  Future<List<String>> get value =>
      super.value.then((List<String> lines) async {
        await file.writeAsString(lines.join('\n'), flush: true);
        return lines;
      });

  @override
  dynamic get serializedValue => '!${file.basename}';
}

class _LinesReference extends ResultReference<List<String>> {
  final File file;
  final List<String> lines;

  _LinesReference(MutableRecording recording, String name, this.lines)
      : file = recording.newFile(name);

  @override
  List<String> get value {
    file.writeAsStringSync(lines.join('\n'), flush: true);
    return lines;
  }

  @override
  List<String> get recordedValue => lines;

  @override
  dynamic get serializedValue => '!${file.basename}';
}
