// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io
    show
        ConnectionTask,
        IOOverrides,
        ServerSocket,
        Socket,
        stderr,
        Stdin,
        stdin,
        Stdout,
        stdout;

import 'interface.dart';
import 'io.dart' as io;

/// Internal base class for [IOOverrides] implementations backed by a
/// specified [FileSystem].
///
/// Operations that are not filesystem-related fall back to the normal
/// `dart:io` implementations.
///
/// Do not use this with a [LocalFileSystem]; doing so would cause overridden
/// operations to create infinite recursion loops.  To reduce the likelihood of
/// such problems, this class is not exported and is not intended to be used
/// directly.
abstract class FileSystemIOOverrides implements io.IOOverrides {
  final FileSystem fs;

  FileSystemIOOverrides(this.fs);

  @override
  io.Stdout get stderr => io.stderr;

  @override
  io.Stdin get stdin => io.stdin;

  @override
  io.Stdout get stdout => io.stdout;

  @override
  Directory createDirectory(String path) => fs.directory(path);

  @override
  File createFile(String path) => fs.file(path);

  @override
  Link createLink(String path) => fs.link(path);

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) =>
      fs.type(path, followLinks: followLinks);

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) =>
      fs.typeSync(path, followLinks: followLinks);

  @override
  Future<bool> fseIdentical(String path1, String path2) =>
      fs.identical(path1, path2);

  @override
  bool fseIdenticalSync(String path1, String path2) =>
      fs.identicalSync(path1, path2);

  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    var entityType = fs.typeSync(path, followLinks: false);
    late FileSystemEntity entity;
    switch (entityType) {
      case FileSystemEntityType.directory:
        entity = fs.directory(path);
        break;
      case io.FileSystemEntityType.file:
        entity = fs.file(path);
        break;
      case io.FileSystemEntityType.link:
        entity = fs.link(path);
        break;
      case io.FileSystemEntityType.notFound:
      case io.FileSystemEntityType.pipe:
      case io.FileSystemEntityType.unixDomainSock:
        throw UnsupportedError(
          'Unsupported FileSystemEntity type for $path: $entityType',
        );
    }

    return entity.watch(events: events, recursive: recursive);
  }

  @override
  bool fsWatchIsSupported() => fs.isWatchSupported;

  @override
  Directory getCurrentDirectory() => fs.currentDirectory;

  @override
  Directory getSystemTempDirectory() => fs.systemTempDirectory;

  @override
  Future<io.ServerSocket> serverSocketBind(
    dynamic address,
    int port, {
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  }) =>
      io.ServerSocket.bind(
        address,
        port,
        backlog: backlog,
        v6Only: v6Only,
        shared: shared,
      );

  @override
  void setCurrentDirectory(String path) =>
      fs.currentDirectory = fs.directory(path);

  @override
  Future<io.Socket> socketConnect(
    dynamic host,
    int port, {
    dynamic sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) =>
      io.Socket.connect(
        host,
        port,
        sourceAddress: sourceAddress,
        sourcePort: sourcePort,
        timeout: timeout,
      );

  @override
  Future<io.ConnectionTask<io.Socket>> socketStartConnect(
    dynamic host,
    int port, {
    dynamic sourceAddress,
    int sourcePort = 0,
  }) =>
      io.Socket.startConnect(
        host,
        port,
        sourceAddress: sourceAddress,
        sourcePort: sourcePort,
      );

  @override
  Future<FileStat> stat(String path) => fs.stat(path);

  @override
  FileStat statSync(String path) => fs.statSync(path);
}
