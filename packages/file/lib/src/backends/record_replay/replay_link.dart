// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_file_system_entity.dart';

/// [Link] implementation that replays all invocation activity from a prior
/// recording.
class ReplayLink extends ReplayFileSystemEntity implements Link {
  /// Creates a new `ReplayLink`.
  ReplayLink(ReplayFileSystemImpl fileSystem, String identifier)
      : super(fileSystem, identifier) {
    Converter<String, Link> reviveLink = ReviveLink(fileSystem);
    Converter<String, Future<Link>> reviveLinkAsFuture =
        reviveLink.fuse(const ToFuture<Link>());

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #rename: reviveLinkAsFuture,
      #renameSync: reviveLink,
      #delete: reviveLinkAsFuture,
      #create: reviveLinkAsFuture,
      #createSync: const Passthrough<Null>(),
      #update: reviveLinkAsFuture,
      #updateSync: const Passthrough<Null>(),
      #target: const ToFuture<String>(),
      #targetSync: const Passthrough<String>(),
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #absolute: reviveLink,
    });
  }
}
