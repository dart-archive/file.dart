// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file/src/interface/file.dart';
import 'package:test/test.dart';

void main() {
  test('Read operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      contexts.add(context);
      operations.add(operation);
    });
    final File file = fs.file('test')..createSync();

    await file.readAsBytes();
    file.readAsBytesSync();
    await file.readAsString();
    file.readAsStringSync();

    expect(contexts, <String>['test', 'test', 'test', 'test']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.read,
      FileSystemOp.read,
      FileSystemOp.read,
      FileSystemOp.read
    ]);
  });

  test('Write operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      contexts.add(context);
      operations.add(operation);
    });
    final File file = fs.file('test')..createSync();

    await file.writeAsBytes(<int>[]);
    file.writeAsBytesSync(<int>[]);
    await file.writeAsString('');
    file.writeAsStringSync('');

    expect(contexts, <String>['test', 'test', 'test', 'test']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.write,
      FileSystemOp.write,
      FileSystemOp.write,
      FileSystemOp.write
    ]);
  });

  test('Failed UTF8 decoding in MemoryFileSystem throws a FileSystemException',
      () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo')
      ..writeAsBytesSync(<int>[0xFFFE]); // Invalid UTF8

    expect(file.readAsStringSync, throwsA(isA<FileSystemException>()));
  });
}
