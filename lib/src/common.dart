import 'package:file/src/io.dart' as io;

String getPath(path) {
  if (path is io.FileSystemEntity) {
    return path.path;
  } else if (path is String) {
    return path;
  } else if (path is Uri) {
    return path.toFilePath();
  } else {
    throw new ArgumentError('Invalid type for "path": ${path?.runtimeType}');
  }
}
