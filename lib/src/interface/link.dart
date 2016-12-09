import 'dart:io' as io;

import 'file_system_entity.dart';

/// A reference to a symbolic link on the file system.
abstract class Link implements FileSystemEntity, io.Link {
}
