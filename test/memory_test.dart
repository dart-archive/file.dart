library file.test.memory_test;

import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryFileSystem', () {
    MemoryFileSystem fs;

    setUp(() async {
      fs = new MemoryFileSystem();
    });
  });
}
