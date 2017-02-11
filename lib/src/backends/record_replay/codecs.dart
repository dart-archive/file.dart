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

/// Converter that leaves object untouched.
const Converter<dynamic, dynamic> kPassthrough = const _PassthroughConverter();

/// Converter that will turn an object into a [Future] of that object.
const Converter<dynamic, dynamic> kFutureReviver =
    const _FutureReviver<dynamic>();

/// Converter that will convert an [Iterable] into a [Stream].
Converter<dynamic, dynamic> kStreamReviver = const _StreamReviver();

/// Converter that will deserialize a [DateTime].
const Converter<dynamic, dynamic> kDateTimeReviver = _DateTimeCodec.kDecoder;

/// Converter that will deserialize a [FileStat].
const Converter<dynamic, dynamic> kFileStatReviver = _FileStatCodec.kDecoder;

/// Converter that will deserialize a [FileSystemEntityType].
const Converter<dynamic, dynamic> kEntityTypeReviver =
    _EntityTypeCodec.kDecoder;

/// Converter that will deserialize a [path.Context].
const Converter<dynamic, dynamic> kPathContextReviver =
    _PathContextCodec.kDecoder;

/// Converter that will deserialize a [Uri].
const Converter<dynamic, dynamic> kUriReviver = _UriCodec.kDecoder;

/// Converter that will deserialize a [Encoding].
const Converter<dynamic, dynamic> kEncodingReviver = _EncodingCodec.kDecoder;

/// Converter that will deserialize a [FileSystemEvent].
const Converter<dynamic, dynamic> kFileSystemEventReviver =
    _FileSystemEventCodec.kDecoder;

/// Converter that will deserialize each element of a [List] by delegating to
/// the specified [elementReviver].
Converter<dynamic, dynamic> listReviver(
        Converter<dynamic, dynamic> elementReviver) =>
    new _ListReviver(elementReviver);

/// Converter that will deserialize a blob file reference into the file's bytes.
Converter<dynamic, dynamic> blobReviver(ReplayFileSystemImpl fileSystem) =>
    new _BlobReviver(fileSystem);

/// Converter that will deserialize a [ReplayDirectory].
Converter<dynamic, dynamic> directoryReviver(ReplayFileSystemImpl fileSystem) =>
    new _DirectoryReviver(fileSystem);

/// Converter that will deserialize a [ReplayFile].
Converter<dynamic, dynamic> fileReviver(ReplayFileSystemImpl fileSystem) =>
    new _FileReviver(fileSystem);

/// Converter that will deserialize a [ReplayLink].
Converter<dynamic, dynamic> linkReviver(ReplayFileSystemImpl fileSystem) =>
    new _LinkReviver(fileSystem);

/// Converter that will deserialize an arbitrary [FileSystemEntity].
Converter<dynamic, dynamic> entityReviver(ReplayFileSystemImpl fileSystem) =>
    new _FileSystemEntityReviver(fileSystem);

/// Converter that will deserialize a [ReplayRandomAccessFile].
Converter<dynamic, dynamic> randomAccessFileReviver(
        ReplayFileSystemImpl fileSystem) =>
    new _RandomAccessFileReviver(fileSystem);

/// Converter that will deserialize a [ReplayRandomAccessFile].
Converter<dynamic, dynamic> ioSinkReviver(ReplayFileSystemImpl fileSystem) =>
    new _IOSinkReviver(fileSystem);

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
    const TypeMatcher<num>(): const _PassthroughConverter(),
    const TypeMatcher<bool>(): const _PassthroughConverter(),
    const TypeMatcher<String>(): const _PassthroughConverter(),
    const TypeMatcher<Null>(): const _PassthroughConverter(),
    const TypeMatcher<Iterable<dynamic>>(): const _IterableEncoder(),
    const TypeMatcher<Map<dynamic, dynamic>>(): const _MapEncoder(),
    const TypeMatcher<Symbol>(): const _SymbolEncoder(),
    const TypeMatcher<DateTime>(): _DateTimeCodec.kEncoder,
    const TypeMatcher<Uri>(): _UriCodec.kEncoder,
    const TypeMatcher<path.Context>(): _PathContextCodec.kEncoder,
    const TypeMatcher<ResultReference<dynamic>>(): const _ResultEncoder(),
    const TypeMatcher<LiveInvocationEvent<dynamic>>(): const _EventEncoder(),
    const TypeMatcher<ReplayAware>(): const _ReplayAwareEncoder(),
    const TypeMatcher<Encoding>(): _EncodingCodec.kEncoder,
    const TypeMatcher<FileMode>(): const _FileModeEncoder(),
    const TypeMatcher<FileStat>(): _FileStatCodec.kEncoder,
    const TypeMatcher<FileSystemEntityType>(): _EntityTypeCodec.kEncoder,
    const TypeMatcher<FileSystemEvent>(): _FileSystemEventCodec.kEncoder,
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

class _PassthroughConverter extends Converter<dynamic, dynamic> {
  const _PassthroughConverter();

  @override
  dynamic convert(dynamic input) => input;
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

class _DateTimeCodec extends Codec<DateTime, int> {
  const _DateTimeCodec();

  static int _encode(DateTime input) => input?.millisecondsSinceEpoch;

  static DateTime _decode(int input) {
    return input == null
        ? null
        : new DateTime.fromMillisecondsSinceEpoch(input);
  }

  static const Converter<DateTime, int> kEncoder =
      const _ForwardingConverter<DateTime, int>(_encode);

  static const Converter<int, DateTime> kDecoder =
      const _ForwardingConverter<int, DateTime>(_decode);

  @override
  Converter<DateTime, int> get encoder => kEncoder;

  @override
  Converter<int, DateTime> get decoder => kDecoder;
}

class _UriCodec extends Codec<Uri, String> {
  const _UriCodec();

  static String _encode(Uri input) => input.toString();

  static Uri _decode(String input) => Uri.parse(input);

  static const Converter<Uri, String> kEncoder =
      const _ForwardingConverter<Uri, String>(_encode);

  static const Converter<String, Uri> kDecoder =
      const _ForwardingConverter<String, Uri>(_decode);

  @override
  Converter<Uri, String> get encoder => kEncoder;

  @override
  Converter<String, Uri> get decoder => kDecoder;
}

class _PathContextCodec extends Codec<path.Context, Map<String, String>> {
  const _PathContextCodec();

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

  static const Converter<path.Context, Map<String, String>> kEncoder =
      const _ForwardingConverter<path.Context, Map<String, String>>(_encode);

  static const Converter<Map<String, String>, path.Context> kDecoder =
      const _ForwardingConverter<Map<String, String>, path.Context>(_decode);

  @override
  Converter<path.Context, Map<String, String>> get encoder => kEncoder;

  @override
  Converter<Map<String, String>, path.Context> get decoder => kDecoder;
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

class _EncodingCodec extends Codec<Encoding, String> {
  const _EncodingCodec();

  static String _encode(Encoding input) => input.name;

  static Encoding _decode(String input) {
    if (input == 'system') {
      return SYSTEM_ENCODING;
    } else if (input != null) {
      return Encoding.getByName(input);
    }
    return null;
  }

  static const Converter<Encoding, String> kEncoder =
      const _ForwardingConverter<Encoding, String>(_encode);

  static const Converter<String, Encoding> kDecoder =
      const _ForwardingConverter<String, Encoding>(_decode);

  @override
  Converter<Encoding, String> get encoder => kEncoder;

  @override
  Converter<String, Encoding> get decoder => kDecoder;
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

class _FileStatCodec extends Codec<FileStat, Map<String, Object>> {
  const _FileStatCodec();

  static Map<String, Object> _encode(FileStat input) {
    return <String, dynamic>{
      'changed': const _DateTimeCodec().encode(input.changed),
      'modified': const _DateTimeCodec().encode(input.modified),
      'accessed': const _DateTimeCodec().encode(input.accessed),
      'type': const _EntityTypeCodec().encode(input.type),
      'mode': input.mode,
      'size': input.size,
      'modeString': input.modeString(),
    };
  }

  static FileStat _decode(Map<String, Object> input) =>
      new ReplayFileStat(input);

  static const Converter<FileStat, Map<String, Object>> kEncoder =
      const _ForwardingConverter<FileStat, Map<String, Object>>(_encode);

  static const Converter<Map<String, Object>, FileStat> kDecoder =
      const _ForwardingConverter<Map<String, Object>, FileStat>(_decode);

  @override
  Converter<FileStat, Map<String, Object>> get encoder => kEncoder;

  @override
  Converter<Map<String, Object>, FileStat> get decoder => kDecoder;
}

class _EntityTypeCodec extends Codec<FileSystemEntityType, String> {
  const _EntityTypeCodec();

  static String _encode(FileSystemEntityType input) => input.toString();

  static FileSystemEntityType _decode(String input) {
    return const <String, FileSystemEntityType>{
      'FILE': FileSystemEntityType.FILE,
      'DIRECTORY': FileSystemEntityType.DIRECTORY,
      'LINK': FileSystemEntityType.LINK,
      'NOT_FOUND': FileSystemEntityType.NOT_FOUND,
    }[input];
  }

  static const Converter<FileSystemEntityType, String> kEncoder =
      const _ForwardingConverter<FileSystemEntityType, String>(_encode);

  static const Converter<String, FileSystemEntityType> kDecoder =
      const _ForwardingConverter<String, FileSystemEntityType>(_decode);

  @override
  Converter<FileSystemEntityType, String> get encoder => kEncoder;

  @override
  Converter<String, FileSystemEntityType> get decoder => kDecoder;
}

class _FileSystemEventCodec
    extends Codec<FileSystemEvent, Map<String, Object>> {
  const _FileSystemEventCodec();

  static Map<String, Object> _encode(FileSystemEvent input) {
    return <String, Object>{
      'type': input.type,
      'path': input.path,
      'isDirectory': input.isDirectory,
    };
  }

  static FileSystemEvent _decode(Map<String, Object> input) =>
      new _FileSystemEvent(input);

  static const Converter<FileSystemEvent, Map<String, Object>> kEncoder =
      const _ForwardingConverter<FileSystemEvent, Map<String, Object>>(_encode);

  static const Converter<Map<String, Object>, FileSystemEvent> kDecoder =
      const _ForwardingConverter<Map<String, Object>, FileSystemEvent>(_decode);

  @override
  Converter<FileSystemEvent, Map<String, Object>> get encoder => kEncoder;

  @override
  Converter<Map<String, Object>, FileSystemEvent> get decoder => kDecoder;
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

class _FutureReviver<T> extends Converter<T, Future<T>> {
  const _FutureReviver();

  @override
  Future<T> convert(T input) async => input;
}

class _DirectoryReviver extends Converter<String, Directory> {
  final ReplayFileSystemImpl fileSystem;
  const _DirectoryReviver(this.fileSystem);

  @override
  Directory convert(String input) => new ReplayDirectory(fileSystem, input);
}

class _FileReviver extends Converter<String, File> {
  final ReplayFileSystemImpl fileSystem;
  const _FileReviver(this.fileSystem);

  @override
  File convert(String input) => new ReplayFile(fileSystem, input);
}

class _LinkReviver extends Converter<String, Link> {
  final ReplayFileSystemImpl fileSystem;
  const _LinkReviver(this.fileSystem);

  @override
  Link convert(String input) => new ReplayLink(fileSystem, input);
}

class _FileSystemEntityReviver extends Converter<String, FileSystemEntity> {
  final ReplayFileSystemImpl fileSystem;
  const _FileSystemEntityReviver(this.fileSystem);

  @override
  FileSystemEntity convert(String input) {
    if (input.contains('Directory')) {
      return new ReplayDirectory(fileSystem, input);
    } else if (input.contains('File')) {
      return new ReplayFile(fileSystem, input);
    } else {
      return new ReplayLink(fileSystem, input);
    }
  }
}

class _RandomAccessFileReviver extends Converter<String, RandomAccessFile> {
  final ReplayFileSystemImpl fileSystem;
  const _RandomAccessFileReviver(this.fileSystem);

  @override
  RandomAccessFile convert(String input) =>
      new ReplayRandomAccessFile(fileSystem, input);
}

class _IOSinkReviver extends Converter<String, IOSink> {
  final ReplayFileSystemImpl fileSystem;
  const _IOSinkReviver(this.fileSystem);

  @override
  IOSink convert(String input) => new ReplayIOSink(fileSystem, input);
}

class _ListReviver extends Converter<Iterable<dynamic>, List<dynamic>> {
  final Converter<dynamic, dynamic> elementReviver;

  const _ListReviver(this.elementReviver);

  @override
  List<dynamic> convert(Iterable<dynamic> input) =>
      input.map(elementReviver.convert).toList();
}

class _StreamReviver extends Converter<List<dynamic>, Stream<dynamic>> {
  const _StreamReviver();

  @override
  Stream<dynamic> convert(List<dynamic> input) {
    return new Stream<dynamic>.fromIterable(input);
  }
}

class _BlobReviver extends Converter<String, List<int>> {
  final ReplayFileSystemImpl fileSystem;
  const _BlobReviver(this.fileSystem);

  @override
  List<int> convert(String input) {
    assert(input.startsWith('!'));
    String basename = input.substring(1);
    String dirname = fileSystem.recording.path;
    String path = fileSystem.recording.fileSystem.path.join(dirname, basename);
    File file = fileSystem.recording.fileSystem.file(path);
    return file.readAsBytesSync();
  }
}
