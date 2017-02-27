#### 2.3.0

* Added the following convenience methods in `Directory`:
  * `Directory.childDirectory(String basename)`
  * `Directory.childFile(String basename)`
  * `Directory.childLink(String basename)`

#### 2.2.0

* Added `ErrorCodes` class, which holds errno values.

#### 2.1.0

* Add support for new `dart:io` API methods added in Dart SDK 1.23

#### 2.0.1

* Minor doc updates

#### 2.0.0

* Improved `toString` implementations in file system entity classes
* Added `ForwardingFileSystem` and associated forwarding classes to the
  main `file` library
* Removed `FileSystem.pathSeparator`, and added a more comprehensive
  `FileSystem.path` property
* Added `FileSystemEntity.basename` and `FileSystemEntity.dirname`
* Added the `record_replay` library
* Added the `testing` library

#### 1.0.1

* Added `FileSystem.systemTempDirectory`
* Added the ability to pass `Uri` and `FileSystemEntity` types to
  `FileSystem.directory()`, `FileSystem.file()`, and `FileSystem.link()`
* Added `FileSystem.pathSeparator`

#### 1.0.0

* Unified interface to match dart:io API
* Local file system implementation
* In-memory file system implementation
* Chroot file system implementation

#### 0.1.0

* Initial version
