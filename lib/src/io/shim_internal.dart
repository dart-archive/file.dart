import 'dart:async';

import 'package:file/src/io.dart' as io;

const String _requiresIOMsg = 'This operation requires the use of dart:io';
dynamic _requiresIO() => throw new UnsupportedError(_requiresIOMsg);

io.Directory newDirectory(_) => _requiresIO();
io.File newFile(_) => _requiresIO();
io.Link newLink(_) => _requiresIO();
io.Directory get currentDirectory => _requiresIO();
set currentDirectory(dynamic _) => _requiresIO();
Future<io.FileStat> stat(String _) => _requiresIO();
io.FileStat statSync(String _) => _requiresIO();
Future<bool> identical(String _, String __) => _requiresIO();
bool identicalSync(String _, String __) => _requiresIO();
bool get isWatchSupported => _requiresIO();
Future<io.FileSystemEntityType> type(String _, bool __) => _requiresIO();
io.FileSystemEntityType typeSync(String _, bool __) => _requiresIO();
