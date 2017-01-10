// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

abstract class Directory implements FileSystemEntity {
  String get path;
  Uri get uri;
  Future<Directory> create({bool recursive: false});
  void createSync({bool recursive: false});
  Future<Directory> createTemp([String prefix]);
  Directory createTempSync([String prefix]);
  Future<String> resolveSymbolicLinks();
  String resolveSymbolicLinksSync();
  Future<Directory> rename(String newPath);
  Directory renameSync(String newPath);
  Directory get absolute;
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true});
  List<FileSystemEntity> listSync(
      {bool recursive: false, bool followLinks: true});
}

abstract class File implements FileSystemEntity {
  String get path;
  Future<File> create({bool recursive: false});
  void createSync({bool recursive: false});
  Future<File> rename(String newPath);
  File renameSync(String newPath);
  Future<File> copy(String newPath);
  File copySync(String newPath);
  Future<int> length();
  int lengthSync();
  File get absolute;
  Future<DateTime> lastModified();
  DateTime lastModifiedSync();
  Future<RandomAccessFile> open({FileMode mode: FileMode.READ});
  RandomAccessFile openSync({FileMode mode: FileMode.READ});
  Stream<List<int>> openRead([int start, int end]);
  IOSink openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8});
  Future<List<int>> readAsBytes();
  List<int> readAsBytesSync();
  Future<String> readAsString({Encoding encoding: UTF8});
  String readAsStringSync({Encoding encoding: UTF8});
  Future<List<String>> readAsLines({Encoding encoding: UTF8});
  List<String> readAsLinesSync({Encoding encoding: UTF8});
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false});
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false});
  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false});
  void writeAsStringSync(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false});
}

enum FileLock {
  SHARED,
  EXCLUSIVE,
  BLOCKING_SHARED,
  BLOCKING_EXCLUSIVE,
}

class FileMode {
  static const READ = const FileMode._internal(0);
  static const WRITE = const FileMode._internal(1);
  static const APPEND = const FileMode._internal(2);
  static const WRITE_ONLY = const FileMode._internal(3);
  static const WRITE_ONLY_APPEND = const FileMode._internal(4);
  final int _mode; // ignore: unused_field
  const FileMode._internal(this._mode);
}

abstract class FileStat {
  DateTime get changed;
  DateTime get modified;
  DateTime get accessed;
  FileSystemEntityType get type;
  int get mode;
  int get size;
  String modeString();
}

abstract class FileSystemEntity {
  String get path;
  Uri get uri;
  Future<bool> exists();
  bool existsSync();
  Future<FileSystemEntity> rename(String newPath);
  FileSystemEntity renameSync(String newPath);
  Future<String> resolveSymbolicLinks();
  String resolveSymbolicLinksSync();
  Future<FileStat> stat();
  FileStat statSync();
  Future<FileSystemEntity> delete({bool recursive: false});
  void deleteSync({bool recursive: false});
  Stream<FileSystemEvent> watch(
      {int events: FileSystemEvent.ALL, bool recursive: false});
  bool get isAbsolute;
  FileSystemEntity get absolute;
  Directory get parent;
}

class FileSystemEntityType {
  static const FILE = const FileSystemEntityType._internal(0);
  static const DIRECTORY = const FileSystemEntityType._internal(1);
  static const LINK = const FileSystemEntityType._internal(2);
  static const NOT_FOUND = const FileSystemEntityType._internal(3);

  final int _type;
  const FileSystemEntityType._internal(this._type);

  String toString() => const ['FILE', 'DIRECTORY', 'LINK', 'NOT_FOUND'][_type];
}

abstract class FileSystemEvent {
  static const int CREATE = 1 << 0;
  static const int MODIFY = 1 << 1;
  static const int DELETE = 1 << 2;
  static const int MOVE = 1 << 3;
  static const int ALL = CREATE | MODIFY | DELETE | MOVE;

  int get type;
  String get path;
  bool get isDirectory;
}

class FileSystemException implements IOException {
  final String message;
  final String path;
  final OSError osError;

  const FileSystemException([this.message = "", this.path = "", this.osError]);

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

abstract class IOException implements Exception {}

abstract class IOSink implements StreamSink<List<int>>, StringSink {
  Encoding encoding;
  void add(List<int> data);
  void write(Object obj);
  void writeAll(Iterable objects, [String separator = ""]);
  void writeln([Object obj = ""]);
  void writeCharCode(int charCode);
  void addError(error, [StackTrace stackTrace]);
  Future addStream(Stream<List<int>> stream);
  Future flush();
  Future close();
  Future get done;
}

abstract class Link implements FileSystemEntity {
  Future<Link> create(String target, {bool recursive: false});
  void createSync(String target, {bool recursive: false});
  void updateSync(String target);
  Future<Link> update(String target);
  Future<String> resolveSymbolicLinks();
  String resolveSymbolicLinksSync();
  Future<Link> rename(String newPath);
  Link renameSync(String newPath);
  Link get absolute;
  Future<String> target();
  String targetSync();
}

class OSError {
  static const int noErrorCode = -1;

  final String message;
  final int errorCode;

  const OSError([this.message = "", this.errorCode = noErrorCode]);

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

abstract class RandomAccessFile {
  Future<RandomAccessFile> close();
  void closeSync();
  Future<int> readByte();
  int readByteSync();
  Future<List<int>> read(int bytes);
  List<int> readSync(int bytes);
  Future<int> readInto(List<int> buffer, [int start = 0, int end]);
  int readIntoSync(List<int> buffer, [int start = 0, int end]);
  Future<RandomAccessFile> writeByte(int value);
  int writeByteSync(int value);
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int end]);
  void writeFromSync(List<int> buffer, [int start = 0, int end]);
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding: UTF8});
  void writeStringSync(String string, {Encoding encoding: UTF8});
  Future<int> position();
  int positionSync();
  Future<RandomAccessFile> setPosition(int position);
  void setPositionSync(int position);
  Future<RandomAccessFile> truncate(int length);
  void truncateSync(int length);
  Future<int> length();
  int lengthSync();
  Future<RandomAccessFile> flush();
  void flushSync();
  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]);
  void lockSync(
      [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]);
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]);
  void unlockSync([int start = 0, int end = -1]);
  String get path;
}
