part of file.src.interface.file;

/// A reference to a symbolic link on the file system.
abstract class Link implements FileSystemEntity {
  @override
  Future<bool> exists() async {
    return await fileSystem.type(path) == FileSystemEntityType.LINK;
  }
}
