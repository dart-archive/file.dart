// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/src/io.dart' as io;

/// Gets the string path represented by the specified generic [path].
String getPath(dynamic path) {
  if (path is io.FileSystemEntity) {
    return path.path;
  } else if (path is String) {
    return path;
  } else if (path is Uri) {
    return path.toFilePath();
  } else {
    throw new ArgumentError('Invalid type for "path": ${path?.runtimeType}');
  }
}
