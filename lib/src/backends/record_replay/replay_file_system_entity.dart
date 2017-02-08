// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';

import 'replay_file_system.dart';
import 'replay_proxy_mixin.dart';
import 'resurrectors.dart';

/// [FileSystemEntity] implementation that replays all invocation activity
/// from a prior recording.
abstract class ReplayFileSystemEntity<T extends FileSystemEntity> extends Object
    with ReplayProxyMixin
    implements FileSystemEntity {
  /// Creates a new `ReplayFileSystemEntity`.
  ReplayFileSystemEntity(this.fileSystem, this.identifier) {
    // TODO(tvolkert): fill in resurrectors
    methods.addAll(<Symbol, Resurrector>{
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
    properties.addAll(<Symbol, Resurrector>{
      #path: resurrectPassthrough,
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
