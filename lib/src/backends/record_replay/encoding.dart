// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;
import 'package:path/path.dart' as p;

import 'common.dart';
import 'events.dart';
import 'recording_directory.dart';
import 'recording_file.dart';
import 'recording_file_system_entity.dart';
import 'recording_io_sink.dart';
import 'recording_link.dart';
import 'recording_random_access_file.dart';
import 'result_reference.dart';

/// Encodes an object into a JSON-ready representation.
typedef dynamic _Encoder(dynamic object);

/// Known encoders. Types not covered here will be encoded using
/// [_encodeDefault].
///
/// When encoding an object, we will walk this map in iteration order looking
/// for a matching encoder. Thus, when there are two encoders that match an
//  object, the first one will win.
const Map<TypeMatcher<dynamic>, _Encoder> _kEncoders =
    const <TypeMatcher<dynamic>, _Encoder>{
  const TypeMatcher<num>(): _encodeRaw,
  const TypeMatcher<bool>(): _encodeRaw,
  const TypeMatcher<String>(): _encodeRaw,
  const TypeMatcher<Null>(): _encodeRaw,
  const TypeMatcher<List<dynamic>>(): _encodeRaw,
  const TypeMatcher<Map<dynamic, dynamic>>(): _encodeMap,
  const TypeMatcher<Iterable<dynamic>>(): _encodeIterable,
  const TypeMatcher<Symbol>(): getSymbolName,
  const TypeMatcher<DateTime>(): _encodeDateTime,
  const TypeMatcher<Uri>(): _encodeUri,
  const TypeMatcher<p.Context>(): _encodePathContext,
  const TypeMatcher<ResultReference<dynamic>>(): _encodeResultReference,
  const TypeMatcher<LiveInvocationEvent<dynamic>>(): _encodeEvent,
  const TypeMatcher<FileSystem>(): _encodeFileSystem,
  const TypeMatcher<RecordingDirectory>(): _encodeFileSystemEntity,
  const TypeMatcher<RecordingFile>(): _encodeFileSystemEntity,
  const TypeMatcher<RecordingLink>(): _encodeFileSystemEntity,
  const TypeMatcher<RecordingIOSink>(): _encodeIOSink,
  const TypeMatcher<RecordingRandomAccessFile>(): _encodeRandomAccessFile,
  const TypeMatcher<Encoding>(): _encodeEncoding,
  const TypeMatcher<FileMode>(): _encodeFileMode,
  const TypeMatcher<FileStat>(): _encodeFileStat,
  const TypeMatcher<FileSystemEntityType>(): _encodeFileSystemEntityType,
  const TypeMatcher<FileSystemEvent>(): _encodeFileSystemEvent,
};

/// Encodes [object] into a JSON-ready representation.
///
/// This function is intended to be used as the `toEncodable` argument to the
/// `JsonEncoder` constructors.
///
/// See also:
///   - [JsonEncoder.withIndent]
dynamic encode(dynamic object) {
  _Encoder encoder = _encodeDefault;
  for (TypeMatcher<dynamic> matcher in _kEncoders.keys) {
    if (matcher.matches(object)) {
      encoder = _kEncoders[matcher];
      break;
    }
  }
  return encoder(object);
}

/// Default encoder (used for types not covered in [_kEncoders]).
String _encodeDefault(dynamic object) => object.runtimeType.toString();

/// Pass-through encoder.
dynamic _encodeRaw(dynamic object) => object;

List<T> _encodeIterable<T>(Iterable<T> iterable) => iterable.toList();

/// Encodes the map keys, and passes the values through.
///
/// As [JsonEncoder] encodes an object graph, it will repeatedly call
/// `toEncodable` to encode unknown types, so any values in a map that need
/// special encoding will already be handled by `JsonEncoder`. However, the
/// encoder won't try to encode map *keys* by default, which is why we encode
/// them here.
Map<String, T> _encodeMap<T>(Map<dynamic, T> map) {
  Map<String, T> encoded = <String, T>{};
  for (dynamic key in map.keys) {
    String encodedKey = encode(key);
    encoded[encodedKey] = map[key];
  }
  return encoded;
}

int _encodeDateTime(DateTime dateTime) => dateTime.millisecondsSinceEpoch;

String _encodeUri(Uri uri) => uri.toString();

Map<String, String> _encodePathContext(p.Context context) => <String, String>{
      'style': context.style.name,
      'cwd': context.current,
    };

dynamic _encodeResultReference(ResultReference<dynamic> reference) =>
    reference.serializedValue;

Map<String, dynamic> _encodeEvent(LiveInvocationEvent<dynamic> event) =>
    event.serialize();

String _encodeFileSystem(FileSystem fs) => kFileSystemEncodedValue;

/// Encodes a file system entity by using its `uid` as a reference identifier.
/// During replay, this allows us to tie the return value of of one event to
/// the object of another.
String _encodeFileSystemEntity(
    RecordingFileSystemEntity<FileSystemEntity, io.FileSystemEntity> entity) {
  return '${entity.runtimeType}@${entity.uid}';
}

String _encodeIOSink(RecordingIOSink sink) {
  return '${sink.runtimeType}@${sink.uid}';
}

String _encodeRandomAccessFile(RecordingRandomAccessFile raf) {
  return '${raf.runtimeType}@${raf.uid}';
}

String _encodeEncoding(Encoding encoding) => encoding.name;

String _encodeFileMode(FileMode fileMode) {
  switch (fileMode) {
    case FileMode.READ:
      return 'READ';
    case FileMode.WRITE:
      return 'WRITE';
    case FileMode.APPEND:
      return 'APPEND';
    case FileMode.WRITE_ONLY:
      return 'WRITE_ONLY';
    case FileMode.WRITE_ONLY_APPEND:
      return 'WRITE_ONLY_APPEND';
  }
  throw new ArgumentError('Invalid value: $fileMode');
}

Map<String, dynamic> _encodeFileStat(FileStat stat) => <String, dynamic>{
      'changed': stat.changed,
      'modified': stat.modified,
      'accessed': stat.accessed,
      'type': stat.type,
      'mode': stat.mode,
      'size': stat.size,
      'modeString': stat.modeString(),
    };

String _encodeFileSystemEntityType(FileSystemEntityType type) =>
    type.toString();

Map<String, dynamic> _encodeFileSystemEvent(FileSystemEvent event) =>
    <String, dynamic>{
      'type': event.type,
      'path': event.path,
    };
