import 'dart:async';

import 'dart:io' as io;

import 'package:file/src/common.dart' as common;

io.Directory newDirectory(path) => new io.Directory(common.getPath(path));
io.File newFile(path) => new io.File(common.getPath(path));
io.Link newLink(path) => new io.Link(common.getPath(path));
io.Directory systemTemp() => io.Directory.systemTemp;
io.Directory get currentDirectory => io.Directory.current;
set currentDirectory(dynamic path) => io.Directory.current = path;
Future<io.FileStat> stat(String path) => io.FileStat.stat(path);
io.FileStat statSync(String path) => io.FileStat.statSync(path);
Future<bool> identical(String path1, String path2) =>
    io.FileSystemEntity.identical(path1, path2);
bool identicalSync(String path1, String path2) =>
    io.FileSystemEntity.identicalSync(path1, path2);
bool get isWatchSupported => io.FileSystemEntity.isWatchSupported;
Future<io.FileSystemEntityType> type(String path, bool followLinks) =>
    io.FileSystemEntity.type(path, followLinks: followLinks);
io.FileSystemEntityType typeSync(String path, bool followLinks) =>
    io.FileSystemEntity.typeSync(path, followLinks: followLinks);
