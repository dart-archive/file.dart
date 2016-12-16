@TestOn('vm')
library file.test.local_test;

import 'dart:io' as io;

import 'package:file/local.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('LocalFileSystem', () {
    LocalFileSystem fs;
    io.Directory tmp;
    String cwd;

    setUp(() {
      fs = new LocalFileSystem();
      tmp = io.Directory.systemTemp.createTempSync('file_test_');
      tmp = new io.Directory(tmp.resolveSymbolicLinksSync());
      cwd = io.Directory.current.path;
      io.Directory.current = tmp;
    });

    tearDown(() {
      io.Directory.current = cwd;
      tmp.deleteSync(recursive: true);
    });

    runCommonTests(() => fs, root: () => tmp.path);
  });
}
