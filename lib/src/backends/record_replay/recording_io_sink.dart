// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

class _RecordingIOSink extends Object
    with _RecordingProxyMixin
    implements IOSink {
  final RecordingFileSystem fileSystem;
  final IOSink delegate;

  _RecordingIOSink(this.fileSystem, this.delegate) {
    methods.addAll(<Symbol, Function>{
      #add: delegate.add,
      #write: delegate.write,
      #writeAll: delegate.writeAll,
      #writeln: delegate.writeln,
      #writeCharCode: delegate.writeCharCode,
      #addError: delegate.addError,
      #addStream: delegate.addStream,
      #flush: delegate.flush,
      #close: delegate.close,
    });

    properties.addAll(<Symbol, Function>{
      #encoding: () => delegate.encoding,
      const Symbol('encoding='): _setEncoding,
      #done: () => delegate.done,
    });
  }

  /// A unique entity id.
  final int uid = _uid;

  @override
  Recording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  void _setEncoding(Encoding value) {
    delegate.encoding = value;
  }
}
