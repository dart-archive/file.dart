library file.src.utils;

import 'dart:async';

import 'package:file/file.dart';

/// Inserts files and directories in [structure] in [directory].
///
/// Fails with a [FileSystemEntityException] if any files or directories
/// previously exist - the assumption by this method is that nothing exists.
///
/// __Example use__:
///     await insertFiles(directory, {
///       'home': {
///         'root': {
///           'README': 'Hello, this is a file.',
///           'root.dat': [0, 32, 252, 45, 101]
///         }
///       }
///     });
///
/// The following types are respected:
/// - A [Map] is a folder.
/// - A [String] is a text file.
/// - A [List<int>] is a binary file.
///
/// Returns [Future<Directory>] that completes with [directory] on completion.
///
/// **NOTE**: This is a method that primarily exists for testing or lightweight
/// operations and is not guaranteed to be efficient for performance sensitive
/// work (e.g. batching is not implemented).
Future<Directory> insertFiles(
    Directory directory, Map<String, Object> structure,
    [bool checkRoot = false]) async {
  // TODO: Add top-level type assertion.
  for (var name in structure.keys) {
    var entity = structure[name];
    var path = '${directory.path}/$name';
    if (entity is String) {
      var file = directory.fileSystem.file(path);
      await file.writeAsString(entity);
    } else if (entity is List<int>) {
      var file = directory.fileSystem.file(path);
      await file.writeAsBytes(entity);
    } else if (entity is Map<String, Object>) {
      var dir = directory.fileSystem.directory(path);
      await dir.create();
      await insertFiles(dir, entity);
    }
  }
  return directory;
}
