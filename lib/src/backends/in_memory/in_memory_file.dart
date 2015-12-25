part of file.src.backends.in_memory;

class _InMemoryFile extends _InMemoryFileSystemEntity with File {
  _InMemoryFile(InMemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);
  // Create an object representing a binary file with no data.
  @override
  Object _createImpl() => [];

  @override
  final FileSystemEntityType _type = FileSystemEntityType.FILE;
}
