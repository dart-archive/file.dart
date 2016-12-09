import 'dart:io' as io;

import 'file_system.dart';

/// The common super class for [File], [Directory], and [Link] objects.
abstract class FileSystemEntity implements io.FileSystemEntity {
  /// Returns the file system responsible for this entity.
  FileSystem get fileSystem;
}
