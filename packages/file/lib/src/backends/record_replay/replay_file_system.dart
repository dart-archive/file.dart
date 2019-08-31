// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

import 'codecs.dart';
import 'common.dart';
import 'errors.dart';
import 'recording_file_system.dart';
import 'replay_proxy_mixin.dart';

/// A file system that replays invocations from a prior recording for use
/// in tests.
///
/// This will replay all invocations (methods, property getters, and property
/// setters) that occur on it, based on an opaque recording that was generated
/// in [RecordingFileSystem]. All activity in the [File], [Directory], [Link],
/// [IOSink], and [RandomAccessFile] instances returned from this API will also
/// be replayed from the same recording.
///
/// Once an invocation has been replayed once, it is marked as such and will
/// not be eligible for further replay. If an eligible invocation cannot be
/// found that matches an incoming invocation, a [NoMatchingInvocationError]
/// will be thrown.
///
/// This class is intended for use in tests, where you would otherwise have to
/// set up complex mocks or fake file systems. With this class, the process is
/// as follows:
///
///   - You record the file system activity during a real run of your program
///     by injecting a `RecordingFileSystem` that delegates to your real file
///     system.
///   - You serialize that recording to disk as your program finishes.
///   - You use that recording in tests to create a mock file system that knows
///     how to respond to the exact invocations your program makes. Any
///     invocations that aren't in the recording will throw, and you can make
///     assertions in your tests about which methods were invoked and in what
///     order.
///
/// *Implementation note*: this class uses [noSuchMethod] to dynamically handle
/// invocations. As a result, method references on objects herein will not pass
/// `is` checks or checked-mode checks on type. For example:
///
/// ```dart
/// typedef FileStat StatSync(String path);
/// FileSystem fs = ReplayFileSystem(directory);
///
/// StatSync method = fs.statSync;     // Will fail in checked-mode
/// fs.statSync is StatSync            // Will return false
/// fs.statSync is Function            // Will return false
///
/// dynamic method2 = fs.statSync;     // OK
/// FileStat stat = method2('/path');  // OK
/// ```
///
/// See also:
///   - [RecordingFileSystem]
abstract class ReplayFileSystem extends FileSystem {
  /// Creates a new `ReplayFileSystem`.
  ///
  /// Recording data will be loaded from the specified [recording] location.
  /// This location must have been created by [RecordingFileSystem], or an
  /// [ArgumentError] will be thrown.
  factory ReplayFileSystem({
    @required Directory recording,
  }) {
    String dirname = recording.path;
    String path = recording.fileSystem.path.join(dirname, kManifestName);
    File manifestFile = recording.fileSystem.file(path);
    if (!manifestFile.existsSync()) {
      throw ArgumentError('Not a valid recording directory: $dirname');
    }
    List<Map<String, dynamic>> manifest = const JsonDecoder()
        .convert(manifestFile.readAsStringSync())
        .cast<Map<String, dynamic>>();
    return ReplayFileSystemImpl(recording, manifest);
  }
}

/// Non-exported implementation class for `ReplayFileSystem`.
class ReplayFileSystemImpl extends FileSystem
    with ReplayProxyMixin
    implements ReplayFileSystem, ReplayAware {
  /// Creates a new `ReplayFileSystemImpl`.
  ReplayFileSystemImpl(this.recording, this.manifest) {
    Converter<String, Directory> reviveDirectory = ReviveDirectory(this);
    Converter<String, Future<FileSystemEntityType>> reviveEntityFuture =
        EntityTypeCodec.deserialize
            .fuse(const ToFuture<FileSystemEntityType>());
    Converter<Map<String, Object>, Future<FileStat>> reviveFileStatFuture =
        FileStatCodec.deserialize.fuse(const ToFuture<FileStat>());

    methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #directory: reviveDirectory,
      #file: ReviveFile(this),
      #link: ReviveLink(this),
      #stat: reviveFileStatFuture,
      #statSync: FileStatCodec.deserialize,
      #identical: const ToFuture<bool>(),
      #identicalSync: const Passthrough<bool>(),
      #type: reviveEntityFuture,
      #typeSync: EntityTypeCodec.deserialize,
    });

    properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
      #path: PathContextCodec.deserialize,
      #systemTempDirectory: reviveDirectory,
      #currentDirectory: reviveDirectory,
      const Symbol('currentDirectory='): const Passthrough<Null>(),
      #isWatchSupported: const Passthrough<bool>(),
    });
  }

  /// The location of the recording that's driving this file system
  final Directory recording;

  @override
  String get identifier => kFileSystemEncodedValue;

  @override
  final List<Map<String, dynamic>> manifest;
}
