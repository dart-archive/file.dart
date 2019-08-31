// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_proxy_mixin.dart';

/// [FileSystemEntity] implementation that replays all invocation activity
/// from a prior recording.
abstract class ReplayFileSystemEntity extends Object
    with ReplayProxyMixin
    implements FileSystemEntity {
  /// Creates a new `ReplayFileSystemEntity`.
  ReplayFileSystemEntity(this.fileSystem, this.identifier) {
    Converter<List<Map<String, Object>>, List<FileSystemEvent>> toEvents =
        const ConvertElements<Map<String, Object>, FileSystemEvent>(
            FileSystemEventCodec.deserialize);
    Converter<List<Map<String, Object>>, Stream<FileSystemEvent>>
        toEventStream = toEvents.fuse(const ToStream<FileSystemEvent>());
    Converter<Map<String, Object>, Future<FileStat>> reviveFileStatFuture =
        FileStatCodec.deserialize.fuse(const ToFuture<FileStat>());

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #exists: const ToFuture<bool>(),
      #existsSync: const Passthrough<bool>(),
      #resolveSymbolicLinks: const ToFuture<String>(),
      #resolveSymbolicLinksSync: const Passthrough<String>(),
      #stat: reviveFileStatFuture,
      #statSync: FileStatCodec.deserialize,
      #deleteSync: const Passthrough<Null>(),
      #watch: toEventStream,
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #path: const Passthrough<String>(),
      #uri: UriCodec.deserialize,
      #isAbsolute: const Passthrough<bool>(),
      #parent: ReviveDirectory(fileSystem),
      #basename: const Passthrough<String>(),
      #dirname: const Passthrough<String>(),
    });
  }

  @override
  final ReplayFileSystemImpl fileSystem;

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => fileSystem.manifest;
}
