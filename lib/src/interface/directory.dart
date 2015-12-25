part of file.src.interface.file;

/// A reference to a directory on the file system.
abstract class Directory implements FileSystemEntity {
  @override
  Future<bool> exists() async {
    return await fileSystem.type(path) == FileSystemEntityType.DIRECTORY;
  }

  Stream<FileSystemEntity> list({bool recursive: false});
}
