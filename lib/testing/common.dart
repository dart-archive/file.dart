/// Common tests that can be re-used across backends.
library file.testing.common;

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/utils.dart';
import 'package:test/test.dart';

/// Creates a directory structure in [system] in [root]:
///     /users
///       /jack
///         profile.jpg
///         README
///       /jill
///         profile.jpg
///         README
///
/// All files will be empty.
Future<Directory> createUsersDirectory(Directory root) {
  return insertFiles(root, const <String, Object> {
    'users': const {
      'jack': const {
        'profile.jpg': const [],
        'README': 'Jack will fill this in'
      },
      'jill': const {
        'profile.jpg': const [],
        'README': 'Jill will fill this in'
      }
    }
  }, true);
}

//
void runCommonTests(FileSystem getFileSystem(), [String getRoot()]) {
  group('[Common]', () {
    FileSystem system;
    String root;

    setUp(() {
      system = getFileSystem();
      root = (getRoot ?? () => '/')();
    });

    group('[Directory]', () {
      test('should not exist by default', () async {
        var dir = system.directory('$root/users');
        expect(await dir.exists(), isFalse);
      });

      test('should exist after being created', () async {
        var dir = system.directory('$root/users');
        expect(await dir.create(), const isInstanceOf<Directory>());
        expect(await dir.exists(), isTrue);
      });

      group('should list files', () {
        test('and by default, be empty', () async {
          var dir = system.directory('$root/users');
          await dir.create();
          expect(await dir.list().toList(), isEmpty);
        });

        test('non-recursively', () async {
          var dir = system.directory(root);
          await createUsersDirectory(dir);
          dir = system.directory('$root/users/jack');
          expect(
            (await dir.list().toList())
                .map((e) => e.path)
                .toList()
                ..sort(), [
            '$root/users/jack/README',
            '$root/users/jack/profile.jpg'
          ]);
        });

        test('recursively', () async {
          var dir = system.directory(root);
          await createUsersDirectory(dir);
          dir = system.directory('$root/users');

          var files = await (dir
              .list(recursive: true)
              .map((e) => e.path)
              .toList())
              ..sort();

          expect(files, [
            '$root/users/jack',
            '$root/users/jack/README',
            '$root/users/jack/profile.jpg',
            '$root/users/jill',
            '$root/users/jill/README',
            '$root/users/jill/profile.jpg',
          ]);
        });
      });
    });

    group('[File]', () {
      test('should not exist by default', () async {
        var file = system.file('$root/README');
        expect(await file.exists(), isFalse);
      });

      test('should exist after being created', () async {
        var file = system.file('$root/README');
        expect(await file.create(), const isInstanceOf<File>());
        expect(await file.exists(), isTrue);
      });
    });

    test('should be able to write and read to the file system', () async {
      var dir = system.directory(root);
      await createUsersDirectory(dir);

      dir = system.directory('$root/users');
      expect(await dir.exists(), isTrue);

      dir = system.directory('$root/users/jack');
      expect(await dir.exists(), isTrue);

      var file = system.file('$root/users/jack/README');
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'Jack will fill this in');
    });
  });
}
