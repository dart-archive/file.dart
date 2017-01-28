// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

/// Encodes an object into a JSON-ready representation.
typedef dynamic _Encoder(dynamic object);

/// This class is a work-around for the "is" operator not accepting a variable
/// value as its right operand (https://github.com/dart-lang/sdk/issues/27680).
class _TypeMatcher<T> {
  /// Creates a type matcher for the given type parameter.
  const _TypeMatcher();

  /// Returns `true` if the given object is of type `T`.
  bool check(dynamic object) => object is T;
}

/// Known encoders. Types not covered here will be encoded using
/// [_encodeDefault].
///
/// When encoding an object, we will walk this map in iteration order looking
/// for a matching encoder. Thus, when there are two encoders that match an
//  object, the first one will win.
const Map<_TypeMatcher, _Encoder> _kEncoders = const <_TypeMatcher, _Encoder>{
  const _TypeMatcher<num>(): _encodeRaw,
  const _TypeMatcher<bool>(): _encodeRaw,
  const _TypeMatcher<String>(): _encodeRaw,
  const _TypeMatcher<Null>(): _encodeRaw,
  const _TypeMatcher<List>(): _encodeRaw,
  const _TypeMatcher<Map>(): _encodeMap,
  const _TypeMatcher<Iterable>(): _encodeIterable,
  const _TypeMatcher<Symbol>(): _getSymbolName,
  const _TypeMatcher<DateTime>(): _encodeDateTime,
  const _TypeMatcher<Uri>(): _encodeUri,
  const _TypeMatcher<p.Context>(): _encodePathContext,
  const _TypeMatcher<_Event>(): _encodeEvent,
  const _TypeMatcher<FileSystem>(): _encodeFileSystem,
  const _TypeMatcher<_RecordingDirectory>(): _encodeFileSystemEntity,
  const _TypeMatcher<_RecordingFile>(): _encodeFileSystemEntity,
  const _TypeMatcher<_RecordingLink>(): _encodeFileSystemEntity,
  const _TypeMatcher<_RecordingIOSink>(): _encodeIOSink,
  const _TypeMatcher<_RecordingRandomAccessFile>(): _encodeRandomAccessFile,
  const _TypeMatcher<Encoding>(): _encodeEncoding,
  const _TypeMatcher<FileMode>(): _encodeFileMode,
  const _TypeMatcher<FileStat>(): _encodeFileStat,
  const _TypeMatcher<FileSystemEntityType>(): _encodeFileSystemEntityType,
  const _TypeMatcher<FileSystemEvent>(): _encodeFileSystemEvent,
};

/// Encodes [object] into a JSON-ready representation.
///
/// This function is intended to be used as the `toEncodable` argument to the
/// `JsonEncoder` constructors.
///
/// See also:
///   - [JsonEncoder.withIndent]
dynamic _encode(dynamic object) {
  _Encoder encoder = _encodeDefault;
  for (_TypeMatcher matcher in _kEncoders.keys) {
    if (matcher.check(object)) {
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
    String encodedKey = _encode(key);
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

Map<String, dynamic> _encodeEvent(_Event event) => event.encode();

String _encodeFileSystem(FileSystem fs) => _kFileSystemEncodedValue;

/// Encodes a file system entity by using its `uid` as a reference identifier.
/// During replay, this allows us to tie the return value of of one event to
/// the object of another.
String _encodeFileSystemEntity(_RecordingFileSystemEntity entity) {
  return '${entity.runtimeType}@${entity.uid}';
}

String _encodeIOSink(_RecordingIOSink sink) {
  return '${sink.runtimeType}@${sink.uid}';
}

String _encodeRandomAccessFile(_RecordingRandomAccessFile raf) {
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
