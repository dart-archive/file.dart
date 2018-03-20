// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.local;

/// A wrapper implementation around `dart:io`'s implementation.
///
/// Since this implementation of the [FileSystem] interface delegates to
/// `dart:io`, is is not suitable for use in the browser.
class LocalFileSystem extends FileSystem {
  /// Creates a new `LocalFileSystem`.
  const LocalFileSystem();

  @override
  Directory directory(dynamic path) =>
      new _LocalDirectory(this, new io.Directory(getPath(path)));

  @override
  File file(dynamic path) => new _LocalFile(this, new io.File(getPath(path)));

  @override
  Link link(dynamic path) => new _LocalLink(this, new io.Link(getPath(path)));

  @override
  p.Context get path => new p.Context();

  /// Gets the directory provided by the operating system for creating temporary
  /// files and directories in. The location of the system temp directory is
  /// platform-dependent, and may be set by an environment variable.
  @override
  Directory get systemTempDirectory =>
      new _LocalDirectory(this, io.Directory.systemTemp);

  @override
  Directory get currentDirectory => directory(io.Directory.current.path);

  @override
  set currentDirectory(dynamic path) => io.Directory.current = path;

  @override
  Future<io.FileStat> stat(String path) => io.FileStat.stat(path);

  @override
  io.FileStat statSync(String path) => io.FileStat.statSync(path);

  @override
  Future<bool> identical(String path1, String path2) =>
      io.FileSystemEntity.identical(path1, path2);

  @override
  bool identicalSync(String path1, String path2) =>
      io.FileSystemEntity.identicalSync(path1, path2);

  @override
  bool get isWatchSupported => io.FileSystemEntity.isWatchSupported;

  @override
  Future<io.FileSystemEntityType> type(String path, {bool followLinks: true}) =>
      io.FileSystemEntity.type(path, followLinks: followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks: true}) =>
      io.FileSystemEntity.typeSync(path, followLinks: followLinks);
}
