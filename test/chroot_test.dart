@TestOn('vm')
import 'package:file/chroot.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('ChrootFileSystem', () {
    runCommonTests(
      () {
        MemoryFileSystem fs = new MemoryFileSystem();
        fs.directory('/tmp').createSync();
        return new ChrootFileSystem(fs, '/tmp');
      },
      skip: <String>[
        'File > open', // Not yet implemented in MemoryFileSystem

        // TODO: fix bugs causing these tests to fail, and re-enable tests
        'Link > create > succeedsIfLinkDoesntExistViaTraversalAndRecursiveTrue',
        'Link > update > succeedsIfNewTargetSameAsOldTarget',
        'Link > update > succeedsIfNewTargetDifferentFromOldTarget',
      ],
    );
  });
}
