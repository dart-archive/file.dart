// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_file_system_entity.dart';

/// [File] implementation that replays all invocation activity from a prior
/// recording.
class ReplayFile extends ReplayFileSystemEntity implements File {
  /// Creates a new `ReplayFile`.
  ReplayFile(ReplayFileSystemImpl fileSystem, String identifier)
      : super(fileSystem, identifier) {
    Converter<dynamic, dynamic> convertThis = fileReviver(fileSystem);
    Converter<dynamic, dynamic> convertFutureThis =
        convertThis.fuse(kFutureReviver);

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #rename: convertFutureThis,
      #renameSync: convertThis,
      #delete: convertFutureThis,
      #create: convertFutureThis,
      #createSync: kPassthrough,
      #copy: convertFutureThis,
      #copySync: convertThis,
      #length: kFutureReviver,
      #lengthSync: kPassthrough,
      #lastModified: kDateTimeReviver.fuse(kFutureReviver),
      #lastModifiedSync: kDateTimeReviver,
      #open: randomAccessFileReviver(fileSystem).fuse(kFutureReviver),
      #openSync: randomAccessFileReviver(fileSystem),
      #openRead: kStreamReviver,
      #openWrite: ioSinkReviver(fileSystem),
      #readAsBytes: blobReviver(fileSystem).fuse(kFutureReviver),
      #readAsBytesSync: blobReviver(fileSystem),
      #readAsString: kFutureReviver,
      #readAsStringSync: kPassthrough,
      #readAsLines: kFutureReviver,
      #readAsLinesSync: kPassthrough,
      #writeAsBytes: convertFutureThis,
      #writeAsBytesSync: kPassthrough,
      #writeAsString: convertFutureThis,
      #writeAsStringSync: kPassthrough,
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #absolute: convertThis,
    });
  }
}
