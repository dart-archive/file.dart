// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #exists: kPassthrough.fuse(kFutureReviver),
      #existsSync: kPassthrough,
      #resolveSymbolicLinks: kPassthrough.fuse(kFutureReviver),
      #resolveSymbolicLinksSync: kPassthrough,
      #stat: kFileStatReviver.fuse(kFutureReviver),
      #statSync: kFileStatReviver,
      #deleteSync: kPassthrough,
      #watch: listReviver(kFileSystemEventReviver).fuse(kStreamReviver),
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #path: kPassthrough,
      #uri: kUriReviver,
      #isAbsolute: kPassthrough,
      #parent: directoryReviver(fileSystem),
      #basename: kPassthrough,
      #dirname: kPassthrough,
    });
  }

  @override
  final ReplayFileSystemImpl fileSystem;

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => fileSystem.manifest;
}
