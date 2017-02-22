// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:test/test.dart';

/// Matcher that successfully matches against any instance of [Directory].
const Matcher isDirectory = const isInstanceOf<Directory>();

/// Matcher that successfully matches against any instance of [File].
const Matcher isFile = const isInstanceOf<File>();

/// Matcher that successfully matches against any instance of [Link].
const Matcher isLink = const isInstanceOf<Link>();

/// Matcher that successfully matches against any instance of
/// [FileSystemEntity].
const Matcher isFileSystemEntity = const isInstanceOf<FileSystemEntity>();

/// Matcher that successfully matches against any instance of [FileStat].
const Matcher isFileStat = const isInstanceOf<FileStat>();

/// Returns a [Matcher] that matches [path] against an entity's path.
///
/// [path] may be a String, a predicate function, or a [Matcher]. If it is
/// a String, it will be wrapped in an equality matcher.
Matcher hasPath(dynamic path) => new _HasPath(path);

/// Returns a [Matcher] that successfully matches against an instance of
/// [FileSystemException].
///
/// If [osErrorCode] is specified, matches will be limited to exceptions whose
/// `osError.errorCode` also match the specified matcher.
///
/// [osErrorCode] may be an `int`, a predicate function, or a [Matcher]. If it
/// is an `int`, it will be wrapped in an equality matcher.
Matcher isFileSystemException([dynamic osErrorCode]) =>
    new _FileSystemException(osErrorCode);

/// Returns a matcher that successfully matches against a future or function
/// that throws a [FileSystemException].
///
/// If [osErrorCode] is specified, matches will be limited to exceptions whose
/// `osError.errorCode` also match the specified matcher.
///
/// [osErrorCode] may be an `int`, a predicate function, or a [Matcher]. If it
/// is an `int`, it will be wrapped in an equality matcher.
Matcher throwsFileSystemException([dynamic osErrorCode]) =>
    throwsA(isFileSystemException(osErrorCode));

/// Expects the specified [callback] to throw a [FileSystemException] with the
/// specified [osErrorCode] (matched against the exception's
/// `osError.errorCode`).
///
/// [osErrorCode] may be an `int`, a predicate function, or a [Matcher]. If it
/// is an `int`, it will be wrapped in an equality matcher.
///
/// See also:
///   - [ErrorCode]
void expectFileSystemException(dynamic osErrorCode, void callback()) {
  expect(callback, throwsFileSystemException(osErrorCode));
}

/// Matcher that successfully matches against a [FileSystemEntity] that
/// exists ([FileSystemEntity.existsSync] returns true).
const Matcher exists = const _Exists();

class _FileSystemException extends Matcher {
  final Matcher _matcher;

  _FileSystemException(dynamic osErrorCode)
      : _matcher = osErrorCode == null ? null : wrapMatcher(osErrorCode);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is FileSystemException) {
      return (_matcher == null ||
          _matcher.matches(item.osError?.errorCode, matchState));
    }
    return false;
  }

  @override
  Description describe(Description desc) {
    if (_matcher == null) {
      return desc.add('FileSystemException');
    } else {
      desc.add('FileSystemException with osError.errorCode: ');
      return _matcher.describe(desc);
    }
  }
}

class _HasPath extends Matcher {
  final Matcher _matcher;

  _HasPath(dynamic path) : _matcher = wrapMatcher(path);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.path, matchState);

  @override
  Description describe(Description desc) {
    desc.add('has path: ');
    return _matcher.describe(desc);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description desc,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    desc.add('has path: \'${item.path}\'').add('\n   Which: ');
    Description pathDesc = new StringDescription();
    _matcher.describeMismatch(item.path, pathDesc, matchState, verbose);
    desc.add(pathDesc.toString());
    return desc;
  }
}

class _Exists extends Matcher {
  const _Exists();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      item is FileSystemEntity && item.existsSync();

  @override
  Description describe(Description description) =>
      description.add('a file system entity that exists');

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return description.add('does not exist');
  }
}
