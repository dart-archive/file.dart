// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'recording_file_system.dart';
import 'recording_file_system_entity.dart';

/// [Link] implementation that records all invocation activity to its file
/// system's recording.
class RecordingLink extends RecordingFileSystemEntity<Link> implements Link {
  /// Creates a new `RecordingLink`.
  RecordingLink(RecordingFileSystem fileSystem, io.Link delegate)
      : super(fileSystem, delegate) {
    methods.addAll(<Symbol, Function>{
      #create: _create,
      #createSync: delegate.createSync,
      #update: _update,
      #updateSync: delegate.updateSync,
      #target: delegate.target,
      #targetSync: delegate.targetSync,
    });
  }

  @override
  Link wrap(Link delegate) => super.wrap(delegate) ?? wrapLink(delegate);

  Future<Link> _create(String target, {bool recursive = false}) =>
      delegate.create(target, recursive: recursive).then(wrap);

  Future<Link> _update(String target) => delegate.update(target).then(wrap);
}
