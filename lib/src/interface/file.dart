import 'dart:io' as io;

import 'file_system_entity.dart';

/// A reference to a file on the file system.
abstract class File implements FileSystemEntity, io.File {}
