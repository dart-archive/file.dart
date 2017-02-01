// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// ignore: public_member_api_docs
abstract class Directory implements FileSystemEntity {
  // ignore: public_member_api_docs
  Future<Directory> create({bool recursive: false});

  // ignore: public_member_api_docs
  void createSync({bool recursive: false});

  // ignore: public_member_api_docs
  Future<Directory> createTemp([String prefix]);

  // ignore: public_member_api_docs
  Directory createTempSync([String prefix]);

  @override
  Future<Directory> rename(String newPath);

  @override
  Directory renameSync(String newPath);

  @override
  Directory get absolute;

  // ignore: public_member_api_docs
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true});

  // ignore: public_member_api_docs
  List<FileSystemEntity> listSync(
      {bool recursive: false, bool followLinks: true});
}

// ignore: public_member_api_docs
abstract class File implements FileSystemEntity {
  // ignore: public_member_api_docs
  Future<File> create({bool recursive: false});

  // ignore: public_member_api_docs
  void createSync({bool recursive: false});

  @override
  Future<File> rename(String newPath);

  @override
  File renameSync(String newPath);

  // ignore: public_member_api_docs
  Future<File> copy(String newPath);

  // ignore: public_member_api_docs
  File copySync(String newPath);

  // ignore: public_member_api_docs
  Future<int> length();

  // ignore: public_member_api_docs
  int lengthSync();

  @override
  File get absolute;

  // ignore: public_member_api_docs
  Future<DateTime> lastModified();

  // ignore: public_member_api_docs
  DateTime lastModifiedSync();

  // ignore: public_member_api_docs
  Future<RandomAccessFile> open({FileMode mode: FileMode.READ});

  // ignore: public_member_api_docs
  RandomAccessFile openSync({FileMode mode: FileMode.READ});

  // ignore: public_member_api_docs
  Stream<List<int>> openRead([int start, int end]);

  // ignore: public_member_api_docs
  IOSink openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  Future<List<int>> readAsBytes();

  // ignore: public_member_api_docs
  List<int> readAsBytesSync();

  // ignore: public_member_api_docs
  Future<String> readAsString({Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  String readAsStringSync({Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  Future<List<String>> readAsLines({Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  List<String> readAsLinesSync({Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false});

  // ignore: public_member_api_docs
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false});

  // ignore: public_member_api_docs
  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false});

  // ignore: public_member_api_docs
  void writeAsStringSync(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false});
}

// ignore: public_member_api_docs
enum FileLock {
  // ignore: constant_identifier_names, public_member_api_docs
  SHARED,

  // ignore: constant_identifier_names, public_member_api_docs
  EXCLUSIVE,

  // ignore: constant_identifier_names, public_member_api_docs
  BLOCKING_SHARED,

  // ignore: constant_identifier_names, public_member_api_docs
  BLOCKING_EXCLUSIVE,
}

// ignore: public_member_api_docs
class FileMode {
  // ignore: constant_identifier_names, public_member_api_docs
  static const FileMode READ = const FileMode._internal(0);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileMode WRITE = const FileMode._internal(1);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileMode APPEND = const FileMode._internal(2);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileMode WRITE_ONLY = const FileMode._internal(3);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileMode WRITE_ONLY_APPEND = const FileMode._internal(4);

  final int _mode; // ignore: unused_field

  const FileMode._internal(this._mode);
}

// ignore: public_member_api_docs
abstract class FileStat {
  // ignore: public_member_api_docs
  DateTime get changed;

  // ignore: public_member_api_docs
  DateTime get modified;

  // ignore: public_member_api_docs
  DateTime get accessed;

  // ignore: public_member_api_docs
  FileSystemEntityType get type;

  // ignore: public_member_api_docs
  int get mode;

  // ignore: public_member_api_docs
  int get size;

  // ignore: public_member_api_docs
  String modeString();
}

// ignore: public_member_api_docs
abstract class FileSystemEntity {
  // ignore: public_member_api_docs
  String get path;

  // ignore: public_member_api_docs
  Uri get uri;

  // ignore: public_member_api_docs
  Future<bool> exists();

  // ignore: public_member_api_docs
  bool existsSync();

  // ignore: public_member_api_docs
  Future<FileSystemEntity> rename(String newPath);

  // ignore: public_member_api_docs
  FileSystemEntity renameSync(String newPath);

  // ignore: public_member_api_docs
  Future<String> resolveSymbolicLinks();

  // ignore: public_member_api_docs
  String resolveSymbolicLinksSync();

  // ignore: public_member_api_docs
  Future<FileStat> stat();

  // ignore: public_member_api_docs
  FileStat statSync();

  // ignore: public_member_api_docs
  Future<FileSystemEntity> delete({bool recursive: false});

  // ignore: public_member_api_docs
  void deleteSync({bool recursive: false});

  // ignore: public_member_api_docs
  Stream<FileSystemEvent> watch(
      {int events: FileSystemEvent.ALL, bool recursive: false});

  // ignore: public_member_api_docs
  bool get isAbsolute;

  // ignore: public_member_api_docs
  FileSystemEntity get absolute;

  // ignore: public_member_api_docs
  Directory get parent;
}

// ignore: public_member_api_docs
class FileSystemEntityType {
  // ignore: constant_identifier_names, public_member_api_docs
  static const FileSystemEntityType FILE =
      const FileSystemEntityType._internal(0);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileSystemEntityType DIRECTORY =
      const FileSystemEntityType._internal(1);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileSystemEntityType LINK =
      const FileSystemEntityType._internal(2);

  // ignore: constant_identifier_names, public_member_api_docs
  static const FileSystemEntityType NOT_FOUND =
      const FileSystemEntityType._internal(3);

  final int _type;
  const FileSystemEntityType._internal(this._type);

  // ignore: public_member_api_docs
  @override
  String toString() =>
      const <String>['FILE', 'DIRECTORY', 'LINK', 'NOT_FOUND'][_type];
}

// ignore: public_member_api_docs
abstract class FileSystemEvent {
  // ignore: constant_identifier_names, public_member_api_docs
  static const int CREATE = 1 << 0;

  // ignore: constant_identifier_names, public_member_api_docs
  static const int MODIFY = 1 << 1;

  // ignore: constant_identifier_names, public_member_api_docs
  static const int DELETE = 1 << 2;

  // ignore: constant_identifier_names, public_member_api_docs
  static const int MOVE = 1 << 3;

  // ignore: constant_identifier_names, public_member_api_docs
  static const int ALL = CREATE | MODIFY | DELETE | MOVE;

  // ignore: public_member_api_docs
  int get type;

  // ignore: public_member_api_docs
  String get path;

  // ignore: public_member_api_docs
  bool get isDirectory;
}

// ignore: public_member_api_docs
class FileSystemException implements IOException {
  // ignore: public_member_api_docs
  const FileSystemException([this.message = "", this.path = "", this.osError]);

  // ignore: public_member_api_docs
  final String message;

  // ignore: public_member_api_docs
  final String path;

  // ignore: public_member_api_docs
  final OSError osError;

  // ignore: public_member_api_docs
  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("FileSystemException");
    if (message.isNotEmpty) {
      sb.write(": $message");
      if (path != null) {
        sb.write(", path = '$path'");
      }
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
      if (path != null) {
        sb.write(", path = '$path'");
      }
    } else if (path != null) {
      sb.write(": $path");
    }
    return sb.toString();
  }
}

// ignore: public_member_api_docs
abstract class IOException implements Exception {}

// ignore: public_member_api_docs
abstract class IOSink implements StreamSink<List<int>>, StringSink {
  // ignore: public_member_api_docs
  Encoding encoding;

  // ignore: public_member_api_docs
  @override
  void add(List<int> data);

  // ignore: public_member_api_docs
  @override
  void write(Object obj);

  // ignore: public_member_api_docs
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]);

  // ignore: public_member_api_docs
  @override
  void writeln([Object obj = ""]);

  // ignore: public_member_api_docs
  @override
  void writeCharCode(int charCode);

  // ignore: public_member_api_docs
  @override
  void addError(dynamic error, [StackTrace stackTrace]);

  // ignore: public_member_api_docs
  @override
  Future<dynamic> addStream(Stream<List<int>> stream);

  // ignore: public_member_api_docs
  Future<dynamic> flush();

  // ignore: public_member_api_docs
  @override
  Future<dynamic> close();

  // ignore: public_member_api_docs
  @override
  Future<dynamic> get done;
}

// ignore: public_member_api_docs
abstract class Link implements FileSystemEntity {
  // ignore: public_member_api_docs
  Future<Link> create(String target, {bool recursive: false});

  // ignore: public_member_api_docs
  void createSync(String target, {bool recursive: false});

  // ignore: public_member_api_docs
  void updateSync(String target);

  // ignore: public_member_api_docs
  Future<Link> update(String target);

  // ignore: public_member_api_docs
  @override
  Future<Link> rename(String newPath);

  // ignore: public_member_api_docs
  @override
  Link renameSync(String newPath);

  // ignore: public_member_api_docs
  @override
  Link get absolute;

  // ignore: public_member_api_docs
  Future<String> target();

  // ignore: public_member_api_docs
  String targetSync();
}

// ignore: public_member_api_docs
class OSError {
  // ignore: public_member_api_docs
  static const int noErrorCode = -1;

  // ignore: public_member_api_docs
  const OSError([this.message = "", this.errorCode = noErrorCode]);

  // ignore: public_member_api_docs
  final String message;

  // ignore: public_member_api_docs
  final int errorCode;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("OS Error");
    if (message.isNotEmpty) {
      sb..write(": ")..write(message);
      if (errorCode != noErrorCode) {
        sb..write(", errno = ")..write(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb..write(": errno = ")..write(errorCode.toString());
    }
    return sb.toString();
  }
}

// ignore: public_member_api_docs
abstract class RandomAccessFile {
  // ignore: public_member_api_docs
  Future<RandomAccessFile> close();

  // ignore: public_member_api_docs
  void closeSync();

  // ignore: public_member_api_docs
  Future<int> readByte();

  // ignore: public_member_api_docs
  int readByteSync();

  // ignore: public_member_api_docs
  Future<List<int>> read(int bytes);

  // ignore: public_member_api_docs
  List<int> readSync(int bytes);

  // ignore: public_member_api_docs
  Future<int> readInto(List<int> buffer, [int start = 0, int end]);

  // ignore: public_member_api_docs
  int readIntoSync(List<int> buffer, [int start = 0, int end]);

  // ignore: public_member_api_docs
  Future<RandomAccessFile> writeByte(int value);

  // ignore: public_member_api_docs
  int writeByteSync(int value);

  // ignore: public_member_api_docs
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int end]);

  // ignore: public_member_api_docs
  void writeFromSync(List<int> buffer, [int start = 0, int end]);

  // ignore: public_member_api_docs
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  void writeStringSync(String string, {Encoding encoding: UTF8});

  // ignore: public_member_api_docs
  Future<int> position();

  // ignore: public_member_api_docs
  int positionSync();

  // ignore: public_member_api_docs
  Future<RandomAccessFile> setPosition(int position);

  // ignore: public_member_api_docs
  void setPositionSync(int position);

  // ignore: public_member_api_docs
  Future<RandomAccessFile> truncate(int length);

  // ignore: public_member_api_docs
  void truncateSync(int length);

  // ignore: public_member_api_docs
  Future<int> length();

  // ignore: public_member_api_docs
  int lengthSync();

  // ignore: public_member_api_docs
  Future<RandomAccessFile> flush();

  // ignore: public_member_api_docs
  void flushSync();

  // ignore: public_member_api_docs
  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]);

  // ignore: public_member_api_docs
  void lockSync(
      [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]);

  // ignore: public_member_api_docs
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]);

  // ignore: public_member_api_docs
  void unlockSync([int start = 0, int end = -1]);

  // ignore: public_member_api_docs
  String get path;
}
