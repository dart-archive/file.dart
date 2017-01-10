// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('MemoryFileSystem', () {
    runCommonTests(
      () => new MemoryFileSystem(),
      skip: <String>[
        'File > open', // Not yet implemented
      ],
    );
  });
}
