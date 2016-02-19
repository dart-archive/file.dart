part of file.src.interface.file;

/// The common super class for [File], [Directory], and [Link] objects.
///
/// [FileSystemEntity] objects are returned from file listing operations. To
/// determine if a [FileSystemEntity] is a [File], [Directory], or [Link]
/// perform a type check:
///     if (entity is File) (entity as File).remove();
///
/// Unlike the native `dart:io` package, all operations are asynchronous. This
/// is because some backing implementations communicate over the network.
abstract class FileSystemEntity {
  Future<FileSystemEntity> copy(String newPath);

  /// Creates the entity this reference represents.
  ///
  /// Returns a [Future<FileSystemEntity>] that completes with a reference to
  /// the file system object that was created.
  ///
  /// If [recursive] is `false`, the default, the object is created only if all
  /// directories in the [path] actually exist. If [recursive] is `true`, all
  /// non-existing path components are created.
  ///
  /// Existing objects are left untouched by create.
  ///
  /// May complete with a [Future<FileSystemEntityException>] if the operation
  /// fails.
  Future<FileSystemEntity> create({bool recursive: false});

  /// Deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a [Directory], and if [recursive] is `false`,
  /// the directory must be empty. Otherwise, if [recursive] is `true`, the
  /// directory and all sub-directories and files in the directories are
  /// deleted.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows delete to be used to unconditionally delete any file
  /// system object.
  ///
  /// Returns a [Future<FileSystemEntity>] that completes with this
  /// [FileSystemEntity] when the deletion is done. If the FileSystemEntity
  /// cannot be deleted, the future completes with an exception.
  Future<FileSystemEntity> delete({bool recursive: false});

  /// Checks whether the file system entity with this [path] exists.
  ///
  /// Returns a [Future<bool>] that completes with the result.
  ///
  /// **NOTE**: Since the method is implemented on every super class, it will
  /// complete with false if a *different* type of object exists. To check if
  /// *any* object exists at a given path, use [FileSystem.type] method.
  Future<bool> exists();

  /// The backing implementation of this file system object.
  FileSystem get fileSystem;

  /// Returns a reference to the parent directory of this file system object.
  ///
  /// If this object is a root directory, returns `null`.
  Directory get parent;

  /// The absolute location this entity refers to.
  String get path;

  Future<FileSystemEntity> rename(String newPath);
}

/// Exception thrown when a file operation fails.
class FileSystemEntityException implements Exception {
  @override
  final String message;

  /// The file system path on which the error occurred.
  ///
  /// Can be `null` if the exception does not relate directly to an object.
  final String path;

  FileSystemEntityException(this.message, this.path);

  String toString() => '${FileSystemEntityException}: $message: $path';
}

/// The type of an entity on the file system.
enum FileSystemEntityType {
  DIRECTORY,
  FILE,
  LINK,
  NOT_FOUND
}

/// Returns the parent directory of [path].
String getParentPath(String path) {
  return path == '/' || path == '' ? null : path.substring(0, path.lastIndexOf('/'));
}
