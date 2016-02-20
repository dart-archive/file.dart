[![Build Status](https://travis-ci.org/matanlurey/file.svg?branch=master)](https://travis-ci.org/matanlurey/file)
[![Coverage Status](https://coveralls.io/repos/github/matanlurey/file/badge.svg?branch=master)](https://coveralls.io/github/matanlurey/file?branch=master)

# File

A generic file system abstraction for Dart.

*This package is currently experimental and subject to change*

Like `dart:io`, `package:file` supplies a rich Dart idiomatic API for accessing
a file system.

Unlike `dart:io`, `package:file`:

- Does not mix synchronous and asynchronous API in one. It is up to users to
  choose one, the other, or both.
- Has explicit factory classes for different implementations.
- Can be used to implement custom file systems.
- Comes with in-memory implementation out-of-the-box, making it super-easy to
  test code that works with the file system.

## Usage

Implement your own custom file system:

```dart
import 'package:file/file.dart';

class FooBarFileSystem implements FileSystem { ... }
```

Use the in-memory file system:

```dart
import 'package:file/file.dart';

var fs = new InMemoryFileSystem();
```

Use the local file system (requires dart:io access):

```dart
import 'package:file/io.dart';

var fs = const LocalFileSystem();
```

The synchronous counterparts can be imported from:

```dart
// API and in-memory implementation
import `package:file/sync.dart`;
// Implementation based on "dart:io"
import `package:file/sync_io.dart`;
```
