// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_proxy_mixin.dart';

/// [IOSink] implementation that replays all invocation activity from a prior
/// recording.
class ReplayIOSink extends Object with ReplayProxyMixin implements IOSink {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new `ReplayIOSink`.
  ReplayIOSink(this._fileSystem, this.identifier) {
    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #add: kPassthrough,
      #write: kPassthrough,
      #writeAll: kPassthrough,
      #writeln: kPassthrough,
      #writeCharCode: kPassthrough,
      #addError: kPassthrough,
      #addStream: kFutureReviver,
      #flush: kFutureReviver,
      #close: kFutureReviver,
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #encoding: kEncodingReviver,
      const Symbol('encoding='): kPassthrough,
      #done: kPassthrough.fuse(kFutureReviver),
    });
  }

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => _fileSystem.manifest;
}
