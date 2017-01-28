// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

class _RecordingRandomAccessFile extends Object
    with _RecordingProxyMixin
    implements RandomAccessFile {
  final RecordingFileSystem fileSystem;
  final RandomAccessFile delegate;

  _RecordingRandomAccessFile(this.fileSystem, this.delegate) {
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

  /// A unique entity id.
  final int uid = _uid;

  @override
  Recording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  RandomAccessFile _wrap(RandomAccessFile raw) =>
      raw == delegate ? this : new _RecordingRandomAccessFile(fileSystem, raw);

  Future<RandomAccessFile> _close() => delegate.close().then(_wrap);

  Future<RandomAccessFile> _writeByte(int value) =>
      delegate.writeByte(value).then(_wrap);

  Future<RandomAccessFile> _writeFrom(List<int> buffer,
          [int start = 0, int end]) =>
      delegate.writeFrom(buffer, start, end).then(_wrap);

  Future<RandomAccessFile> _writeString(String string,
          {Encoding encoding: UTF8}) =>
      delegate.writeString(string, encoding: encoding).then(_wrap);

  Future<RandomAccessFile> _setPosition(int position) =>
      delegate.setPosition(position).then(_wrap);

  Future<RandomAccessFile> _truncate(int length) =>
      delegate.truncate(length).then(_wrap);

  Future<RandomAccessFile> _flush() => delegate.flush().then(_wrap);

  Future<RandomAccessFile> _lock(
          [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]) =>
      delegate.lock(mode, start, end).then(_wrap);

  Future<RandomAccessFile> _unlock([int start = 0, int end = -1]) =>
      delegate.unlock(start, end).then(_wrap);
}
