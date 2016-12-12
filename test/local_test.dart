@TestOn('vm')
library file.test.local_test;

import 'package:file/local.dart';
import 'package:test/test.dart';

void main() {
  group('LocalFileSystem', () {
    LocalFileSystem fs;

    setUp(() async {
      fs = const LocalFileSystem();
    });
  });
}
