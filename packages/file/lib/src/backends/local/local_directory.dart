// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/src/common.dart' as common;
import 'package:file/src/forwarding.dart';
import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';

import 'local_file_system_entity.dart';

/// [Directory] implementation that forwards all calls to `dart:io`.
class LocalDirectory extends LocalFileSystemEntity<LocalDirectory, io.Directory>
    with ForwardingDirectory<LocalDirectory>, common.DirectoryAddOnsMixin {
  /// Instantiates a new [LocalDirectory] tied to the specified file system
  /// and delegating to the specified [delegate].
  LocalDirectory(FileSystem fs, io.Directory delegate) : super(fs, delegate);

  @override
  String toString() => "LocalDirectory: '$path'";

  @override
  Future<LocalDirectory> create({bool recursive: false}) async =>
      wrap(await delegate.create(recursive: recursive));

  @override
  Future<LocalDirectory> delete({bool recursive: false}) async =>
      wrap(await delegate.delete(recursive: recursive));

  @override
  Future<LocalDirectory> rename(String newPath) async =>
      wrap(await delegate.rename(newPath));

  @override
  Future<LocalDirectory> createTemp([String prefix]) async =>
      wrap(await delegate.createTemp(prefix));
}
