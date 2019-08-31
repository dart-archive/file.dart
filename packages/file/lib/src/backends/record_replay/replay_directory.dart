// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_file_system_entity.dart';

/// [Directory] implementation that replays all invocation activity from a
/// prior recording.
class ReplayDirectory extends ReplayFileSystemEntity implements Directory {
  /// Creates a new `ReplayDirectory`.
  ReplayDirectory(ReplayFileSystemImpl fileSystem, String identifier)
      : super(fileSystem, identifier) {
    Converter<String, Directory> reviveDirectory = ReviveDirectory(fileSystem);
    Converter<String, Future<Directory>> reviveFutureDirectory =
        reviveDirectory.fuse(const ToFuture<Directory>());
    Converter<String, FileSystemEntity> reviveEntity =
        ReviveFileSystemEntity(fileSystem);
    Converter<List<dynamic>, List<String>> dynamicToString =
        const CastList<dynamic, String>();
    Converter<List<dynamic>, List<FileSystemEntity>> reviveEntities =
        dynamicToString.fuse<List<FileSystemEntity>>(
            ConvertElements<String, FileSystemEntity>(reviveEntity));
    Converter<List<dynamic>, Stream<FileSystemEntity>> reviveEntitiesAsStream =
        reviveEntities
            .fuse<Stream<FileSystemEntity>>(const ToStream<FileSystemEntity>());

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #rename: reviveFutureDirectory,
      #renameSync: reviveDirectory,
      #delete: reviveFutureDirectory,
      #create: reviveFutureDirectory,
      #createSync: const Passthrough<Null>(),
      #createTemp: reviveFutureDirectory,
      #createTempSync: reviveDirectory,
      #list: reviveEntitiesAsStream,
      #listSync: reviveEntities,
      #childDirectory: reviveDirectory,
      #childFile: ReviveFile(fileSystem),
      #childLink: ReviveLink(fileSystem),
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #absolute: reviveDirectory,
    });
  }
}
