part of file.src.interface;

/// The common super class for [File], [Directory], and [Link] objects.
abstract class FileSystemEntity implements io.FileSystemEntity {
  /// Returns the file system responsible for this entity.
  FileSystem get fileSystem;
}
