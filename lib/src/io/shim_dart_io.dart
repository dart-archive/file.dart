// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'dart:io' as io;

import 'package:file/src/common.dart' as common;

/// Creates a new [io.Directory] with the specified [path].
io.Directory newDirectory(dynamic path) =>
    new io.Directory(common.getPath(path));

/// Creates a new [io.File] with the specified [path].
io.File newFile(dynamic path) => new io.File(common.getPath(path));

/// Creates a new [io.Link] with the specified [path].
io.Link newLink(dynamic path) => new io.Link(common.getPath(path));

/// Wraps [io.Directory.systemTemp].
io.Directory systemTemp() => io.Directory.systemTemp;

/// Wraps [io.Directory.current].
io.Directory get currentDirectory => io.Directory.current;

/// Wraps [io.Directory.current=].
set currentDirectory(dynamic path) => io.Directory.current = path;

/// Wraps [io.FileStat.stat].
Future<io.FileStat> stat(String path) => io.FileStat.stat(path);

/// Wraps [io.FileStat.statSync].
io.FileStat statSync(String path) => io.FileStat.statSync(path);

/// Wraps [io.FileSystemEntity.identical].
Future<bool> identical(String path1, String path2) =>
    io.FileSystemEntity.identical(path1, path2);

/// Wraps [io.FileSystemEntity.identicalSync].
bool identicalSync(String path1, String path2) =>
    io.FileSystemEntity.identicalSync(path1, path2);

/// Wraps [io.FileSystemEntity.isWatchSupported].
bool get isWatchSupported => io.FileSystemEntity.isWatchSupported;

/// Wraps [io.FileSystemEntity.type].
Future<io.FileSystemEntityType> type(String path, bool followLinks) =>
    io.FileSystemEntity.type(path, followLinks: followLinks);

/// Wraps [io.FileSystemEntity.typeSync].
io.FileSystemEntityType typeSync(String path, bool followLinks) =>
    io.FileSystemEntity.typeSync(path, followLinks: followLinks);
