part of file.src.interface;

/// A reference to a symbolic link on the file system.
abstract class Link implements FileSystemEntity, io.Link {
  // Override method definitions to codify the return type covariance.
  @override
  Future<Link> create(String target, {bool recursive: false});

  @override
  Future<Link> update(String target);

  @override
  Future<Link> rename(String newPath);

  @override
  Link renameSync(String newPath);

  @override
  Link get absolute;
}
