/// The synchronous version of the same API.
///
/// WARNING: synchronous API will block, which prevents parallelization of
/// operations and, if used on a UI, could result in missed frames. It is also
/// generally not possible to implement a synchronous API on top of an
/// asynchronous one. This API is mostly useful for gradual migration of
/// existing code that currently relies on synchronous API from `dart:io`. It is
/// almost always preferable to use the asynchronous API.
library file.src.interface.sync;

import 'interface.dart' show FileSystemEntityType;
export 'interface.dart'
    show FileSystemEntityType, getParentPath, FileSystemEntityException;

abstract class SyncFileSystem {
  SyncDirectory directory(String path);
  SyncFile file(String path);
  FileSystemEntityType type(String path, {bool followLinks: true});
}

abstract class SyncFileSystemEntity {
  SyncFileSystemEntity copy(String newPath);
  SyncFileSystemEntity create({bool recursive: false});
  SyncFileSystemEntity delete({bool recursive: false});
  bool exists();
  SyncFileSystem get fileSystem;
  SyncDirectory get parent;
  String get path;
  SyncFileSystemEntity rename(String newPath);
}

abstract class SyncDirectory implements SyncFileSystemEntity {
  @override
  bool exists() => fileSystem.type(path) == FileSystemEntityType.DIRECTORY;
  List<SyncFileSystemEntity> list({bool recursive: false});
}

abstract class SyncFile implements SyncFileSystemEntity {
  @override
  bool exists() => fileSystem.type(path) == FileSystemEntityType.FILE;
  List<int> readAsBytes();
  String readAsString();
  SyncFile writeAsBytes(List<int> bytes);
  SyncFile writeAsString(String contents);
}
