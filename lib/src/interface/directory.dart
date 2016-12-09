import 'dart:io' as io;

import 'file_system_entity.dart';

/// A reference to a directory on the file system.
abstract class Directory implements FileSystemEntity, io.Directory {
}
