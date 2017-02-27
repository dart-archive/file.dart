// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.local;

class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, io.Directory>
    with ForwardingDirectory, common.DirectoryAddOnsMixin {
  _LocalDirectory(FileSystem fs, io.Directory delegate) : super(fs, delegate);

  @override
  String toString() => "LocalDirectory: '$path'";
}
