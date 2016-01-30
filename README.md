# File

A generic file system abstraction for Dart.

*This package is currently experimental and subject to change*

Like `dart:io`, `package:file` supplies a rich Dart idiomatic API for accessing
a file system.

Unlike `dart:io`, `package:file`:

- Has an entirely *async* public interface (no `fooSync` methods).
- Has explicit factory classes for different implementations:

```dart
var inMemoryFS = new InMemoryFileSystem();
var file = inMemoryFS.file('/foo/bar');
```

- Can be used to implement custom file systems:

```dart
class GoogleDriveFileSystem implements FileSystem { ... }
```

And much much more!
