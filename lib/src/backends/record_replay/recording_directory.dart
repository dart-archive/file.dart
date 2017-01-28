// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

class _RecordingDirectory
    extends _RecordingFileSystemEntity<Directory, io.Directory>
    implements Directory {
  _RecordingDirectory(RecordingFileSystem fileSystem, io.Directory delegate)
      : super(fileSystem, delegate) {
    methods.addAll(<Symbol, Function>{
      #create: _create,
      #createSync: delegate.createSync,
      #createTemp: _createTemp,
      #createTempSync: _createTempSync,
      #list: _list,
      #listSync: _listSync,
    });
  }

  @override
  Directory _wrap(io.Directory delegate) =>
      super._wrap(delegate) ?? _wrapDirectory(delegate);

  Future<Directory> _create({bool recursive: false}) =>
      delegate.create(recursive: recursive).then(_wrap);

  Future<Directory> _createTemp([String prefix]) =>
      delegate.createTemp(prefix).then(_wrap);

  Directory _createTempSync([String prefix]) =>
      _wrap(delegate.createTempSync(prefix));

  Stream<FileSystemEntity> _list(
          {bool recursive: false, bool followLinks: true}) =>
      delegate
          .list(recursive: recursive, followLinks: followLinks)
          .map(_wrapGeneric);

  List<FileSystemEntity> _listSync(
          {bool recursive: false, bool followLinks: true}) =>
      delegate
          .listSync(recursive: recursive, followLinks: followLinks)
          .map(_wrapGeneric)
          .toList();

  FileSystemEntity _wrapGeneric(io.FileSystemEntity entity) {
    if (entity is io.File) {
      return _wrapFile(entity);
    } else if (entity is io.Directory) {
      return _wrapDirectory(entity);
    } else if (entity is io.Link) {
      return _wrapLink(entity);
    }
    throw new FileSystemException('Unsupported type: $entity', entity.path);
  }
}
