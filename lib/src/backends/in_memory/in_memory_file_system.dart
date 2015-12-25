part of file.src.backends.in_memory;

/// Returns a deep copy of [map], verifying it is JSON serializable.
Map<String, Object> _cloneSafe(Map<String, Object> map) {
  var json = JSON.encode(map);
  return JSON.decode(json) as Map<String, Object>;
}

/// An implementation of [FileSystem] that exists entirely in memory.
///
/// [InMemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
///
/// **NOTE**: This class is not yet optimized and should not be used for
/// performance-sensitive operations. There is also no implementation today for
/// symbolic [Link]s.
class InMemoryFileSystem implements FileSystem {
  final Map<String, Object> _data;

  /// Create a new, empty in-memory file system.
  factory InMemoryFileSystem() {
    return new InMemoryFileSystem._(<String, Object>{});
  }

  /// Build an in-memory file system from a [map] file structure.
  ///
  /// __Example use__:
  ///     new InMemoryFileSystem.build({
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
  factory InMemoryFileSystem.fromMap(Map<String, Object> files) {
    // Lazy/dirty way of doing a deep clone and checking the structure.
    return new InMemoryFileSystem._(_cloneSafe(files));
  }

  // Prevent extending this class.
  InMemoryFileSystem._(this._data);

  @override
  Directory directory(String path) => new _InMemoryDirectory(this, path);

  @override
  File file(String path) => new _InMemoryFile(this, path);

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
  Map<String, Object> _resolvePath(Iterable<String> paths, {bool recursive: false}) {
    var root = _data;
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

  /// Returns a Map equivalent to the file structure of the file system.
  ///
  // See [InMemoryFileSystem.fromMap] for details on the structure.
  Map<String, Object> toMap() => _cloneSafe(_data);

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) {
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
      var directory = _resolvePath(paths.take(paths.length - 1));
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
    return new Future<FileSystemEntityType>.value(result);
  }
}
