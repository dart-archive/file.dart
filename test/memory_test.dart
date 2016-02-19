library file.test.memory_test;

import 'package:file/file.dart';
import 'package:file/sync.dart';
import 'package:file/testing/common.dart' as common;
import 'package:test/test.dart';

void main() {
  group('MemoryFileSystem', () {
    common.runCommonTests(() => new MemoryFileSystem());

    test('takes a backing storage', () async {
      var syncFs = new SyncMemoryFileSystem();
      var fs = new MemoryFileSystem(backedBy: syncFs.storage);
      syncFs.file('/hello').writeAsString('world');
      expect(await fs.file('/hello').readAsString(), 'world');
    });
  });

  group('SyncMemoryFileSystem', () {
    test('takes a backing storage', () async {
      var fs = new MemoryFileSystem();
      var syncFs = new SyncMemoryFileSystem(backedBy: fs.storage);
      syncFs.file('/hello').writeAsString('world');
      expect(await fs.file('/hello').readAsString(), 'world');
    });
  });
}
