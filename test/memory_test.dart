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

        // TODO: Fix bugs causing these tests to fail, and re-enable.
        'File > openRead > providesSingleSubscriptionStream',
      ],
    );
  });
}
