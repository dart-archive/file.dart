// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_proxy_mixin.dart';

/// [IOSink] implementation that replays all invocation activity from a prior
/// recording.
class ReplayIOSink extends Object with ReplayProxyMixin implements IOSink {
  /// Creates a new [ReplayIOSink].
  ReplayIOSink(this._fileSystem, this.identifier) {
    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #add: const Passthrough<Null>(),
      #write: const Passthrough<Null>(),
      #writeAll: const Passthrough<Null>(),
      #writeln: const Passthrough<Null>(),
      #writeCharCode: const Passthrough<Null>(),
      #addError: const Passthrough<Null>(),
      #addStream: const ToFuture<dynamic>(),
      #flush: const ToFuture<dynamic>(),
      #close: const ToFuture<dynamic>(),
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #encoding: EncodingCodec.deserialize,
      const Symbol('encoding='): const Passthrough<Null>(),
      #done: const ToFuture<dynamic>(),
    });
  }

  final ReplayFileSystemImpl _fileSystem;

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => _fileSystem.manifest;

  @override
  dynamic onResult(Invocation invocation, dynamic result) {
    if (invocation.memberName == #addStream) {
      Stream<List<int>> stream = invocation.positionalArguments.first;
      Future<dynamic> future = result;
      return future.then<void>(stream.drain);
    }
    return result;
  }
}
