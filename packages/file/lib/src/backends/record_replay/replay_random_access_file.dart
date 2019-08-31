// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_proxy_mixin.dart';

/// [RandomAccessFile] implementation that replays all invocation activity from a prior
/// recording.
class ReplayRandomAccessFile extends Object
    with ReplayProxyMixin
    implements RandomAccessFile {
  /// Creates a new [ReplayRandomAccessFile].
  ReplayRandomAccessFile(this._fileSystem, this.identifier) {
    ToFuture<RandomAccessFile> toFuture = const ToFuture<RandomAccessFile>();
    Converter<String, Future<RandomAccessFile>> reviveRandomAccessFileAsFuture =
        ReviveRandomAccessFile(_fileSystem).fuse(toFuture);

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #close: reviveRandomAccessFileAsFuture,
      #closeSync: const Passthrough<Null>(),
      #readByte: const ToFuture<int>(),
      #readByteSync: const Passthrough<int>(),
      #read: const ToFuture<Uint8List>(),
      #readSync: const Passthrough<Uint8List>(),
      #readInto: const ToFuture<int>(),
      #readIntoSync: const Passthrough<int>(),
      #writeByte: reviveRandomAccessFileAsFuture,
      #writeByteSync: const Passthrough<int>(),
      #writeFrom: reviveRandomAccessFileAsFuture,
      #writeFromSync: const Passthrough<Null>(),
      #writeString: reviveRandomAccessFileAsFuture,
      #writeStringSync: const Passthrough<Null>(),
      #position: const ToFuture<int>(),
      #positionSync: const Passthrough<int>(),
      #setPosition: reviveRandomAccessFileAsFuture,
      #setPositionSync: const Passthrough<Null>(),
      #truncate: reviveRandomAccessFileAsFuture,
      #truncateSync: const Passthrough<Null>(),
      #length: const ToFuture<int>(),
      #lengthSync: const Passthrough<int>(),
      #flush: reviveRandomAccessFileAsFuture,
      #flushSync: const Passthrough<Null>(),
      #lock: reviveRandomAccessFileAsFuture,
      #lockSync: const Passthrough<Null>(),
      #unlock: reviveRandomAccessFileAsFuture,
      #unlockSync: const Passthrough<Null>(),
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #path: const Passthrough<String>(),
    });
  }

  final ReplayFileSystemImpl _fileSystem;

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => _fileSystem.manifest;
}
