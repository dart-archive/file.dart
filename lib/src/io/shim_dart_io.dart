import 'dart:async';

import 'dart:io' as io;

io.Directory newDirectory(String path) => new io.Directory(path);
io.File newFile(String path) => new io.File(path);
io.Link newLink(String path) => new io.Link(path);
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
