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
    // TODO(tvolkert): fill in resurrectors
    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #exists: null,
      #existsSync: null,
      #rename: null,
      #renameSync: null,
      #resolveSymbolicLinks: null,
      #resolveSymbolicLinksSync: null,
      #stat: null,
      #statSync: null,
      #delete: null,
      #deleteSync: null,
      #watch: null,
    });

    // TODO(tvolkert): fill in resurrectors
    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #path: kPassthrough,
      #uri: null,
      #isAbsolute: null,
      #absolute: null,
      #parent: null,
      #basename: null,
      #dirname: null,
    });
  }

  @override
  final ReplayFileSystemImpl fileSystem;

  @override
  final String identifier;

  @override
  List<Map<String, dynamic>> get manifest => fileSystem.manifest;
}
