part of file.src.interface;

/// A reference to a directory on the file system.
abstract class Directory implements FileSystemEntity, io.Directory {
  // Override method definitions to codify the return type covariance.
  @override
  Future<Directory> create({bool recursive: false});

  @override
  Future<Directory> createTemp([String prefix]);

  @override
  Directory createTempSync([String prefix]);

  @override
  Future<Directory> rename(String newPath);

  @override
  Directory renameSync(String newPath);

  @override
  Directory get absolute;

  @override
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true});

  @override
  List<FileSystemEntity> listSync(
      {bool recursive: false, bool followLinks: true});
}
