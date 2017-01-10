// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../test/chroot_test.dart' as chroot_test;
import '../test/local_test.dart' as local_test;
import '../test/memory_test.dart' as memory_test;

void main() {
  group('(chroot_test.dart)', chroot_test.main);
  group('(local_test.dart)', local_test.main);
  group('(memory_test.dart)', memory_test.main);
}
