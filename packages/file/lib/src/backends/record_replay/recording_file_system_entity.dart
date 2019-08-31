// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

import 'common.dart';
import 'mutable_recording.dart';
import 'recording_directory.dart';
import 'recording_file.dart';
import 'recording_file_system.dart';
import 'recording_link.dart';
import 'recording_proxy_mixin.dart';

/// [FileSystemEntity] implementation that records all invocation activity to
/// its file system's recording.
abstract class RecordingFileSystemEntity<T extends FileSystemEntity>
    extends Object with RecordingProxyMixin implements FileSystemEntity {
  /// Creates a new `RecordingFileSystemEntity`.
  RecordingFileSystemEntity(this.fileSystem, this.delegate) {
    methods.addAll(<Symbol, Function>{
      #exists: delegate.exists,
      #existsSync: delegate.existsSync,
      #rename: _rename,
      #renameSync: _renameSync,
      #resolveSymbolicLinks: delegate.resolveSymbolicLinks,
      #resolveSymbolicLinksSync: delegate.resolveSymbolicLinksSync,
      #stat: delegate.stat,
      #statSync: delegate.statSync,
      #delete: _delete,
      #deleteSync: delegate.deleteSync,
      #watch: delegate.watch,
    });

    properties.addAll(<Symbol, Function>{
      #path: () => delegate.path,
      #uri: () => delegate.uri,
      #isAbsolute: () => delegate.isAbsolute,
      #absolute: _getAbsolute,
      #parent: _getParent,
      #basename: () => delegate.basename,
      #dirname: () => delegate.dirname,
    });
  }

  /// A unique entity id.
  final int uid = newUid();

  @override
  String get identifier => '$runtimeType@$uid';

  @override
  final RecordingFileSystemImpl fileSystem;

  @override
  MutableRecording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  /// The entity to which this entity delegates its functionality while
  /// recording.
  @protected
  final T delegate;

  /// Returns an entity with the same file system and same type as this
  /// entity but backed by the specified delegate.
  ///
  /// This base implementation checks to see if the specified delegate is the
  /// same as this entity's delegate, and if so, it returns this entity.
  /// Otherwise it returns `null`. Subclasses should override this method to
  /// instantiate the correct wrapped type only if this super implementation
  /// returns `null`.
  @protected
  @mustCallSuper
  T wrap(T delegate) => delegate == this.delegate ? this as T : null;

  /// Returns a directory with the same file system as this entity but backed
  /// by the specified delegate directory.
  @protected
  Directory wrapDirectory(io.Directory delegate) =>
      RecordingDirectory(fileSystem, delegate);

  /// Returns a file with the same file system as this entity but backed
  /// by the specified delegate file.
  @protected
  File wrapFile(io.File delegate) => RecordingFile(fileSystem, delegate);

  /// Returns a link with the same file system as this entity but backed
  /// by the specified delegate link.
  @protected
  Link wrapLink(io.Link delegate) => RecordingLink(fileSystem, delegate);

  Future<T> _rename(String newPath) => delegate
      .rename(newPath)
      .then((io.FileSystemEntity entity) => wrap(entity as T));

  T _renameSync(String newPath) => wrap(delegate.renameSync(newPath) as T);

  Future<T> _delete({bool recursive = false}) => delegate
      .delete(recursive: recursive)
      .then((io.FileSystemEntity entity) => wrap(entity as T));

  T _getAbsolute() => wrap(delegate.absolute as T);

  Directory _getParent() => wrapDirectory(delegate.parent);
}
