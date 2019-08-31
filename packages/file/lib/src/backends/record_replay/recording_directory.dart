// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'recording_file_system.dart';
import 'recording_file_system_entity.dart';

/// [Directory] implementation that records all invocation activity to its file
/// system's recording.
class RecordingDirectory extends RecordingFileSystemEntity<Directory>
    implements Directory {
  /// Creates a new `RecordingDirectory`.
  RecordingDirectory(RecordingFileSystem fileSystem, io.Directory delegate)
      : super(fileSystem, delegate) {
    methods.addAll(<Symbol, Function>{
      #create: _create,
      #createSync: delegate.createSync,
      #createTemp: _createTemp,
      #createTempSync: _createTempSync,
      #list: _list,
      #listSync: _listSync,
      #childDirectory: _childDirectory,
      #childFile: _childFile,
      #childLink: _childLink,
    });
  }

  // These four abstract methods, [create], [createSync], [list], and [listSync],
  // are implemented by [noSuchMethod], but their presence here works around
  // https://github.com/dart-lang/sdk/issues/33459, allowing these methods to
  // be called within a Dart 2 runtime.
  // TODO(srawlins): Remove these when the minimum SDK version in
  // `pubspec.yaml` contains a fix for
  // https://github.com/dart-lang/sdk/issues/33459.

  @override
  Future<Directory> create({bool recursive = false});

  @override
  void createSync({bool recursive = false});

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true});

  @override
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true});

  @override
  Directory wrap(Directory delegate) =>
      super.wrap(delegate) ?? wrapDirectory(delegate);

  Future<Directory> _create({bool recursive = false}) =>
      delegate.create(recursive: recursive).then(wrap);

  Future<Directory> _createTemp([String prefix]) =>
      delegate.createTemp(prefix).then(wrap);

  Directory _createTempSync([String prefix]) =>
      wrap(delegate.createTempSync(prefix));

  Stream<FileSystemEntity> _list(
          {bool recursive = false, bool followLinks = true}) =>
      delegate
          .list(recursive: recursive, followLinks: followLinks)
          .map(_wrapGeneric);

  List<FileSystemEntity> _listSync(
          {bool recursive = false, bool followLinks = true}) =>
      delegate
          .listSync(recursive: recursive, followLinks: followLinks)
          .map(_wrapGeneric)
          .toList();

  FileSystemEntity _wrapGeneric(io.FileSystemEntity entity) {
    if (entity is io.File) {
      return wrapFile(entity);
    } else if (entity is io.Directory) {
      return wrapDirectory(entity);
    } else if (entity is io.Link) {
      return wrapLink(entity);
    }
    throw FileSystemException('Unsupported type: $entity', entity.path);
  }

  Directory _childDirectory(String basename) =>
      wrapDirectory(delegate.childDirectory(basename));

  File _childFile(String basename) => wrapFile(delegate.childFile(basename));

  Link _childLink(String basename) => wrapLink(delegate.childLink(basename));
}
