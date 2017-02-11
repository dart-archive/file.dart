// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'codecs.dart';
import 'replay_file_system.dart';
import 'replay_file_system_entity.dart';

/// [File] implementation that replays all invocation activity from a prior
/// recording.
class ReplayFile extends ReplayFileSystemEntity implements File {
  /// Creates a new `ReplayFile`.
  ReplayFile(ReplayFileSystemImpl fileSystem, String identifier)
      : super(fileSystem, identifier) {
    Converter<String, File> reviveFile = new ReviveFile(fileSystem);
    Converter<String, Future<File>> reviveFileAsFuture =
        reviveFile.fuse(const ToFuture<File>());
    Converter<String, List<int>> blobToBytes = new BlobToBytes(fileSystem);
    Converter<String, String> blobToString = blobToBytes.fuse(UTF8.decoder);
    Converter<String, RandomAccessFile> reviveRandomAccessFile =
        new ReviveRandomAccessFile(fileSystem);
    // TODO(tvolkert) remove `as`: https://github.com/dart-lang/sdk/issues/28748
    Converter<String, List<String>> lineSplitter =
        const LineSplitter() as Converter<String, List<String>>;
    Converter<String, List<String>> blobToLines =
        blobToString.fuse(lineSplitter);
    Converter<String, Stream<List<int>>> blobToByteStream = blobToBytes
        .fuse(const Listify<List<int>>())
        .fuse(const ToStream<List<int>>());

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #rename: reviveFileAsFuture,
      #renameSync: reviveFile,
      #delete: reviveFileAsFuture,
      #create: reviveFileAsFuture,
      #createSync: const Passthrough<Null>(),
      #copy: reviveFileAsFuture,
      #copySync: reviveFile,
      #length: const ToFuture<int>(),
      #lengthSync: const Passthrough<int>(),
      #lastModified: DateTimeCodec.deserialize.fuse(const ToFuture<DateTime>()),
      #lastModifiedSync: DateTimeCodec.deserialize,
      #open: reviveRandomAccessFile.fuse(const ToFuture<RandomAccessFile>()),
      #openSync: reviveRandomAccessFile,
      #openRead: blobToByteStream,
      #openWrite: new ReviveIOSink(fileSystem),
      #readAsBytes: blobToBytes.fuse(const ToFuture<List<int>>()),
      #readAsBytesSync: blobToBytes,
      #readAsString: blobToString.fuse(const ToFuture<String>()),
      #readAsStringSync: blobToString,
      #readAsLines: blobToLines.fuse(const ToFuture<List<String>>()),
      #readAsLinesSync: blobToLines,
      #writeAsBytes: reviveFileAsFuture,
      #writeAsBytesSync: const Passthrough<Null>(),
      #writeAsString: reviveFileAsFuture,
      #writeAsStringSync: const Passthrough<Null>(),
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #absolute: reviveFile,
    });
  }
}
