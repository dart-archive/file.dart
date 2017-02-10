// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';

import 'codecs.dart';

/// [FileStat] implementation that derives its properties from a recorded
/// invocation event.
class ReplayFileStat implements FileStat {
  final Map<String, dynamic> _data;

  /// Creates a new `ReplayFileStat` that will derive its properties from the
  /// specified [data].
  ReplayFileStat(Map<String, dynamic> data) : _data = data;

  @override
  DateTime get changed => kDateTimeReviver.convert(_data['changed']);

  @override
  DateTime get modified => kDateTimeReviver.convert(_data['modified']);

  @override
  DateTime get accessed => kDateTimeReviver.convert(_data['accessed']);

  @override
  FileSystemEntityType get type => kEntityTypeReviver.convert(_data['type']);

  @override
  int get mode => _data['mode'];

  @override
  int get size => _data['size'];

  @override
  String modeString() => _data['modeString'];
}
