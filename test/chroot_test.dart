@TestOn('vm')
import 'package:file/chroot.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('ChrootFileSystem', () {
    runCommonTests(() {
      MemoryFileSystem fs = new MemoryFileSystem();
      fs.directory('/tmp').createSync();
      return new ChrootFileSystem(fs, '/tmp');
    });
  });
}
