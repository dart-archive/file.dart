part of file.src.interface.file;

/// A reference to a file on the file system.
abstract class File implements FileSystemEntity {
  @override
  Future<bool> exists() async {
    return await fileSystem.type(path) == FileSystemEntityType.FILE;
  }
}
