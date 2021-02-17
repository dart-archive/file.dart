// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A file system operation used by the [MemoryFileSytem] to allow
/// tests to insert errors for certain operations.
///
/// This is not backed as an enum to avoid breaking changes when adding new
/// types.
class FileSystemOp {
  const FileSystemOp._(this._value);

  // This field added to ensure const values can be different.
  // ignore: unused_field
  final int _value;

  /// A file system operation used for all read methods.
  ///
  /// * [FileSystemEntity.readAsString]
  /// * [FileSystemEntity.readAsStringSync]
  /// * [FileSystemEntity.readAsBytes]
  /// * [FileSystemEntity.readAsBytesSync]
  static const FileSystemOp read = FileSystemOp._(0);

  /// A file system operation used for all write methods.
  ///
  /// * [FileSystemEntity.writeAsString]
  /// * [FileSystemEntity.writeAsStringSync]
  /// * [FileSystemEntity.writeAsBytes]
  /// * [FileSystemEntity.writeAsBytesSync]
  static const FileSystemOp write = FileSystemOp._(1);
}
