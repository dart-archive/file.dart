part of file.src.backends.memory;

/// An implementation of [FileSystem] that exists entirely in memory.
///
/// [MemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
///
/// **NOTE**: This class is not yet optimized and should not be used for
/// performance-sensitive operations. There is also no implementation today for
/// symbolic [Link]s.
class SyncMemoryFileSystem implements SyncFileSystem {
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
  factory SyncMemoryFileSystem({MemoryFileStorage backedBy}) {
    return new SyncMemoryFileSystem._(backedBy);
  }

  // Prevent extending this class.
  SyncMemoryFileSystem._(MemoryFileStorage storage)
      : _storage = storage ?? new MemoryFileStorageImpl();

  @override
  SyncDirectory directory(String path) {
    return new _MemoryDirectory(this, path == '/' ? '' : path);
  }

  @override
  SyncFile file(String path) => new _MemoryFile(this, path);

  /// Returns a Map equivalent to the file structure of the file system.
  ///
  // See [InMemoryFileSystem.fromMap] for details on the structure.
  Map<String, Object> toMap() => cloneSafe(_data) as Map<String, dynamic>;

  @override
  FileSystemEntityType type(String path, {bool followLinks: true}) {
    return getType(_data, path, followLinks);
  }
}
