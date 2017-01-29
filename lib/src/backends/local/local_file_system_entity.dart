// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.local;

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {
  @override
  final FileSystem fileSystem;

  @override
  final D delegate;

  _LocalFileSystemEntity(this.fileSystem, this.delegate);

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      new _LocalDirectory(fileSystem, delegate);

  @override
  File wrapFile(io.File delegate) => new _LocalFile(fileSystem, delegate);

  @override
  Link wrapLink(io.Link delegate) => new _LocalLink(fileSystem, delegate);
}
