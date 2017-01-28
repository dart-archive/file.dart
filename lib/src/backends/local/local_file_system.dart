// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.local;

/// A wrapper implementation around `dart:io`'s implementation.
///
/// Since this implementation of the [FileSystem] interface delegates to
/// `dart:io`, is is not suitable for use in the browser.
class LocalFileSystem extends FileSystem {
  const LocalFileSystem();

  @override
  Directory directory(path) =>
      new _LocalDirectory(this, shim.newDirectory(path));

  @override
  File file(path) => new _LocalFile(this, shim.newFile(path));

  @override
  Link link(path) => new _LocalLink(this, shim.newLink(path));

  @override
  p.Context get path => new p.Context();

  /// Gets the directory provided by the operating system for creating temporary
  /// files and directories in. The location of the system temp directory is
  /// platform-dependent, and may be set by an environment variable.
  @override
  Directory get systemTempDirectory =>
      new _LocalDirectory(this, shim.systemTemp());

  @override
  Directory get currentDirectory => directory(shim.currentDirectory.path);

  @override
  set currentDirectory(dynamic path) => shim.currentDirectory = path;

  @override
  Future<io.FileStat> stat(String path) => shim.stat(path);

  @override
  io.FileStat statSync(String path) => shim.statSync(path);

  @override
  Future<bool> identical(String path1, String path2) =>
      shim.identical(path1, path2);

  @override
  bool identicalSync(String path1, String path2) =>
      shim.identicalSync(path1, path2);

  @override
  bool get isWatchSupported => shim.isWatchSupported;

  @override
  Future<io.FileSystemEntityType> type(String path, {bool followLinks: true}) =>
      shim.type(path, followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks: true}) =>
      shim.typeSync(path, followLinks);
}
