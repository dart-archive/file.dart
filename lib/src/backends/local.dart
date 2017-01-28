// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file.src.backends.local;

import 'dart:async';

import 'package:file/src/forwarding.dart';
import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../io/shim.dart' as shim;

part 'local/local_directory.dart';
part 'local/local_file.dart';
part 'local/local_file_system.dart';
part 'local/local_file_system_entity.dart';
part 'local/local_link.dart';
