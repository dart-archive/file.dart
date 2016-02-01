part of file.src.interface.file;

/// A reference to a file on the file system.
abstract class File implements FileSystemEntity {
  @override
  Future<bool> exists() async {
    return await fileSystem.type(path) == FileSystemEntityType.FILE;
  }

  Future<List<int>> readAsBytes();

  Future<String> readAsString();

  /// Writes [bytes] to the file.
  Future<File> writeAsBytes(List<int> bytes);

  /// Writes [contents] to the file.
  Future<File> writeAsString(String contents);
}
