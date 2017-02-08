// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'replay_file_stat.dart';

/// Resurrects an invocation result (return value) from the specified
/// serialized [data].
@protected
typedef Object Resurrector(dynamic data);

/// Returns a [Resurrector] that will wrap the return value of the specified
/// [delegate] in a [Future].
Resurrector resurrectFuture(Resurrector delegate) {
  return (dynamic serializedResult) async {
    return delegate(serializedResult);
  };
}

/// Resurrects a [FileStat] from the specified serialized [data].
FileStat resurrectFileStat(Map<String, dynamic> data) {
  return new ReplayFileStat(data);
}

/// Resurrects a [DateTime] from the specified [milliseconds] since the epoch.
DateTime resurrectDateTime(int milliseconds) {
  return new DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

/// Resurrects a [FileSystemEntityType] from the specified string
/// representation.
FileSystemEntityType resurrectFileSystemEntityType(String type) {
  return <String, FileSystemEntityType>{
    'FILE': FileSystemEntityType.FILE,
    'DIRECTORY': FileSystemEntityType.DIRECTORY,
    'LINK': FileSystemEntityType.LINK,
    'NOT_FOUND': FileSystemEntityType.NOT_FOUND,
  }[type];
}

/// Resurrects a value whose serialized representation is the same the real
/// value.
dynamic resurrectPassthrough(dynamic value) => value;

/// Resurrects a [path.Context] from the specified serialized [data]
path.Context resurrectPathContext(Map<String, String> data) {
  return new path.Context(
    style: <String, path.Style>{
      'posix': path.Style.posix,
      'windows': path.Style.windows,
      'url': path.Style.url,
    }[data['style']],
    current: data['cwd'],
  );
}
