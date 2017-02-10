// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #rename: linkReviver(fileSystem).fuse(kFutureReviver),
      #renameSync: linkReviver(fileSystem),
      #delete: linkReviver(fileSystem).fuse(kFutureReviver),
      #create: linkReviver(fileSystem).fuse(kFutureReviver),
      #createSync: kPassthrough,
      #update: linkReviver(fileSystem).fuse(kFutureReviver),
      #updateSync: kPassthrough,
      #target: kPassthrough.fuse(kFutureReviver),
      #targetSync: kPassthrough,
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #absolute: linkReviver(fileSystem),
    });
  }
}
