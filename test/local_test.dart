@TestOn('vm')
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
        'File > rename > throwsIfDestinationExistsAsLinkToDirectory',

        // https://github.com/dart-lang/sdk/issues/28172
        'File > length > throwsIfExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28173
        'File > lastModified > throwsIfExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28174
        '.+ > RandomAccessFile > writeFromWithStart',
        '.+ > RandomAccessFile > writeFromWithStartAndEnd',

        // https://github.com/dart-lang/sdk/issues/28201
        'Link > delete > throwsIfLinkDoesntExistAtTail',
        'Link > delete > throwsIfLinkDoesntExistViaTraversal',
        'Link > update > throwsIfLinkDoesntExistAtTail',
        'Link > update > throwsIfLinkDoesntExistViaTraversal',

        // https://github.com/dart-lang/sdk/issues/28202
        'Link > rename > throwsIfSourceDoesntExistAtTail',
        'Link > rename > throwsIfSourceDoesntExistViaTraversal',

        // https://github.com/dart-lang/sdk/issues/28275
        'Link > rename > throwsIfDestinationExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28277
        'Link > rename > throwsIfDestinationExistsAsFile',
      ],
    );
  });
}
