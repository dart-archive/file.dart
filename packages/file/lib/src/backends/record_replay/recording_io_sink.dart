// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';

import 'common.dart';
import 'mutable_recording.dart';
import 'recording_file_system.dart';
import 'recording_proxy_mixin.dart';

/// [IOSink] implementation that records all invocation activity to its file
/// system's recording.
class RecordingIOSink extends Object
    with RecordingProxyMixin
    implements IOSink {
  /// Creates a new `RecordingIOSink`.
  RecordingIOSink(this.fileSystem, this.delegate) {
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

  /// The file system that owns this sink.
  final RecordingFileSystem fileSystem;

  /// The sink to which this sink delegates its functionality while recording.
  final IOSink delegate;

  /// A unique entity id.
  final int uid = newUid();

  @override
  String get identifier => '$runtimeType@$uid';

  @override
  MutableRecording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  void _setEncoding(Encoding value) {
    delegate.encoding = value;
  }
}
