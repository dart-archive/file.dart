library file.tool.test_all_for_coverage;

import 'package:test/test.dart';

import '../test/in_memory_test.dart' as in_memory_test;

void main() {
  group('(in_memory_test.dart)', in_memory_test.main);
}
