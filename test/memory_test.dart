import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('MemoryFileSystem', () {
    runCommonTests(
      () => new MemoryFileSystem(),
      skip: <String>[
        'File > open', // Not yet implemented
      ],
    );
  });
}
