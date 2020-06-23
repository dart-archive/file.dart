// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
    Converter<String, File> reviveFile = ReviveFile(fileSystem);
    Converter<String, Future<File>> reviveFileAsFuture =
        reviveFile.fuse(const ToFuture<File>());
    Converter<String, Uint8List> blobToBytes = BlobToBytes(fileSystem);
    Converter<String, Future<Uint8List>> blobToBytesFuture =
        blobToBytes.fuse(const ToFuture<Uint8List>());
    Converter<String, String> blobToString =
        blobToBytes.cast<String, List<int>>().fuse(utf8.decoder);
    Converter<String, Future<String>> blobToStringFuture =
        blobToString.fuse(const ToFuture<String>());
    Converter<String, RandomAccessFile> reviveRandomAccessFile =
        ReviveRandomAccessFile(fileSystem);
    Converter<String, Future<RandomAccessFile>> reviveRandomAccessFileFuture =
        reviveRandomAccessFile.fuse(const ToFuture<RandomAccessFile>());
    Converter<String, List<String>> lineSplitter =
        const LineSplitterConverter();
    Converter<String, List<String>> blobToLines =
        blobToString.fuse(lineSplitter);
    Converter<String, Future<List<String>>> blobToLinesFuture =
        blobToLines.fuse(const ToFuture<List<String>>());
    Converter<String, Stream<Uint8List>> blobToByteStream = blobToBytes
        .fuse(const Listify<Uint8List>())
        .fuse(const ToStream<Uint8List>());
    Converter<int, Future<DateTime>> reviveDateTime =
        DateTimeCodec.deserialize.fuse(const ToFuture<DateTime>());

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
      #lastAccessed: reviveDateTime,
      #lastAccessedSync: DateTimeCodec.deserialize,
      #setLastAccessed: const ToFuture<dynamic>(),
      #setLastAccessedSync: const Passthrough<Null>(),
      #lastModified: reviveDateTime,
      #lastModifiedSync: DateTimeCodec.deserialize,
      #setLastModified: const ToFuture<dynamic>(),
      #setLastModifiedSync: const Passthrough<Null>(),
      #open: reviveRandomAccessFileFuture,
      #openSync: reviveRandomAccessFile,
      #openRead: blobToByteStream,
      #openWrite: ReviveIOSink(fileSystem),
      #readAsBytes: blobToBytesFuture,
      #readAsBytesSync: blobToBytes,
      #readAsString: blobToStringFuture,
      #readAsStringSync: blobToString,
      #readAsLines: blobToLinesFuture,
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
