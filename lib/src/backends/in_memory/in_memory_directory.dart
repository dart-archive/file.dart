part of file.src.backends.in_memory;

class _InMemoryDirectory
    extends _InMemoryFileSystemEntity
    with Directory {
  _InMemoryDirectory(InMemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);
  // Create an object representing a directory with no files.
  @override
  Object _createImpl() => {};

  @override
  final FileSystemEntityType _type = FileSystemEntityType.DIRECTORY;
}
