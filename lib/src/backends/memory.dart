// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file.src.backends.memory;

import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:file/file.dart';
import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;
import 'package:path/path.dart' as p;

part 'memory/memory_directory.dart';
part 'memory/memory_file.dart';
part 'memory/memory_file_stat.dart';
part 'memory/memory_file_system.dart';
part 'memory/memory_file_system_entity.dart';
part 'memory/memory_link.dart';
part 'memory/node.dart';
part 'memory/utils.dart';
