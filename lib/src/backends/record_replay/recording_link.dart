// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

class _RecordingLink extends _RecordingFileSystemEntity<Link, io.Link>
    implements Link {
  _RecordingLink(RecordingFileSystem fileSystem, io.Link delegate)
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
  Link _wrap(io.Link delegate) => super._wrap(delegate) ?? _wrapLink(delegate);

  Future<Link> _create(String target, {bool recursive: false}) =>
      delegate.create(target, recursive: recursive).then(_wrap);

  Future<Link> _update(String target) => delegate.update(target).then(_wrap);
}
