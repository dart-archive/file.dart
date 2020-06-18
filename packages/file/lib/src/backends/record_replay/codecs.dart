// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show systemEncoding;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

import 'common.dart';
import 'errors.dart';
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

typedef _ConverterDelegate<S, T> = T Function(S input);

class _ForwardingConverter<S, T> extends Converter<S, T> {
  const _ForwardingConverter(this._delegate);

  final _ConverterDelegate<S, T> _delegate;

  @override
  T convert(S input) => _delegate(input);
}

class _GenericEncoder extends Converter<dynamic, dynamic> {
  const _GenericEncoder();

  /// Known encoders. Types not covered here will be encoded as a [String]
  /// whose value is the runtime type of the object being encoded.
  ///
  /// When encoding an object, we will walk this map in insertion order looking
  /// for a matching encoder. Thus, when there are two encoders that match an
  /// object, the first one will win.
  static const Map<TypeMatcher<dynamic>, Converter<Object, Object>> _encoders =
      <TypeMatcher<dynamic>, Converter<Object, Object>>{
    TypeMatcher<num>(): Passthrough<num>(),
    TypeMatcher<bool>(): Passthrough<bool>(),
    TypeMatcher<String>(): Passthrough<String>(),
    TypeMatcher<Null>(): Passthrough<Null>(),
    TypeMatcher<Iterable<dynamic>>(): _IterableEncoder(),
    TypeMatcher<Map<dynamic, dynamic>>(): _MapEncoder(),
    TypeMatcher<Symbol>(): _SymbolEncoder(),
    TypeMatcher<DateTime>(): DateTimeCodec.serialize,
    TypeMatcher<Uri>(): UriCodec.serialize,
    TypeMatcher<path.Context>(): PathContextCodec.serialize,
    TypeMatcher<ResultReference<dynamic>>(): _ResultEncoder(),
    TypeMatcher<LiveInvocationEvent<dynamic>>(): _EventEncoder(),
    TypeMatcher<ReplayAware>(): _ReplayAwareEncoder(),
    TypeMatcher<Encoding>(): EncodingCodec.serialize,
    TypeMatcher<FileMode>(): _FileModeEncoder(),
    TypeMatcher<FileStat>(): FileStatCodec.serialize,
    TypeMatcher<FileSystemEntityType>(): EntityTypeCodec.serialize,
    TypeMatcher<FileSystemEvent>(): FileSystemEventCodec.serialize,
    TypeMatcher<FileSystemException>(): _FSExceptionCodec.serialize,
    TypeMatcher<OSError>(): _OSErrorCodec.serialize,
    TypeMatcher<ArgumentError>(): _ArgumentErrorCodec.serialize,
    TypeMatcher<NoSuchMethodError>(): _NoSuchMethodErrorCodec.serialize,
  };

  @override
  dynamic convert(dynamic input) {
    for (TypeMatcher<dynamic> matcher in _encoders.keys) {
      if (matcher.matches(input)) {
        return _encoders[matcher].convert(input);
      }
    }
    return input.runtimeType.toString();
  }
}

/// A trivial conversion turning a Sink<List<String>> into a
/// Sink<String>
class _StringSinkWrapper implements Sink<String> {
  _StringSinkWrapper(this._sink);

  final Sink<List<String>> _sink;

  @override
  void add(String s) => _sink.add(<String>[s]);

  @override
  void close() => _sink.close();
}

/// A [Converter] version of the dart:convert [LineSplitter] (which in
/// 2.0 no longer implements the [Converter] interface).
class LineSplitterConverter extends Converter<String, List<String>> {
  /// Creates a new [LineSplitterConverter]
  const LineSplitterConverter();

  LineSplitter get _splitter => const LineSplitter();

  @override
  List<String> convert(String input) => _splitter.convert(input);
  @override
  StringConversionSink startChunkedConversion(Sink<List<String>> sink) =>
      _splitter.startChunkedConversion(_StringSinkWrapper(sink));
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
    return input == null ? null : DateTime.fromMillisecondsSinceEpoch(input);
  }

  /// Converter that serializes [DateTime] instances.
  static const Converter<DateTime, int> serialize =
      _ForwardingConverter<DateTime, int>(_encode);

  /// Converter that deserializes [DateTime] instances.
  static const Converter<int, DateTime> deserialize =
      _ForwardingConverter<int, DateTime>(_decode);

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
      _ForwardingConverter<Uri, String>(_encode);

  /// Converter that deserializes [Uri] instances.
  static const Converter<String, Uri> deserialize =
      _ForwardingConverter<String, Uri>(_decode);

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

  static path.Context _decode(Map<String, dynamic> input) {
    return path.Context(
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
      _ForwardingConverter<path.Context, Map<String, String>>(_encode);

  /// Converter that deserializes [path.Context] instances.
  static const Converter<Map<String, dynamic>, path.Context> deserialize =
      _ForwardingConverter<Map<String, dynamic>, path.Context>(_decode);

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
      return systemEncoding;
    } else if (input != null) {
      return Encoding.getByName(input);
    }
    return null;
  }

  /// Converter that serializes [Encoding] instances.
  static const Converter<Encoding, String> serialize =
      _ForwardingConverter<Encoding, String>(_encode);

  /// Converter that deserializes [Encoding] instances.
  static const Converter<String, Encoding> deserialize =
      _ForwardingConverter<String, Encoding>(_decode);

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
      case FileMode.read:
        return 'READ';
      case FileMode.write:
        return 'WRITE';
      case FileMode.append:
        return 'APPEND';
      case FileMode.writeOnly:
        return 'WRITE_ONLY';
      case FileMode.writeOnlyAppend:
        return 'WRITE_ONLY_APPEND';
    }
    throw ArgumentError('Invalid value: $input');
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

  static FileStat _decode(Map<String, Object> input) => ReplayFileStat(input);

  /// Converter that serializes [FileStat] instances.
  static const Converter<FileStat, Map<String, Object>> serialize =
      _ForwardingConverter<FileStat, Map<String, Object>>(_encode);

  /// Converter that deserializes [FileStat] instances.
  static const Converter<Map<String, Object>, FileStat> deserialize =
      _ForwardingConverter<Map<String, Object>, FileStat>(_decode);

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
      'file': FileSystemEntityType.file,
      'directory': FileSystemEntityType.directory,
      'link': FileSystemEntityType.link,
      'notFound': FileSystemEntityType.notFound,
    }[input];
  }

  /// Converter that serializes [FileSystemEntityType] instances.
  static const Converter<FileSystemEntityType, String> serialize =
      _ForwardingConverter<FileSystemEntityType, String>(_encode);

  /// Converter that deserializes [FileSystemEntityType] instances.
  static const Converter<String, FileSystemEntityType> deserialize =
      _ForwardingConverter<String, FileSystemEntityType>(_decode);

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
      _FileSystemEvent(input);

  /// Converter that serializes [FileSystemEvent] instances.
  static const Converter<FileSystemEvent, Map<String, Object>> serialize =
      _ForwardingConverter<FileSystemEvent, Map<String, Object>>(_encode);

  /// Converter that deserializes [FileSystemEvent] instances.
  static const Converter<Map<String, Object>, FileSystemEvent> deserialize =
      _ForwardingConverter<Map<String, Object>, FileSystemEvent>(_decode);

  @override
  Converter<FileSystemEvent, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, FileSystemEvent> get decoder => deserialize;
}

class _FileSystemEvent implements FileSystemEvent {
  const _FileSystemEvent(this._data);

  final Map<String, Object> _data;

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
  /// Creates a new [ReviveDirectory].
  const ReviveDirectory(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  Directory convert(String input) => ReplayDirectory(_fileSystem, input);
}

/// Revives a [File] entity reference into a [ReplayFile].
class ReviveFile extends Converter<String, File> {
  /// Creates a new [ReviveFile].
  const ReviveFile(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  File convert(String input) => ReplayFile(_fileSystem, input);
}

/// Revives a [Link] entity reference into a [ReplayLink].
class ReviveLink extends Converter<String, Link> {
  /// Creates a new [ReviveLink].
  const ReviveLink(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  Link convert(String input) => ReplayLink(_fileSystem, input);
}

/// Revives a [FileSystemEntity] entity reference into a [ReplayDirectory],
/// [ReplayFile], or a [ReplayLink] depending on the identifier of the entity
/// reference.
class ReviveFileSystemEntity extends Converter<String, FileSystemEntity> {
  /// Creates a new [ReviveFileSystemEntity].
  const ReviveFileSystemEntity(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  FileSystemEntity convert(String input) {
    if (input.contains('Directory')) {
      return ReplayDirectory(_fileSystem, input);
    } else if (input.contains('File')) {
      return ReplayFile(_fileSystem, input);
    } else {
      return ReplayLink(_fileSystem, input);
    }
  }
}

/// Revives a [RandomAccessFile] entity reference into a
/// [ReplayRandomAccessFile].
class ReviveRandomAccessFile extends Converter<String, RandomAccessFile> {
  /// Creates a new [ReviveRandomAccessFile] that will derive its behavior
  /// from the specified file system's recording.
  const ReviveRandomAccessFile(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  RandomAccessFile convert(String input) =>
      ReplayRandomAccessFile(_fileSystem, input);
}

/// Revives an [IOSink] entity reference into a [ReplayIOSink].
class ReviveIOSink extends Converter<String, IOSink> {
  /// Creates a new [ReviveIOSink] that will derive its behavior from the
  /// specified file system's recording.
  const ReviveIOSink(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  IOSink convert(String input) => ReplayIOSink(_fileSystem, input);
}

/// Converts all elements of a [List], returning a new [List] of converted
/// elements.
class ConvertElements<S, T> extends Converter<List<S>, List<T>> {
  /// Creates a new [ConvertElements] that will use the specified
  /// [elementConverter] to convert the elements of an [Iterable].
  const ConvertElements(Converter<S, T> elementConverter)
      : _delegate = elementConverter;

  final Converter<S, T> _delegate;

  @override
  List<T> convert(List<S> input) => input.map(_delegate.convert).toList();
}

/// Converts a `List<S>` into a `List<T>` by casting it to the appropriate
/// type. The list must contain only elements of type `T`, or a runtime error
/// will be thrown.
class CastList<S, T> extends Converter<List<S>, List<T>> {
  /// Creates a new [CastList].
  const CastList();

  @override
  List<T> convert(List<S> input) => input.cast<T>();
}

/// Converts a [List] of elements into a [Stream] of the same elements.
class ToStream<T> extends Converter<List<T>, Stream<T>> {
  /// Creates a new [ToStream].
  const ToStream();

  @override
  Stream<T> convert(List<T> input) => Stream<T>.fromIterable(input);
}

/// Converts a blob reference (serialized as a [String] of the form
/// `!<filename>`) into a byte list.
class BlobToBytes extends Converter<String, Uint8List> {
  /// Creates a new [BlobToBytes] that will use the specified file system's
  /// recording to load the blob.
  const BlobToBytes(this._fileSystem);

  final ReplayFileSystemImpl _fileSystem;

  @override
  Uint8List convert(String input) {
    assert(input.startsWith('!'));
    String basename = input.substring(1);
    String dirname = _fileSystem.recording.path;
    String path = _fileSystem.recording.fileSystem.path.join(dirname, basename);
    File file = _fileSystem.recording.fileSystem.file(path);
    return file.readAsBytesSync();
  }
}

/// Converts serialized errors into throwable objects.
class ToError extends Converter<dynamic, dynamic> {
  /// Creates a new [ToError].
  const ToError();

  /// Known decoders (keyed by `type`). Types not covered here will be decoded
  /// into [InvocationException].
  static const Map<String, Converter<Object, Object>> _decoders =
      <String, Converter<Object, Object>>{
    _FSExceptionCodec.type: _FSExceptionCodec.deserialize,
    _OSErrorCodec.type: _OSErrorCodec.deserialize,
    _ArgumentErrorCodec.type: _ArgumentErrorCodec.deserialize,
    _NoSuchMethodErrorCodec.type: _NoSuchMethodErrorCodec.deserialize,
  };

  @override
  dynamic convert(dynamic input) {
    if (input is Map) {
      String errorType = input[kManifestErrorTypeKey];
      if (_decoders.containsKey(errorType)) {
        return _decoders[errorType].convert(input);
      }
    }
    return InvocationException();
  }
}

class _FSExceptionCodec
    extends Codec<FileSystemException, Map<String, Object>> {
  const _FSExceptionCodec();

  static const String type = 'FileSystemException';

  static Map<String, Object> _encode(FileSystemException exception) {
    return <String, Object>{
      kManifestErrorTypeKey: type,
      'message': exception.message,
      'path': exception.path,
      'osError': encode(exception.osError),
    };
  }

  static FileSystemException _decode(Map<String, Object> input) {
    Object osError = input['osError'];
    return FileSystemException(
      input['message'],
      input['path'],
      osError == null ? null : const ToError().convert(osError),
    );
  }

  static const Converter<FileSystemException, Map<String, Object>> serialize =
      _ForwardingConverter<FileSystemException, Map<String, Object>>(_encode);

  static const Converter<Map<String, Object>, FileSystemException> deserialize =
      _ForwardingConverter<Map<String, Object>, FileSystemException>(_decode);

  @override
  Converter<FileSystemException, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, FileSystemException> get decoder =>
      deserialize;
}

class _OSErrorCodec extends Codec<OSError, Map<String, Object>> {
  const _OSErrorCodec();

  static const String type = 'OSError';

  static Map<String, Object> _encode(OSError error) {
    return <String, Object>{
      kManifestErrorTypeKey: type,
      'message': error.message,
      'errorCode': error.errorCode,
    };
  }

  static OSError _decode(Map<String, Object> input) {
    return OSError(input['message'], input['errorCode']);
  }

  static const Converter<OSError, Map<String, Object>> serialize =
      _ForwardingConverter<OSError, Map<String, Object>>(_encode);

  static const Converter<Map<String, Object>, OSError> deserialize =
      _ForwardingConverter<Map<String, Object>, OSError>(_decode);

  @override
  Converter<OSError, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, OSError> get decoder => deserialize;
}

class _ArgumentErrorCodec extends Codec<ArgumentError, Map<String, Object>> {
  const _ArgumentErrorCodec();

  static const String type = 'ArgumentError';

  static Map<String, Object> _encode(ArgumentError error) {
    return <String, Object>{
      kManifestErrorTypeKey: type,
      'message': encode(error.message),
      'invalidValue': encode(error.invalidValue),
      'name': error.name,
    };
  }

  static ArgumentError _decode(Map<String, Object> input) {
    dynamic message = input['message'];
    dynamic invalidValue = input['invalidValue'];
    String name = input['name'];
    if (invalidValue != null) {
      return ArgumentError.value(invalidValue, name, message);
    } else if (name != null) {
      return ArgumentError.notNull(name);
    } else {
      return ArgumentError(message);
    }
  }

  static const Converter<ArgumentError, Map<String, Object>> serialize =
      _ForwardingConverter<ArgumentError, Map<String, Object>>(_encode);

  static const Converter<Map<String, Object>, ArgumentError> deserialize =
      _ForwardingConverter<Map<String, Object>, ArgumentError>(_decode);

  @override
  Converter<ArgumentError, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, ArgumentError> get decoder => deserialize;
}

class _NoSuchMethodErrorCodec
    extends Codec<NoSuchMethodError, Map<String, Object>> {
  const _NoSuchMethodErrorCodec();

  static const String type = 'NoSuchMethodError';

  static Map<String, Object> _encode(NoSuchMethodError error) {
    return <String, Object>{
      kManifestErrorTypeKey: type,
      'toString': error.toString(),
    };
  }

  static NoSuchMethodError _decode(Map<String, Object> input) {
    return _NoSuchMethodError(input['toString']);
  }

  static const Converter<NoSuchMethodError, Map<String, Object>> serialize =
      _ForwardingConverter<NoSuchMethodError, Map<String, Object>>(_encode);

  static const Converter<Map<String, Object>, NoSuchMethodError> deserialize =
      _ForwardingConverter<Map<String, Object>, NoSuchMethodError>(_decode);

  @override
  Converter<NoSuchMethodError, Map<String, Object>> get encoder => serialize;

  @override
  Converter<Map<String, Object>, NoSuchMethodError> get decoder => deserialize;
}

class _NoSuchMethodError extends Error implements NoSuchMethodError {
  _NoSuchMethodError(this._toString);

  final String _toString;

  @override
  String toString() => _toString;
}
