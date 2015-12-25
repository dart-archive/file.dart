part of file.src.interface.file;

/// A generic representation of a file system.
abstract class FileSystem {
  /// Returns a reference to a [Directory] at [path].
  Directory directory(String path);

  /// Returns a reference to a [File] at [path].
  File file(String path);

  /// Finds the type of file system object that a [path] points to.
  ///
  /// Returns a Future<FileSystemEntityType> that completes with the result.
  ///
  /// [FileSystemEntityType.LINK] will only be returned if [followLinks] is
  /// `false`, otherwise symbolic links are resolved and the result type is
  /// returned instead.
  ///
  /// If the [path] does not point to a file system object or an error occurs
  /// then [FileSystemEntityType.NOT_FOUND] is returned.
  Future<FileSystemEntityType> type(String path, {bool followLinks: true});
}
