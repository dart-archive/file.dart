library file.test.memory_test;

import 'package:file/src/backends/memory.dart';
import 'package:file/src/interface.dart';
import 'package:file/testing/common.dart' as common;
import 'package:test/test.dart';

void main() {
  group('MemoryFileSystem', () {
    common.runCommonTests(() => new MemoryFileSystem());
  });
}
