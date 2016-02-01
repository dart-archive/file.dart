@TestOn('vm')
library file.test.local_test;

import 'dart:io' as io;

import 'package:file/src/backends/local.dart';
import 'package:file/testing/common.dart' as common;
import 'package:test/test.dart';

void main() {
  group('LocalFileSystem', () {
    LocalFileSystem system;
    io.Directory temp;

    setUp(() async {
      system = const LocalFileSystem();
      temp = await io.Directory.systemTemp.createTemp();
    });

    common.runCommonTests(() => system, () => temp.path);

    tearDown(() async {
      await temp.delete(recursive: true);
    });
  });
}
