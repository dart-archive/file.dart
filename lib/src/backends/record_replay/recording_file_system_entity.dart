// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

abstract class _RecordingFileSystemEntity<T extends FileSystemEntity,
        D extends io.FileSystemEntity> extends Object
    with _RecordingProxyMixin
    implements FileSystemEntity {
  _RecordingFileSystemEntity(this.fileSystem, this.delegate) {
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
    });
  }

  /// A unique entity id.
  final int uid = _uid;

  @override
  final RecordingFileSystem fileSystem;

  @override
  Recording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  final D delegate;

  /// Returns an entity with the same file system and same type as this
  /// entity but backed by the specified delegate.
  ///
  /// If the specified delegate is the same as this entity's delegate, this
  /// will return this entity.
  ///
  /// Subclasses should override this method to instantiate the correct wrapped
  /// type if this super implementation returns `null`.
  @mustCallSuper
  T _wrap(D delegate) => delegate == this.delegate ? this as T : null;

  Directory _wrapDirectory(io.Directory delegate) =>
      new _RecordingDirectory(fileSystem, delegate);

  File _wrapFile(io.File delegate) => new _RecordingFile(fileSystem, delegate);

  Link _wrapLink(io.Link delegate) => new _RecordingLink(fileSystem, delegate);

  Future<T> _rename(String newPath) => delegate
      .rename(newPath)
      .then((io.FileSystemEntity entity) => _wrap(entity as D));

  T _renameSync(String newPath) => _wrap(delegate.renameSync(newPath) as D);

  Future<T> _delete({bool recursive: false}) => delegate
      .delete(recursive: recursive)
      .then((io.FileSystemEntity entity) => _wrap(entity as D));

  T _getAbsolute() => _wrap(delegate.absolute as D);

  Directory _getParent() => _wrapDirectory(delegate.parent);
}
