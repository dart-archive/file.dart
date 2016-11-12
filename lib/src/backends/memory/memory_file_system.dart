part of file.src.backends.memory;

/// An implementation of [FileSystem] that exists entirely in memory.
///
/// [MemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
///
/// **NOTE**: This class is not yet optimized and should not be used for
/// performance-sensitive operations. There is also no implementation today for
/// symbolic [Link]s.
class MemoryFileSystem implements FileSystem {
  final MemoryFileStorageImpl _storage;
  MemoryFileStorage get storage => _storage;
  Map<String, dynamic> get _data => _storage.data;

  /// Create a new in-memory file system.
  ///
  /// If [backedBy] is not supplied, the file system starts empty.
  ///
  /// If [backedBy] is supplied this file system will use it as the underlying
  /// storage of file system information. This is useful if you need to
  /// instantiate multiple instances of in-memory file systems all backed by
  /// the same map.
  factory MemoryFileSystem({MemoryFileStorage backedBy}) {
    return new MemoryFileSystem._(backedBy);
  }

  // Prevent extending this class.
  MemoryFileSystem._(MemoryFileStorage storage)
      : _storage = storage ?? new MemoryFileStorageImpl();

  @override
  Directory directory(String path) {
    return new _MemoryDirectory(this, path == '/' ? '' : path);
  }

  @override
  File file(String path) => new _MemoryFile(this, path);

  /// Returns a Map equivalent to the file structure of the file system.
  ///
  // See [InMemoryFileSystem.fromMap] for details on the structure.
  Map<String, dynamic> toMap() => cloneSafe/*<Map<String, dynamic>>*/(_data);

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) {
    return new Future<FileSystemEntityType>.value(
        getType(_data, path, followLinks));
  }
}
