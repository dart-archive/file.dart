// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'common.dart';
import 'mutable_recording.dart';
import 'recording_file_system.dart';
import 'recording_proxy_mixin.dart';

/// [RandomAccessFile] implementation that records all invocation activity to
/// its file system's recording.
class RecordingRandomAccessFile extends Object
    with RecordingProxyMixin
    implements RandomAccessFile {
  /// Creates a new `RecordingRandomAccessFile`.
  RecordingRandomAccessFile(this.fileSystem, this.delegate) {
    methods.addAll(<Symbol, Function>{
      #close: _close,
      #closeSync: delegate.closeSync,
      #readByte: delegate.readByte,
      #readByteSync: delegate.readByteSync,
      #read: delegate.read,
      #readSync: delegate.readSync,
      #readInto: delegate.readInto,
      #readIntoSync: delegate.readIntoSync,
      #writeByte: _writeByte,
      #writeByteSync: delegate.writeByteSync,
      #writeFrom: _writeFrom,
      #writeFromSync: delegate.writeFromSync,
      #writeString: _writeString,
      #writeStringSync: delegate.writeStringSync,
      #position: delegate.position,
      #positionSync: delegate.positionSync,
      #setPosition: _setPosition,
      #setPositionSync: delegate.setPositionSync,
      #truncate: _truncate,
      #truncateSync: delegate.truncateSync,
      #length: delegate.length,
      #lengthSync: delegate.lengthSync,
      #flush: _flush,
      #flushSync: delegate.flushSync,
      #lock: _lock,
      #lockSync: delegate.lockSync,
      #unlock: _unlock,
      #unlockSync: delegate.unlockSync,
    });

    properties.addAll(<Symbol, Function>{
      #path: () => delegate.path,
    });
  }

  /// The file system that owns this random access file.
  final RecordingFileSystem fileSystem;

  /// The random access file to which this random access file delegates its
  /// functionality while recording.
  final RandomAccessFile delegate;

  /// A unique entity id.
  final int uid = newUid();

  @override
  String get identifier => '$runtimeType@$uid';

  @override
  MutableRecording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  RandomAccessFile _wrap(RandomAccessFile raw) =>
      raw == delegate ? this : RecordingRandomAccessFile(fileSystem, raw);

  Future<void> _close() => delegate.close();

  Future<RandomAccessFile> _writeByte(int value) =>
      delegate.writeByte(value).then(_wrap);

  Future<RandomAccessFile> _writeFrom(List<int> buffer,
          [int start = 0, int end]) =>
      delegate.writeFrom(buffer, start, end).then(_wrap);

  Future<RandomAccessFile> _writeString(String string,
          {Encoding encoding = utf8}) =>
      delegate.writeString(string, encoding: encoding).then(_wrap);

  Future<RandomAccessFile> _setPosition(int position) =>
      delegate.setPosition(position).then(_wrap);

  Future<RandomAccessFile> _truncate(int length) =>
      delegate.truncate(length).then(_wrap);

  Future<RandomAccessFile> _flush() => delegate.flush().then(_wrap);

  Future<RandomAccessFile> _lock(
          [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]) =>
      delegate.lock(mode, start, end).then(_wrap);

  Future<RandomAccessFile> _unlock([int start = 0, int end = -1]) =>
      delegate.unlock(start, end).then(_wrap);
}
