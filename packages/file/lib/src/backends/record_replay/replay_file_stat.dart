// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';

import 'codecs.dart';

/// [FileStat] implementation that derives its properties from a recorded
/// invocation event.
class ReplayFileStat implements FileStat {
  /// Creates a new `ReplayFileStat` that will derive its properties from the
  /// specified [data].
  ReplayFileStat(Map<String, dynamic> data) : _data = data;

  final Map<String, dynamic> _data;

  @override
  DateTime get changed =>
      DateTimeCodec.deserialize.convert(_data['changed'] as int);

  @override
  DateTime get modified =>
      DateTimeCodec.deserialize.convert(_data['modified'] as int);

  @override
  DateTime get accessed =>
      DateTimeCodec.deserialize.convert(_data['accessed'] as int);

  @override
  FileSystemEntityType get type =>
      EntityTypeCodec.deserialize.convert(_data['type'] as String);

  @override
  int get mode => _data['mode'] as int;

  @override
  int get size => _data['size'] as int;

  @override
  String modeString() => _data['modeString'] as String;
}
