// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show SYSTEM_ENCODING;

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

import 'common.dart';
import 'events.dart';
import 'replay_directory.dart';
import 'replay_file.dart';
import 'replay_file_stat.dart';
import 'replay_file_system.dart';
import 'replay_io_sink.dart';
import 'replay_link.dart';
import 'replay_random_access_file.dart';
import 'result_reference.dart';

/// Encodes an arbitrary [object] into a JSON-ready representation (a number,
/// boolean, string, null, list, or map).
///
/// Returns a value suitable for conversion into JSON using [JsonEncoder]
/// without the need for a `toEncodable` argument.
dynamic encode(dynamic object) => const _GenericEncoder().convert(object);

typedef T _ConverterDelegate<S, T>(S input);

class _ForwardingConverter<S, T> extends Converter<S, T> {
  final _ConverterDelegate<S, T> _delegate;

  const _ForwardingConverter(this._delegate);

  @override
  T convert(S input) => _delegate(input);
}

class _GenericEncoder extends Converter<dynamic, dynamic> {
  const _GenericEncoder();

  /// Known encoders. Types not covered here will be encoded using
  /// [_encodeDefault].
  ///
  /// When encoding an object, we will walk this map in insertion order looking
  /// for a matching encoder. Thus, when there are two encoders that match an
  /// object, the first one will win.
  static const Map<TypeMatcher<dynamic>, Converter<Object, Object>> _encoders =
      const <TypeMatcher<dynamic>, Converter<Object, Object>>{
    const TypeMatcher<num>(): const Passthrough<num>(),
    const TypeMatcher<bool>(): const Passthrough<bool>(),
    const TypeMatcher<String>(): const Passthrough<String>(),
    const TypeMatcher<Null>(): const Passthrough<Null>(),
    const TypeMatcher<Iterable<dynamic>>(): const _IterableEncoder(),
    const TypeMatcher<Map<dynamic, dynamic>>(): const _MapEncoder(),
    const TypeMatcher<Symbol>(): const _SymbolEncoder(),
    const TypeMatcher<DateTime>(): DateTimeCodec.serialize,
    const TypeMatcher<Uri>(): UriCodec.serialize,
    const TypeMatcher<path.Context>(): PathContextCodec.serialize,
    const TypeMatcher<ResultReference<dynamic>>(): const _ResultEncoder(),
    const TypeMatcher<LiveInvocationEvent<dynamic>>(): const _EventEncoder(),
    const TypeMatcher<ReplayAware>(): const _ReplayAwareEncoder(),
    const TypeMatcher<Encoding>(): EncodingCodec.serialize,
    const TypeMatcher<FileMode>(): const _FileModeEncoder(),
    const TypeMatcher<FileStat>(): FileStatCodec.serialize,
    const TypeMatcher<FileSystemEntityType>(): EntityTypeCodec.serialize,
    const TypeMatcher<FileSystemEvent>(): FileSystemEventCodec.serialize,
  };

  /// Default encoder (used for types not covered in [_encoders]).
  static String _encodeDefault(dynamic object) => object.runtimeType.toString();

  @override
  dynamic convert(dynamic input) {
    Converter<dynamic, dynamic> encoder =
        const _ForwardingConverter<dynamic, String>(_encodeDefault);
    for (TypeMatcher<dynamic> matcher in _encoders.keys) {
      if (matcher.matches(input)) {
        encoder = _encoders[matcher];
        break;
      }
    }
    return encoder.convert(input);
  }
}

/// Converter that leaves an object untouched.
class Passthrough<T> extends Converter<T, T> {
  /// Creates a new [Passthrough].
  const Passthrough();

  @override
  T convert(T input) => input;
}

class _IterableEncoder extends Converter<Iterable<dynamic>, List<dynamic>> {
  const _IterableEncoder();

  @override
  List<dynamic> convert(Iterable<dynamic> input) {
    _GenericEncoder generic = const _GenericEncoder();
    List<dynamic> encoded = <dynamic>[];
    for (Object element in input) {
      encoded.add(generic.convert(element));
    }
    return encoded;
  }
}

class _MapEncoder
    extends Converter<Map<dynamic, dynamic>, Map<String, dynamic>> {
  const _MapEncoder();

  @override
  Map<String, dynamic> convert(Map<dynamic, dynamic> input) {
    _GenericEncoder generic = const _GenericEncoder();
    Map<String, dynamic> encoded = <String, dynamic>{};
    for (dynamic key in input.keys) {
      String encodedKey = generic.convert(key);
      encoded[encodedKey] = generic.convert(input[key]);
    }
    return encoded;
  }
}

class _SymbolEncoder extends Converter<Symbol, String> {
  const _SymbolEncoder();

  @override
  String convert(Symbol input) => getSymbolName(input);
}

/// A [DateTimeCodec] serializes and deserializes [DateTime] instances.
class DateTimeCodec extends Codec<DateTime, int> {
  /// Creates a new [DateTimeCodec].
  const DateTimeCodec();

  static int _encode(DateTime input) => input?.millisecondsSinceEpoch;

  static DateTime _decode(int input) {
    return input == null
        ? null
        : new DateTime.fromMillisecondsSinceEpoch(input);
  }

  /// Converter that serializes [DateTime] instances.
  static const Converter<DateTime, int> serialize =
      const _ForwardingConverter<DateTime, int>(_encode);

  /// Converter that deserializes [DateTime] instances.
  static const Converter<int, DateTime> deserialize =
      const _ForwardingConverter<int, DateTime>(_decode);

  @override
  Converter<DateTime, int> get encoder => serialize;

  @override
  Converter<int, DateTime> get decoder => deserialize;
}

/// A [UriCodec] serializes and deserializes [Uri] instances.
class UriCodec extends Codec<Uri, String> {
  /// Creates a new [UriCodec].
  const UriCodec();

  static String _encode(Uri input) => input.toString();

  static Uri _decode(String input) => Uri.parse(input);

  /// Converter that serializes [Uri] instances.
  static const Converter<Uri, String> serialize =
      const _ForwardingConverter<Uri, String>(_encode);

  /// Converter that deserializes [Uri] instances.
  static const Converter<String, Uri> deserialize =
      const _ForwardingConverter<String, Uri>(_decode);

  @override
  Converter<Uri, String> get encoder => serialize;

  @override
  Converter<String, Uri> get decoder => deserialize;
}

/// A [PathContextCodec] serializes and deserializes [path.Context] instances.
class PathContextCodec extends Codec<path.Context, Map<String, String>> {
  /// Creates a new [PathContextCodec].
  const PathContextCodec();

  static Map<String, String> _encode(path.Context input) {
    return <String, String>{
      'style': input.style.name,
      'cwd': input.current,
    };
  }

  static path.Context _decode(Map<String, String> input) {
    return new path.Context(
      style: <String, path.Style>{
        'posix': path.Style.posix,
        'windows': path.Style.windows,
        'url': path.Style.url,
      }[input['style']],
      current: input['cwd'],
    );
  }

  /// Converter that serializes [path.Context] instances.
  static const Converter<path.Context, Map<String, String>> serialize =
      const _ForwardingConverter<path.Context, Map<String, String>>(_encode);

  /// Converter that deserializes [path.Context] instances.
  static const Converter<Map<String, String>, path.Context> deserialize =
      const _ForwardingConverter<Map<String, String>, path.Context>(_decode);

  @override
  Converter<path.Context, Map<String, String>> get encoder => serialize;

  @override
  Converter<Map<String, String>, path.Context> get decoder => deserialize;
}

class _ResultEncoder extends Converter<ResultReference<dynamic>, Object> {
  const _ResultEncoder();

  @override
  Object convert(ResultReference<dynamic> input) => input.serializedValue;
}

class _EventEncoder
    extends Converter<LiveInvocationEvent<dynamic>, Map<String, Object>> {
  const _EventEncoder();

  @override
  Map<String, Object> convert(LiveInvocationEvent<dynamic> input) {
    return input.serialize();
  }
}

class _ReplayAwareEncoder extends Converter<ReplayAware, String> {
  const _ReplayAwareEncoder();

  @override
  String convert(ReplayAware input) => input.identifier;
}

/// An [EncodingCodec] serializes and deserializes [Encoding] instances.
class EncodingCodec extends Codec<Encoding, String> {
  /// Creates a new [EncodingCodec].
  const EncodingCodec();

  static String _encode(Encoding input) => input.name;

  static Encoding _decode(String input) {
    if (input == 'system') {
      return SYSTEM_ENCODING;
    } else if (input != null) {
      return Encoding.getByName(input);
    }
    return null;
  }

  /// Converter that serializes [Encoding] instances.
  static const Converter<Encoding, String> serialize =
      const _ForwardingConverter<Encoding, String>(_encode);

  /// Converter that deserializes [Encoding] instances.
  static const Converter<String, Encoding> deserialize =
      const _ForwardingConverter<String, Encoding>(_decode);

  @override
  Converter<Encoding, String> get encoder => serialize;

  @override
  Converter<String, Encoding> get decoder => deserialize;
}

class _FileModeEncoder extends Converter<FileMode, String> {
  const _FileModeEncoder();

  @override
  String convert(FileMode input) {
    switch (input) {
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
    throw new ArgumentError('Invalid value: $input');
  }
}

/// An [FileStatCodec] serializes and deserializes [FileStat] instances.
class FileStatCodec extends Codec<FileStat, Map<String, Object>> {
  /// Creates a new [FileStatCodec].
  const FileStatCodec();

  static Map<String, Object> _encode(FileStat input) {
    return <String, dynamic>{
      'changed': const DateTimeCodec().encode(input.changed),
      'modified': const DateTimeCodec().encode(input.modified),
      'accessed': const DateTimeCodec().encode(input.accessed),
      'type': const EntityTypeCodec().encode(input.type),
      'mode': input.mode,
      'size': input.size,
      'modeString': input.modeString(),
    };
  }

  static FileStat _decode(Map<String, Object> input) =>
      new ReplayFileStat(input);

  /// Converter that serializes [FileStat] instances.
  static const Converter<FileStat, Map<String, Object>> serialize =
      const _ForwardingConverter<FileStat, Map<String, Object>>(_encode);

  /// Converter that deserializes [FileStat] instances.
  static const Converter<Map<String, Object>, FileStat> deserialize =
      const _ForwardingConverter<Map<String, Object>, FileStat>(_decode);

  @override
  Converter<FileStat, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, FileStat> get decoder => deserialize;
}

/// An [EntityTypeCodec] serializes and deserializes [FileSystemEntity]
/// instances.
class EntityTypeCodec extends Codec<FileSystemEntityType, String> {
  /// Creates a new [EntityTypeCodec].
  const EntityTypeCodec();

  static String _encode(FileSystemEntityType input) => input.toString();

  static FileSystemEntityType _decode(String input) {
    return const <String, FileSystemEntityType>{
      'FILE': FileSystemEntityType.FILE,
      'DIRECTORY': FileSystemEntityType.DIRECTORY,
      'LINK': FileSystemEntityType.LINK,
      'NOT_FOUND': FileSystemEntityType.NOT_FOUND,
    }[input];
  }

  /// Converter that serializes [FileSystemEntityType] instances.
  static const Converter<FileSystemEntityType, String> serialize =
      const _ForwardingConverter<FileSystemEntityType, String>(_encode);

  /// Converter that deserializes [FileSystemEntityType] instances.
  static const Converter<String, FileSystemEntityType> deserialize =
      const _ForwardingConverter<String, FileSystemEntityType>(_decode);

  @override
  Converter<FileSystemEntityType, String> get encoder => serialize;

  @override
  Converter<String, FileSystemEntityType> get decoder => deserialize;
}

/// A [FileSystemEventCodec] serializes and deserializes [FileSystemEvent]
/// instances.
class FileSystemEventCodec extends Codec<FileSystemEvent, Map<String, Object>> {
  /// Creates a new [FileSystemEventCodec].
  const FileSystemEventCodec();

  static Map<String, Object> _encode(FileSystemEvent input) {
    return <String, Object>{
      'type': input.type,
      'path': input.path,
      'isDirectory': input.isDirectory,
    };
  }

  static FileSystemEvent _decode(Map<String, Object> input) =>
      new _FileSystemEvent(input);

  /// Converter that serializes [FileSystemEvent] instances.
  static const Converter<FileSystemEvent, Map<String, Object>> serialize =
      const _ForwardingConverter<FileSystemEvent, Map<String, Object>>(_encode);

  /// Converter that deserializes [FileSystemEvent] instances.
  static const Converter<Map<String, Object>, FileSystemEvent> deserialize =
      const _ForwardingConverter<Map<String, Object>, FileSystemEvent>(_decode);

  @override
  Converter<FileSystemEvent, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, FileSystemEvent> get decoder => deserialize;
}

class _FileSystemEvent implements FileSystemEvent {
  final Map<String, Object> _data;

  const _FileSystemEvent(this._data);

  @override
  int get type => _data['type'];

  @override
  String get path => _data['path'];

  @override
  bool get isDirectory => _data['isDirectory'];
}

/// Converts an object into a [Future] that completes with that object.
class ToFuture<T> extends Converter<T, Future<T>> {
  /// Creates a new [ToFuture].
  const ToFuture();

  @override
  Future<T> convert(T input) async => input;
}

/// Converts an object into a single-element [List] containing that object.
class Listify<T> extends Converter<T, List<T>> {
  /// Creates a new [Listify].
  const Listify();

  @override
  List<T> convert(T input) => <T>[input];
}

/// Revives a [Directory] entity reference into a [ReplayDirectory].
class ReviveDirectory extends Converter<String, Directory> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [ReviveDirectory].
  const ReviveDirectory(this._fileSystem);

  @override
  Directory convert(String input) => new ReplayDirectory(_fileSystem, input);
}

/// Revives a [File] entity reference into a [ReplayFile].
class ReviveFile extends Converter<String, File> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [ReviveFile].
  const ReviveFile(this._fileSystem);

  @override
  File convert(String input) => new ReplayFile(_fileSystem, input);
}

/// Revives a [Link] entity reference into a [ReplayLink].
class ReviveLink extends Converter<String, Link> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [ReviveLink].
  const ReviveLink(this._fileSystem);

  @override
  Link convert(String input) => new ReplayLink(_fileSystem, input);
}

/// Revives a [FileSystemEntity] entity reference into a [ReplayDirectory],
/// [ReplayFile], or a [ReplayLink] depending on the identifier of the entity
/// reference.
class ReviveFileSystemEntity extends Converter<String, FileSystemEntity> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [ReviveFileSystemEntity].
  const ReviveFileSystemEntity(this._fileSystem);

  @override
  FileSystemEntity convert(String input) {
    if (input.contains('Directory')) {
      return new ReplayDirectory(_fileSystem, input);
    } else if (input.contains('File')) {
      return new ReplayFile(_fileSystem, input);
    } else {
      return new ReplayLink(_fileSystem, input);
    }
  }
}

/// Revives a [RandomAccessFile] entity reference into a
/// [ReplayRandomAccessFile].
class ReviveRandomAccessFile extends Converter<String, RandomAccessFile> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [ReviveRandomAccessFile] that will derive its behavior
  /// from the specified file system's recording.
  const ReviveRandomAccessFile(this._fileSystem);

  @override
  RandomAccessFile convert(String input) =>
      new ReplayRandomAccessFile(_fileSystem, input);
}

/// Revives an [IOSink] entity reference into a [ReplayIOSink].
class ReviveIOSink extends Converter<String, IOSink> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [ReviveIOSink] that will derive its behavior from the
  /// specified file system's recording.
  const ReviveIOSink(this._fileSystem);

  @override
  IOSink convert(String input) => new ReplayIOSink(_fileSystem, input);
}

/// Converts all elements of a [List], returning a new [List] of converted
/// elements.
class ConvertElements<S, T> extends Converter<List<S>, List<T>> {
  final Converter<S, T> _delegate;

  /// Creates a new [ConvertElements] that will use the specified
  /// [elementConverter] to convert the elements of an [Iterable].
  const ConvertElements(Converter<S, T> elementConverter)
      : _delegate = elementConverter;

  @override
  List<T> convert(List<S> input) => input.map(_delegate.convert).toList();
}

/// Converts a [List] of elements into a [Stream] of the same elements.
class ToStream<T> extends Converter<List<T>, Stream<T>> {
  /// Creates a new [ToStream].
  const ToStream();

  @override
  Stream<T> convert(List<T> input) => new Stream<T>.fromIterable(input);
}

/// Converts a blob reference (serialized as a [String] of the form
/// `!<filename>`) into a byte list.
class BlobToBytes extends Converter<String, List<int>> {
  final ReplayFileSystemImpl _fileSystem;

  /// Creates a new [BlobToBytes] that will use the specified file system's
  /// recording to load the blob.
  const BlobToBytes(this._fileSystem);

  @override
  List<int> convert(String input) {
    assert(input.startsWith('!'));
    String basename = input.substring(1);
    String dirname = _fileSystem.recording.path;
    String path = _fileSystem.recording.fileSystem.path.join(dirname, basename);
    File file = _fileSystem.recording.fileSystem.file(path);
    return file.readAsBytesSync();
  }
}
