import 'dart:convert' show JSON;

import 'interface.dart' show FileSystemEntityType;

/// Returns a deep copy of [map], verifying it is JSON serializable.
Map<String, Object> cloneSafe(Map<String, Object> map) {
  var json = JSON.encode(map);
  return JSON.decode(json) as Map<String, Object>;
}

// Resolves a list of path parts to the final directory in the hash map.
//
// This will be the most expensive part of the implementation as the
// directory structure grows n levels deep it will require n checks.
//
// This could be sped up by using a SplayTree intead for O(logn) lookups
// if we are expecting very deep directory structures.
//
// May pass [recursive] as `true` to create missing directories instead of
// failing by returning null.
Map<String, Object> resolvePath(
    Map<String, Object> data, Iterable<String> paths,
    {bool recursive: false}) {
  var root = data;
  for (var path in paths) {
    if (path == '') continue;
    // Could use putIfAbsent to potentially optimize, but creating a long
    // directory structure recursively is unlikely to happen in a tight loop.
    var next = root[path];
    if (next == null) {
      if (recursive) {
        root[path] = next = <String, Object>{};
      } else {
        return null;
      }
    }
    root = next as Map<String, Object>;
  }
  return root;
}

FileSystemEntityType getType(
    Map<String, Object> data, String path, bool followLinks) {
  if (!followLinks) {
    throw new UnimplementedError('No support for symbolic links in system');
  }
  FileSystemEntityType result;
  if (path == '/') {
    result = FileSystemEntityType.DIRECTORY;
  } else if (!path.startsWith('/')) {
    throw new ArgumentError('Path must begin with "/"');
  } else {
    var paths = path.substring(1).split('/');
    var directory = resolvePath(data, paths.take(paths.length - 1));
    var entity;
    if (directory != null) {
      entity = directory[paths.last];
    }
    if (entity == null) {
      result = FileSystemEntityType.NOT_FOUND;
    } else if (entity is String || entity is List) {
      result = FileSystemEntityType.FILE;
    } else if (entity is Map) {
      result = FileSystemEntityType.DIRECTORY;
    } else {
      throw new UnsupportedError('Unknown type: ${entity.runtimeType}');
    }
  }
  return result;
}
