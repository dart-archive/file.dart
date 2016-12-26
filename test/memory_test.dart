@TestOn('vm')
library file.test.local_test;

import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('MemoryFileSystem', () {
    runCommonTests(
      () => new MemoryFileSystem(),
      skip: <String>[
        'File > open', // Not yet implemented

        // TODO: fix bugs causing these tests to fail, and re-enable tests
        'Link > delete > throwsIfPathReferencesFileAndRecursiveFalse',
        'Link > delete > throwsIfPathReferencesDirectoryAndRecursiveFalse',
        'Link > delete > unlinksIfTargetIsFileAndRecursiveFalse',
        'Link > delete > unlinksIfTargetIsDirectoryAndRecursiveFalse',
        'Link > delete > unlinksIfTargetIsSymlinkLoop',
        'Link > create > throwsIfAlreadyExistsAsFile',
        'Link > create > throwsIfAlreadyExistsAsDirectory',
        'Link > create > throwsIfAlreadyExistsWithSameTarget',
        'Link > create > throwsIfAlreadyExistsWithDifferentTarget',
        'Link > update > throwsIfPathReferencesFile',
        'Link > update > throwsIfPathReferencesDirectory',
        'Link > target > throwsIfPathReferencesFile',
        'Link > target > throwsIfPathReferencesDirectory',
        'Link > rename > throwsIfPathReferencesFile',
        'Link > rename > throwsIfPathReferencesDirectory',
        'Link > rename > succeedsIfTargetIsFile',
        'Link > rename > succeedsIfTargetIsDirectory',
        'Link > rename > succeedsIfTargetIsSymlinkLoop',
      ],
    );
  });
}
