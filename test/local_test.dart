@TestOn('vm')
library file.test.local_test;

import 'dart:io' as io;

import 'package:file/chroot.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('LocalFileSystem', () {
    LocalFileSystem fs;
    io.Directory tmp;

    setUp(() {
      fs = new LocalFileSystem();
      tmp = io.Directory.systemTemp.createTempSync('file_test_');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    runCommonTests(() {
      return new ChrootFileSystem(fs, tmp.path);
    });
  });
}
