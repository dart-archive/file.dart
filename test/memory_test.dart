library file.test.memory_test;

import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryFileSystem', () {
    MemoryFileSystem fs;

    setUp(() async {
      fs = new MemoryFileSystem();
    });

    group('MemoryFileSystem', () {
      group('currentDirectory', () {
        test('default', () {
          expect(fs.currentDirectory.path, '/');
        });

        test('setToNotFoundThrows', () {
          expectFileSystemException('No such file or directory', () {
            fs.currentDirectory = '/foo';
          });
        });

        test('setString', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = '/foo';
          expect(fs.currentDirectory.path, '/foo');
        });

        test('setDirectory', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = new io.Directory('/foo');
          expect(fs.currentDirectory.path, '/foo');
        });

        test('setOtherTypeThrows', () {
          expect(() {
            fs.currentDirectory = 123;
          }, throwsArgumentError);
        });

        test('setRelative', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, '/foo');
          fs.directory('/foo/bar').createSync();
          fs.currentDirectory = 'bar';
          expect(fs.currentDirectory.path, '/foo/bar');
        });

        test('setParent', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, '/foo');
          fs.currentDirectory = '..';
          expect(fs.currentDirectory.path, '/');
        });

        test('setParentPastRootStaysAtRoot', () {
          fs.currentDirectory = '../../..';
          expect(fs.currentDirectory.path, '/');
        });

        test('setWithTrailingSlashGetsRemoved', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = '/foo/';
          expect(fs.currentDirectory.path, '/foo');
        });

        test('setToFilePathThrows', () {
          fs.file('/foo').createSync();
          expectFileSystemException('Not a directory', () {
            fs.currentDirectory = '/foo';
          });
        });

        test('setResolvesSymlinks', () {
          fs.link('/foo/bar/baz').createSync('/qux', recursive: true);
          fs.directory('/qux').createSync();
          fs.directory('/quux').createSync();
          fs.currentDirectory = '/foo/bar/baz/../quux/';
          expect(fs.currentDirectory.path, '/quux');
        });
      });

      group('stat', () {
        test('notFound', () {
          io.FileStat stat = fs.statSync('/foo');
          expect(stat.type, io.FileSystemEntityType.NOT_FOUND);
        });

        test('parentNotFound', () {
          io.FileStat stat = fs.statSync('/foo/bar');
          expect(stat.type, io.FileSystemEntityType.NOT_FOUND);
        });

        test('directory', () {
          fs.directory('/foo').createSync();
          var stat = fs.statSync('/foo');
          expect(stat.type, io.FileSystemEntityType.DIRECTORY);
        });

        test('file', () {
          fs.file('/foo').createSync();
          var stat = fs.statSync('/foo');
          expect(stat.type, io.FileSystemEntityType.FILE);
        });

        test('linkReturnsTargetStat', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          var stat = fs.statSync('/bar');
          expect(stat.type, io.FileSystemEntityType.FILE);
        });

        test('linkWithCircularReferenceReturnsNotFound', () {
          fs.link('/foo').createSync('/bar');
          fs.link('/bar').createSync('/baz');
          fs.link('/baz').createSync('/foo');
          var stat = fs.statSync('/foo');
          expect(stat.type, io.FileSystemEntityType.NOT_FOUND);
        });
      });

      group('identical', () {
        test('samePathExists', () {
          fs.file('/foo').createSync();
          expect(fs.identicalSync('/foo', '/foo'), true);
        });

        test('differentPathsBothExist', () {
          fs.file('/foo').createSync();
          fs.file('/bar').createSync();
          expect(fs.identicalSync('/foo', '/bar'), false);
        });

        test('differentPathsReferringToSameEntityViaTraversal', () {
          fs.file('/foo/file').createSync(recursive: true);
          fs.link('/bar').createSync('/foo');
          expect(fs.identicalSync('/foo/file', '/bar/file'), true);
        });

        test('differentPathsReferringToSameEntityAtTail', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          expect(fs.identicalSync('/foo', '/bar'), true);
        });

        test('bothNotFound', () {
          expect(fs.identicalSync('/foo', '/bar'), false);
        });

        test('oneNotFound', () {
          fs.file('/foo').createSync();
          expect(fs.identicalSync('/foo', '/bar'), false);
        });
      });

      group('type', () {
        test('file', () {
          fs.file('/foo').createSync();
          var type = fs.typeSync('/foo');
          expect(type, io.FileSystemEntityType.FILE);
        });

        test('directory', () {
          fs.directory('/foo').createSync();
          var type = fs.typeSync('/foo');
          expect(type, io.FileSystemEntityType.DIRECTORY);
        });

        test('linkFollowed', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          var type = fs.typeSync('/bar');
          expect(type, io.FileSystemEntityType.FILE);
        });

        test('linkNotFollowed', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          var type = fs.typeSync('/bar', followLinks: false);
          expect(type, io.FileSystemEntityType.LINK);
        });

        test('notFoundAtTail', () {
          var type = fs.typeSync('/foo');
          expect(type, io.FileSystemEntityType.NOT_FOUND);
        });

        test('notFoundViaTraversal', () {
          var type = fs.typeSync('/foo/bar/baz');
          expect(type, io.FileSystemEntityType.NOT_FOUND);
        });
      });
    });
  });
}

Matcher isFileSystemException([String msg]) => new _FileSystemException(msg);
Matcher throwsFileSystemException([String msg]) =>
    new Throws(isFileSystemException(msg));

void expectFileSystemException(String msg, void callback()) {
  expect(callback, throwsFileSystemException(msg));
}

class _FileSystemException extends Matcher {
  final String msg;
  const _FileSystemException(this.msg);

  Description describe(Description description) =>
      description.add('FileSystemException with msg "$msg"');

  bool matches(item, Map matchState) {
    if (item is io.FileSystemException) {
      return (msg == null || item.message.contains(msg));
    }
    return false;
  }
}
