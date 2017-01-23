// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('MemoryFileSystem', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = new MemoryFileSystem();
    });

    runCommonTests(
      () => fs,
      skip: <String>[
        'File > open', // Not yet implemented
      ],
    );

    group('toString', () {
      test('File', () {
        expect(fs.file('/foo').toString(), "MemoryFile: '/foo'");
      });

      test('Directory', () {
        expect(fs.directory('/foo').toString(), "MemoryDirectory: '/foo'");
      });

      test('Link', () {
        expect(fs.link('/foo').toString(), "MemoryLink: '/foo'");
      });
    });
  });
}
