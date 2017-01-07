part of file.src.interface;

/// A generic representation of a file system.
///
/// Note that this class uses `dart:io` only inasmuch as it deals in the types
/// exposed by the `dart:io` library. Subclasses should document their level of
/// dependence on the library (and the associated implications of using that
/// implementation in the browser).
abstract class FileSystem {
  const FileSystem();

  /// Returns a reference to a [Directory] at [path].
  ///
  /// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
  Directory directory(path);

  /// Returns a reference to a [File] at [path].
  ///
  /// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
  File file(path);

  /// Returns a reference to a [Link] at [path].
  ///
  /// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
  Link link(path);

  /// Gets the path separator used by this file system to separate components
  /// in file paths.
  String get pathSeparator;

  /// Gets the system temp directory.
  ///
  /// It is left to file system implementations to decide how to define the
  /// "system temp directory".
  Directory get systemTempDirectory;

  /// Creates a directory object pointing to the current working directory.
  Directory get currentDirectory;

  /// Sets the current working directory to the specified path. The new value
  /// set can be either a [Directory] or a [String].
  ///
  /// Relative paths will be resolved by the underlying file system
  /// implementation (meaning it is up to the underlying implementation to
  /// decide whether to support relative paths).
  set currentDirectory(path);

  /// Asynchronously calls the operating system's stat() function on [path].
  /// Returns a Future which completes with a [FileStat] object containing
  /// the data returned by stat().
  /// If the call fails, completes the future with a [FileStat] object with
  /// .type set to FileSystemEntityType.NOT_FOUND and the other fields invalid.
  Future<io.FileStat> stat(String path);

  /// Calls the operating system's stat() function on [path].
  /// Returns a [FileStat] object containing the data returned by stat().
  /// If the call fails, returns a [FileStat] object with .type set to
  /// FileSystemEntityType.NOT_FOUND and the other fields invalid.
  io.FileStat statSync(String path);

  /// Checks whether two paths refer to the same object in the
  /// file system. Returns a [Future<bool>] that completes with the result.
  ///
  /// Comparing a link to its target returns false, as does comparing two links
  /// that point to the same target.  To check the target of a link, use
  /// Link.target explicitly to fetch it.  Directory links appearing
  /// inside a path are followed, though, to find the file system object.
  ///
  /// Completes the returned Future with an error if one of the paths points
  /// to an object that does not exist.
  Future<bool> identical(String path1, String path2);

  /// Synchronously checks whether two paths refer to the same object in the
  /// file system.
  ///
  /// Comparing a link to its target returns false, as does comparing two links
  /// that point to the same target.  To check the target of a link, use
  /// Link.target explicitly to fetch it.  Directory links appearing
  /// inside a path are followed, though, to find the file system object.
  ///
  /// Throws an error if one of the paths points to an object that does not
  /// exist.
  bool identicalSync(String path1, String path2);

  /// Tests if [watch] is supported on the current system.
  bool get isWatchSupported;

  /// Finds the type of file system object that a [path] points to. Returns
  /// a Future<FileSystemEntityType> that completes with the result.
  ///
  /// [FileSystemEntityType.LINK] will only be returned if [followLinks] is
  /// `false`, and [path] points to a link
  ///
  /// If the [path] does not point to a file system object or an error occurs
  /// then [FileSystemEntityType.NOT_FOUND] is returned.
  Future<io.FileSystemEntityType> type(String path, {bool followLinks: true});

  /// Syncronously finds the type of file system object that a [path] points
  /// to. Returns a [FileSystemEntityType].
  ///
  /// [FileSystemEntityType.LINK] will only be returned if [followLinks] is
  /// `false`, and [path] points to a link
  ///
  /// If the [path] does not point to a file system object or an error occurs
  /// then [FileSystemEntityType.NOT_FOUND] is returned.
  io.FileSystemEntityType typeSync(String path, {bool followLinks: true});

  /// Checks if [`type(path)`](type) returns [io.FileSystemEntityType.FILE].
  Future<bool> isFile(String path) async =>
      await type(path) == io.FileSystemEntityType.FILE;

  /// Synchronously checks if [`type(path)`](type) returns
  /// [io.FileSystemEntityType.FILE].
  bool isFileSync(String path) =>
      typeSync(path) == io.FileSystemEntityType.FILE;

  /// Checks if [`type(path)`](type) returns [io.FileSystemEntityType.DIRECTORY].
  Future<bool> isDirectory(String path) async =>
      await type(path) == io.FileSystemEntityType.DIRECTORY;

  /// Synchronously checks if [`type(path)`](type) returns
  /// [io.FileSystemEntityType.DIRECTORY].
  bool isDirectorySync(String path) =>
      typeSync(path) == io.FileSystemEntityType.DIRECTORY;

  /// Checks if [`type(path)`](type) returns [io.FileSystemEntityType.LINK].
  Future<bool> isLink(String path) async =>
      await type(path) == io.FileSystemEntityType.LINK;

  /// Synchronously checks if [`type(path)`](type) returns
  /// [io.FileSystemEntityType.LINK].
  bool isLinkSync(String path) =>
      typeSync(path) == io.FileSystemEntityType.LINK;
}
