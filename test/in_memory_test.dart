library file.test.in_memory_test;

import 'package:file/src/backends/in_memory.dart';
import 'package:file/src/interface.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryFileSystem', () {
    InMemoryFileSystem system;

    group('implementation', () {
      setUp(() => system = new InMemoryFileSystem());

      test('should return a new File reference', () async {
        var file = system.file('/foo/bar');
        expect(file.path, '/foo/bar');
        expect(await file.exists(), isFalse);
      });

      test('should return a directory for each parent', () async {
        var file = system.file('/foo/bar/baz');
        expect(file.parent.path, '/foo/bar');
        expect(file.parent.parent.path, '/foo');
        expect(file.parent.parent.parent.path, '/');
        expect(file.parent.parent.parent.parent, isNull);
      });

      test('should create a file in the root', () async {
        var file = system.file('/README');
        expect(await file.exists(), isFalse);
        expect(system.toMap(), {});
        expect(await file.create(), const isInstanceOf<File>());
        expect(await file.exists(), isTrue);
        expect(system.toMap(), {'README': []});
      });

      test('should create a file deeper in the tree (success case)', () async {
        var file = system.file('/users/matan/README');
        expect(await file.create(recursive: true), const isInstanceOf<File>());
        expect(await file.exists(), isTrue);
        expect(system.toMap(), {
          'users': {
            'matan': {
              'README': []
            }
          }
        });
      });

      test('should create a file deeper in the tree (failure case)', () async {
        var file = system.file('/users/matan/README');
        file.create().catchError(expectAsync((e) {
          expect(e, const isInstanceOf<FileSystemEntityException>());
        }));
        expect(system.toMap(), {});
      });
    });

    group('from an existing Map', () {
      setUp(() {
        system = new InMemoryFileSystem.fromMap({
          'foo': {
            'bar': {
              'README': 'Hello World',
              'baz.dat': [1, 2, 3, 4],
              'baz': {}
            }
          }
        });
      });

      test('should create the appropriate structures', () async {
        expect(await system.type('/'), FileSystemEntityType.DIRECTORY);
        expect(await system.type('/foo'), FileSystemEntityType.DIRECTORY);
        expect(await system.type('/foo/bar'), FileSystemEntityType.DIRECTORY);
      });

      test('should succeed deleting a file that exists', () async {
        var file = system.file('/foo/bar/README');
        expect(await file.exists(), isTrue);
        expect(await file.delete(), const isInstanceOf<File>());
        expect(await file.exists(), isFalse);
      });

      test('should fail in deleting a file that does not exist', () async {
        var file = system.file('/foo/baz/README');
        expect(await file.exists(), isFalse);
        file.delete().catchError(expectAsync((e) {
          expect(e, const isInstanceOf<FileSystemEntityException>());
        }));
      });

      test('should succeed in deleting a directory that exists', () async {
        var directory = system.directory('/foo/bar/baz');
        expect(await directory.exists(), isTrue);
        expect(await directory.delete(), const isInstanceOf<Directory>());
        expect(await directory.exists(), isFalse);
      });

      test('should succeed in deleting a directory recursively', () async {
        var directory = system.directory('/foo/bar');
        expect(await directory.exists(), isTrue);
        expect(
            await directory.delete(recursive: true),
            const isInstanceOf<Directory>());
        expect(await directory.exists(), isFalse);
      });

      test('should fail in deleting a directory non-recursively', () async {
        var directory = system.directory('/foo/bar');
        expect(await directory.exists(), isTrue);
        directory.delete().catchError(expectAsync((e) {
          expect(e, const isInstanceOf<FileSystemEntityException>());
        }));
      });

      test('should be able to copy a file', () async {
        var file = system.file('/foo/bar/README');
        file = await file.copy('/foo/bar/README.md');
        expect(file.path, '/foo/bar/README.md');
        expect(await file.exists(), isTrue);
      });

      test('should be able to copy a directory', () async {
        var dir = system.directory('/foo/bar');
        dir = await dir.copy('/foo/bar2');
        expect(dir.path, '/foo/bar2');
        expect(await dir.exists(), isTrue);
      });

      test('should fail copying when the path does not exist', () async {
        system
            .directory('/foo/bar')
            .copy('/foo/bar/baz')
            .catchError(expectAsync((e) {
          expect(e, const isInstanceOf<FileSystemEntityException>());
        }));
      });

      test('should be able to move a file', () async {
        var file = system.file('/foo/bar/README');
        file = await file.rename('/foo/bar/README.md');
        expect(file.path, '/foo/bar/README.md');
        expect(await file.exists(), isTrue);
        expect(await system.file('/foo/bar/README').exists(), isFalse);
      });

      test('should be able to move a directory', () async {
        var dir = system.directory('/foo/bar');
        dir = await dir.rename('/foo/bar2');
        expect(dir.path, '/foo/bar2');
        expect(await dir.exists(), isTrue);
        expect(await system.directory('/foo/bar').exists(), isFalse);
      });

      test('should fail moving when the path does not exist', () async {
        system
            .directory('/foo/bar')
            .rename('/foo/bar/baz')
            .catchError(expectAsync((e) {
          expect(e, const isInstanceOf<FileSystemEntityException>());
        }));
      });

      test('should be able to list files', () async {
        expect(
            (await system.directory('/foo/bar').list().toList())
                .map((FileSystemEntity e) => e.path),
            [
              '/foo/bar/README',
              '/foo/bar/baz.dat',
              '/foo/bar/baz']);
      });

      test('should be able to list files recursively', () async {
        expect(
            (await system.directory('/').list(recursive: true).toList())
                .map((FileSystemEntity e) => e.path),
            [
              '/foo/bar/README',
              '/foo/bar/baz.dat',
            ]
        );
      });
    });
  });
}
