// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';

import 'replay_file_system.dart';
import 'replay_file_system_entity.dart';
import 'resurrectors.dart';

/// [File] implementation that replays all invocation activity from a prior
/// recording.
class ReplayFile extends ReplayFileSystemEntity implements File {
  /// Creates a new `ReplayFile`.
  ReplayFile(ReplayFileSystemImpl fileSystem, String identifier)
      : super(fileSystem, identifier) {
    // TODO(tvolkert): fill in resurrectors
    methods.addAll(<Symbol, Resurrector>{
      #create: null,
      #createSync: null,
      #copy: null,
      #copySync: null,
      #length: null,
      #lengthSync: null,
      #lastModified: null,
      #lastModifiedSync: null,
      #open: null,
      #openSync: null,
      #openRead: null,
      #openWrite: null,
      #readAsBytes: null,
      #readAsBytesSync: null,
      #readAsString: null,
      #readAsStringSync: null,
      #readAsLines: null,
      #readAsLinesSync: null,
      #writeAsBytes: null,
      #writeAsBytesSync: null,
      #writeAsString: null,
      #writeAsStringSync: null,
    });
  }
}
