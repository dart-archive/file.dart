// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// For internal use only!
///
/// This exposes the subset of the `dart:io` interfaces that are required by
/// the `file` package. The `file` package re-exports these interfaces (or in
/// some cases, implementations of these interfaces by the same name), so this
/// file need not be exposes publicly and exists for internal use only.
///
/// For VM users, this exports the actual `dart:io` interfaces; for browser
/// contexts, this exports locally-defined versions of those same interfaces.
export 'io/interface.dart' if (dart.library.io) 'dart:io'
    show
        Directory,
        File,
        FileLock,
        FileMode,
        FileStat,
        FileSystemEntity,
        FileSystemEntityType,
        FileSystemEvent,
        FileSystemException,
        IOException,
        IOSink,
        Link,
        OSError,
        RandomAccessFile;
