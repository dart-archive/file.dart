// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/src/io.dart' as io;

const String _requiresIOMsg = 'This operation requires the use of dart:io';
dynamic _requiresIO() => throw new UnsupportedError(_requiresIOMsg);

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.Directory newDirectory(_) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.File newFile(_) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.Link newLink(_) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.Directory systemTemp() => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.Directory get currentDirectory => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
set currentDirectory(dynamic _) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
Future<io.FileStat> stat(String _) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.FileStat statSync(String _) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
Future<bool> identical(String _, String __) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
bool identicalSync(String _, String __) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
bool get isWatchSupported => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
Future<io.FileSystemEntityType> type(String _, bool __) => _requiresIO();

/// Throws [UnsupportedError]; browsers cannot use the `local` library.
io.FileSystemEntityType typeSync(String _, bool __) => _requiresIO();
