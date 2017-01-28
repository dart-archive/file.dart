// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file.src.backends.record_replay;

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'record_replay/common.dart';
part 'record_replay/encoding.dart';
part 'record_replay/events.dart';
part 'record_replay/recording.dart';
part 'record_replay/recording_directory.dart';
part 'record_replay/recording_file.dart';
part 'record_replay/recording_file_system.dart';
part 'record_replay/recording_file_system_entity.dart';
part 'record_replay/recording_io_sink.dart';
part 'record_replay/recording_link.dart';
part 'record_replay/recording_proxy_mixin.dart';
part 'record_replay/recording_random_access_file.dart';
