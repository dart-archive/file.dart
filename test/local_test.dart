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

    runCommonTests(
      () => fs,
      root: () => tmp.path,
      skip: <String>[
        // https://github.com/dart-lang/sdk/issues/28170
        'File > create > throwsIfAlreadyExistsAsDirectory',
        'File > create > throwsIfAlreadyExistsAsLinkToDirectory',

        // https://github.com/dart-lang/sdk/issues/28171
        'File > rename > throwsIfTargetExistsAsLinkToDirectory',

        // https://github.com/dart-lang/sdk/issues/28172
        'File > length > throwsIfExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28173
        'File > lastModified > throwsIfExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28174
        '.+ > RandomAccessFile > writeFromWithStart',
        '.+ > RandomAccessFile > writeFromWithStartAndEnd',
      ],
    );
  });
}
