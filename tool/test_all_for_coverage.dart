library file.tool.test_all_for_coverage;

import 'package:test/test.dart';

import '../test/memory_test.dart' as memory_test;

void main() {
  group('(memory_test.dart)', memory_test.main);
}
