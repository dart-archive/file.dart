// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_proxy_mixin.dart';

/// [RandomAccessFile] implementation that replays all invocation activity from a prior
/// recording.
class ReplayRandomAccessFile extends Object
    with ReplayProxyMixin
    implements RandomAccessFile {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new `ReplayIOSink`.
  ReplayRandomAccessFile(this._fileSystem, this.identifier) {
    Converter<dynamic, dynamic> convertFutureThis =
        randomAccessFileReviver(_fileSystem).fuse(kFutureReviver);

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #close: convertFutureThis,
      #closeSync: kPassthrough,
      #readByte: kFutureReviver,
      #readByteSync: kPassthrough,
      #read: kFutureReviver,
      #readSync: kPassthrough,
      #readInto: kFutureReviver,
      #readIntoSync: kPassthrough,
      #writeByte: convertFutureThis,
      #writeByteSync: kPassthrough,
      #writeFrom: convertFutureThis,
      #writeFromSync: kPassthrough,
      #writeString: convertFutureThis,
      #writeStringSync: kPassthrough,
      #position: kFutureReviver,
      #positionSync: kPassthrough,
      #setPosition: convertFutureThis,
      #setPositionSync: kPassthrough,
      #truncate: convertFutureThis,
      #truncateSync: kPassthrough,
      #length: kFutureReviver,
      #lengthSync: kPassthrough,
      #flush: convertFutureThis,
      #flushSync: kPassthrough,
      #lock: convertFutureThis,
      #lockSync: kPassthrough,
      #unlock: convertFutureThis,
      #unlockSync: kPassthrough,
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #path: kPassthrough,
    });
  }

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => _fileSystem.manifest;
}
