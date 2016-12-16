@TestOn("vm")
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:test/test.dart';

void runCommonTests(FileSystem createFileSystem(), {String root()}) {
  var rootfn = root;

  group('common', () {
    FileSystem fs;
    String root;

    /// Returns [path] prefixed by the [root] namespace.
    /// This is only intended for absolute paths.
    String ns(String path) {
      // We purposefully don't use package:path here because some of our tests
      // use non-standard paths that package:path would correct for us
      // inadvertently (thus thwarting the purpose of that test).
      assert(path.startsWith('/'));
      return root == '/' ? path : (path == '/' ? root : '$root$path');
    }

    setUp(() async {
      root = rootfn != null ? rootfn() : '/';
      assert(root.startsWith('/') && (root == '/' || !root.endsWith('/')));
      fs = createFileSystem();
    });

    group('FileSystem', () {
      group('currentDirectory', () {
        test('defaultsToRoot', () {
          expect(fs.currentDirectory.path, root);
        });

        test('throwsIfSetToNonExistentPath', () {
          expectFileSystemException('No such file or directory', () {
            fs.currentDirectory = ns('/foo');
          });
        });

        test('succeedsWhenSetToValidStringPath', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = ns('/foo');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('succeedsWhenSetToValidDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = new io.Directory(ns('/foo'));
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsWhenArgumentIsNotStringOrDirectory', () {
          expect(() {
            fs.currentDirectory = 123;
          }, throwsArgumentError);
        });

        test('succeedsWhenSetToRelativePath', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, ns('/foo'));
          fs.currentDirectory = 'bar';
          expect(fs.currentDirectory.path, ns('/foo/bar'));
        });

        test('succeedsWhenSetToParentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, ns('/foo'));
          fs.currentDirectory = '..';
          expect(fs.currentDirectory.path, ns('/'));
        });

        test('staysAtRootWhenSetToParentOfRoot', () {
          fs.currentDirectory = '../../../../../../../../../..';
          expect(fs.currentDirectory.path, '/');
        });

        test('removesTrailingSlashWhenSet', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = ns('/foo/');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsWhenSetToFilePath', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Not a directory', () {
            fs.currentDirectory = ns('/foo');
          });
        });

        test('resolvesSymlinksWhenEncountered', () {
          fs.link(ns('/foo/bar/baz')).createSync(ns('/qux'), recursive: true);
          fs.directory(ns('/qux')).createSync();
          fs.directory(ns('/quux')).createSync();
          fs.currentDirectory = ns('/foo/bar/baz/../quux/');
          expect(fs.currentDirectory.path, ns('/quux'));
        });
      });

      group('stat', () {
        test('isNotFoundForPathToNonExistentEntityAtTail', () {
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundForPathToNonExistentEntityInTraversal', () {
          FileStat stat = fs.statSync(ns('/foo/bar'));
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });

        test('isDirectoryForDirectory', () {
          fs.directory(ns('/foo')).createSync();
          var stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileForFile', () {
          fs.file(ns('/foo')).createSync();
          var stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isFileForSymlinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          var stat = fs.statSync(ns('/bar'));
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isNotFoundForSymlinkWithCircularReference', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz')).createSync(ns('/foo'));
          var stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });
      });

      group('identical', () {
        test('isTrueForIdenticalPathsToExistentFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.identicalSync(ns('/foo'), ns('/foo')), true);
        });

        test('isFalseForDifferentPathsToDifferentFiles', () {
          fs.file(ns('/foo')).createSync();
          fs.file(ns('/bar')).createSync();
          expect(fs.identicalSync(ns('/foo'), ns('/bar')), false);
        });

        test('isTrueForDifferentPathsToSameFileViaLinkInTraversal', () {
          fs.file(ns('/foo/file')).createSync(recursive: true);
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.identicalSync(ns('/foo/file'), ns('/bar/file')), true);
        });

        test('isFalseForDifferentPathsToSameFileViaLinkAtTail', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.identicalSync(ns('/foo'), ns('/bar')), false);
        });

        test('throwsForDifferentPathsToNonExistentEntities', () {
          expectFileSystemException('No such file or directory', () {
            fs.identicalSync(ns('/foo'), ns('/bar'));
          });
        });

        test('throwsForDifferentPathsToOneFileOneNonExistentEntity', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('No such file or directory', () {
            fs.identicalSync(ns('/foo'), ns('/bar'));
          });
        });
      });

      group('type', () {
        test('isFileForFile', () {
          fs.file(ns('/foo')).createSync();
          var type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.FILE);
        });

        test('isDirectoryForDirectory', () {
          fs.directory(ns('/foo')).createSync();
          var type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileForSymlinkToFileAndFollowLinksTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          var type = fs.typeSync(ns('/bar'));
          expect(type, FileSystemEntityType.FILE);
        });

        test('isLinkForSymlinkToFileAndFollowLinksFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          var type = fs.typeSync(ns('/bar'), followLinks: false);
          expect(type, FileSystemEntityType.LINK);
        });

        test('isNotFoundForNoEntityAtTail', () {
          var type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundForNoDirectoryInTraversal', () {
          var type = fs.typeSync(ns('/foo/bar/baz'));
          expect(type, FileSystemEntityType.NOT_FOUND);
        });
      });
    });

    group('Directory', () {
      test('uri', () {
        expect(
            fs.directory(ns('/foo')).uri.toString(), 'file://${ns('/foo/')}');
        expect(fs.directory('foo').uri.toString(), 'foo/');
      });

      group('exists', () {
        test('falseWhenNotExists', () {
          expect(fs.directory(ns('/foo')).existsSync(), false);
          expect(fs.directory('foo').existsSync(), false);
        });

        test('trueWhenExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')).existsSync(), true);
          expect(fs.directory('foo').existsSync(), true);
        });

        test('falseWhenExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')).existsSync(), false);
          expect(fs.directory('foo').existsSync(), false);
        });

        test('trueWhenExistsAsSymlinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.directory(ns('/bar')).existsSync(), true);
          expect(fs.directory('bar').existsSync(), true);
        });

        test('falseWhenExistsAsSymlinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.directory(ns('/bar')).existsSync(), false);
          expect(fs.directory('bar').existsSync(), false);
        });
      });

      group('create', () {
        test('succeedsWhenAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/foo')).createSync();
        });

        test('failsWhenAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Creation failed', () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('succeedsWhenAlreadyExistsAsSymlinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).createSync();
        });

        test('succeedsWhenTailDoesntExist', () {
          expect(fs.directory(ns('/')).existsSync(), true);
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')).existsSync(), true);
        });

        test('failsWhenAncestorDoesntExistRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo/bar')).createSync();
          });
        });

        test('succeedsWhenAncestorDoesntExistRecursiveTrue', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.directory(ns('/foo')).existsSync(), true);
          expect(fs.directory(ns('/foo/bar')).existsSync(), true);
        });
      });

      group('rename', () {
        test('succeedsWhenDestinationDoesntExist', () {
          var src = fs.directory(ns('/foo'))..createSync();
          var dest = src.renameSync(ns('/bar'));
          expect(dest.path, ns('/bar'));
          expect(dest.existsSync(), true);
        });

        test('succeedsWhenDestinationIsEmptyDirectory', () {
          fs.directory(ns('/bar')).createSync();
          var src = fs.directory(ns('/foo'))..createSync();
          var dest = src.renameSync(ns('/bar'));
          expect(dest.existsSync(), true);
        });

        test('failsWhenDestinationIsFile', () {
          fs.file(ns('/bar')).createSync();
          var src = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException('Not a directory', () {
            src.renameSync(ns('/bar'));
          });
        });

        test('failsWhenDestinationParentFolderDoesntExist', () {
          var src = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            src.renameSync(ns('/bar/baz'));
          });
        });

        test('failsWhenDestinationIsNonEmptyDirectory', () {
          fs.file(ns('/bar/baz')).createSync(recursive: true);
          var src = fs.directory(ns('/foo'))..createSync();
          // The error will be 'Directory not empty' on OS X, but it will be
          // 'File exists' on Linux, so we just ignore it here in the test.
          expectFileSystemException(null, () {
            src.renameSync(ns('/bar'));
          });
        });

        test('failsWhenSourceDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('failsWhenSourceIsFile', () {
          fs.file(ns('/foo')).createSync();
          // The error message is usually 'No such file or directory', but
          // it's occasionally 'Not a directory', 'Directory not empty',
          // 'File exists', or 'Undefined error'.
          // https://github.com/dart-lang/sdk/issues/28147
          expectFileSystemException(null, () {
            fs.directory(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsWhenSourceIsSymlinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).renameSync(ns('/baz'));
          expect(fs.directory(ns('/foo')).existsSync(), true);
          expect(fs.link(ns('/bar')).existsSync(), false);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/baz')).targetSync(), ns('/foo'));
        });

        test('failsWhenDestinationIsSymlinkToEmptyDirectory', () {
          var src = fs.directory(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException('Not a directory', () {
            src.renameSync(ns('/baz'));
          });
        });
      });

      group('delete', () {
        test('succeedsWhenEmptyDirectoryExistsAndRecursiveFalse', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          dir.deleteSync();
          expect(dir.existsSync(), false);
        });

        test('succeedsWhenEmptyDirectoryExistsAndRecursiveTrue', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          dir.deleteSync(recursive: true);
          expect(dir.existsSync(), false);
        });

        test('throwsWhenNonEmptyDirectoryExistsAndRecursiveFalse', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          fs.file(ns('/foo/bar')).createSync();
          expectFileSystemException('Directory not empty', () {
            dir.deleteSync();
          });
        });

        test('succeedsWhenNonEmptyDirectoryExistsAndRecursiveTrue', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          fs.file(ns('/foo/bar')).createSync();
          dir.deleteSync(recursive: true);
          expect(fs.directory(ns('/foo')).existsSync(), false);
          expect(fs.file(ns('/foo/bar')).existsSync(), false);
        });

        test('throwsWhenDirectoryDoesntExistAndRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });

        test('throwsWhenDirectoryDoesntExistAndRecursiveTrue', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).deleteSync(recursive: true);
          });
        });

        test('succeedsWhenPathReferencesFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.directory(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
        });

        test('throwsWhenPathReferencesFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Not a directory', () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });

        test('succeedsWhenPathReferencesLinkToDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsWhenPathReferencesLinkToDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsWhenPathReferencesLinkToFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('failsWhenPathReferencesLinkToFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Not a directory', () {
            fs.directory(ns('/bar')).deleteSync();
          });
        });
      });

      group('resolveSymbolicLinks', () {
        test('succeedsForRootDirectory', () {
          expect(fs.directory(ns('/')).resolveSymbolicLinksSync(), ns('/'));
        });

        test('throwsIfLoopInLinkChain', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz'))..createSync(ns('/foo'));
          expectFileSystemException('Too many levels of symbolic links', () {
            fs.directory(ns('/foo')).resolveSymbolicLinksSync();
          });
        });

        test('throwsPathNotFoundInTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo/bar')).resolveSymbolicLinksSync();
          });
        });

        test('throwsPathNotFoundAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).resolveSymbolicLinksSync();
          });
        });

        test('resolvesRelativePathToCurrentDirectory', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.link(ns('/foo/baz')).createSync(ns('/foo/bar'));
          fs.currentDirectory = ns('/foo');
          expect(
              fs.directory('baz').resolveSymbolicLinksSync(), ns('/foo/bar'));
        });

        test('handlesRelativeSymlinks', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          fs.link(ns('/foo/qux')).createSync('bar/baz');
          expect(fs.directory(ns('/foo/qux')).resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
        });

        test('handlesAbsoluteSymlinks', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar/baz/qux')).createSync(recursive: true);
          fs.link(ns('/foo/quux')).createSync(ns('/bar/baz/qux'));
          expect(fs.directory(ns('/foo/quux')).resolveSymbolicLinksSync(),
              ns('/bar/baz/qux'));
        });

        test('handlesParentAndThisFolderReferences', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          fs.link(ns('/foo/bar/baz/qux')).createSync('../..');
          var resolved = fs
              .directory(ns('/foo/./bar/baz/../baz/qux/bar'))
              .resolveSymbolicLinksSync();
          expect(resolved, ns('/foo/bar'));
        });

        test('handlesBackToBackSlashesInPath', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          expect(fs.directory(ns('//foo/bar///baz')).resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
        });

        test('handlesComplexPathWithMultipleSymlinks', () {
          fs.link(ns('/foo/bar/baz')).createSync('../../qux', recursive: true);
          fs.link(ns('/qux')).createSync('quux');
          fs.link(ns('/quux/quuz')).createSync(ns('/foo'), recursive: true);
          var resolved = fs
              .directory(ns('/foo//bar/./baz/quuz/bar/..///bar/baz/'))
              .resolveSymbolicLinksSync();
          expect(resolved, ns('/quux'));
        });
      });

      group('absolute', () {
        test('returnsSamePathWhenAlreadyAbsolute', () {
          expect(fs.directory(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.directory('foo').absolute.path, ns('/foo'));
        });
      });

      group('parent', () {
        test('returnsRootForRoot', () {
          expect(fs.directory('/').parent.path, '/');
        });

        test('succeedsForNonRoot', () {
          expect(fs.directory('/foo/bar').parent.path, '/foo');
        });
      });

      group('createTemp', () {
        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).createTempSync();
          });
        });

        test('resolvesNameCollisions', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          var tmp = fs.directory(ns('/foo')).createTempSync('bar');
          expect(tmp.path,
              allOf(isNot(ns('/foo/bar')), startsWith(ns('/foo/bar'))));
        });

        test('succeedsWithoutPrefix', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          expect(dir.createTempSync().path, startsWith(ns('/foo/')));
        });

        test('succeedsWithPrefix', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          expect(dir.createTempSync('bar').path, startsWith(ns('/foo/bar')));
        });

        test('succeedsWithNestedPathPrefixThatExists', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          var tmp = fs.directory(ns('/foo')).createTempSync('bar/baz');
          expect(tmp.path, startsWith(ns('/foo/bar/baz')));
        });

        test('throwsWithNestedPathPrefixThatDoesntExist', () {
          var dir = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            dir.createTempSync('bar/baz');
          });
        });
      });

      group('list', () {
        Directory dir;

        setUp(() {
          dir = fs.currentDirectory = fs.directory(ns('/foo'))..createSync();
          fs.file('bar').createSync();
          fs.file('baz/qux').createSync(recursive: true);
          fs.link('quux').createSync('baz/qux');
          fs.link('baz/quuz').createSync('../quux');
          fs.link('baz/grault').createSync('.');
          fs.currentDirectory = ns('/');
        });

        test('returnsEmptyListForEmptyDirectory', () {
          var empty = fs.directory(ns('/bar'))..createSync();
          expect(empty.listSync(), isEmpty);
        });

        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/bar')).listSync();
          });
        });

        test('returnsLinkObjectsIfFollowLinksFalse', () {
          var list = dir.listSync(followLinks: false);
          expect(list, hasLength(3));
          expect(list[0], allOf(isFile, hasPath(ns('/foo/bar'))));
          expect(list[1], allOf(isDirectory, hasPath(ns('/foo/baz'))));
          expect(list[2], allOf(isLink, hasPath(ns('/foo/quux'))));
        });

        test('followsLinksIfFollowLinksTrue', () {
          var list = dir.listSync();
          expect(list, hasLength(3));
          expect(list[0], allOf(isFile, hasPath(ns('/foo/bar'))));
          expect(list[1], allOf(isDirectory, hasPath(ns('/foo/baz'))));
          expect(list[2], allOf(isFile, hasPath(ns('/foo/quux'))));
        });

        test('returnsLinkObjectsForRecursiveLinkIfFollowLinksTrue', () {
          expect(
            dir.listSync(recursive: true),
            allOf(
              hasLength(9),
              allOf(
                contains(allOf(isFile, hasPath(ns('/foo/bar')))),
                contains(allOf(isFile, hasPath(ns('/foo/quux')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/qux')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/quuz')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/grault/qux')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/grault/quuz')))),
              ),
              allOf(
                contains(allOf(isDirectory, hasPath(ns('/foo/baz')))),
                contains(allOf(isDirectory, hasPath(ns('/foo/baz/grault')))),
              ),
              contains(allOf(isLink, hasPath(ns('/foo/baz/grault/grault')))),
            ),
          );
        });

        test('recurseIntoDirectoriesIfRecursiveTrueFollowLinksFalse', () {
          expect(
            dir.listSync(recursive: true, followLinks: false),
            allOf(
              hasLength(6),
              contains(allOf(isFile, hasPath(ns('/foo/bar')))),
              contains(allOf(isFile, hasPath(ns('/foo/baz/qux')))),
              contains(allOf(isLink, hasPath(ns('/foo/quux')))),
              contains(allOf(isLink, hasPath(ns('/foo/baz/quuz')))),
              contains(allOf(isLink, hasPath(ns('/foo/baz/grault')))),
              contains(allOf(isDirectory, hasPath(ns('/foo/baz')))),
            ),
          );
        });

        test('childEntriesNotNormalized', () {
          dir = fs.directory(ns('/bar/baz'))..createSync(recursive: true);
          fs.file(ns('/bar/baz/qux')).createSync();
          var list = fs.directory(ns('/bar//../bar/./baz')).listSync();
          expect(list, hasLength(1));
          expect(list[0], allOf(isFile, hasPath(ns('/bar//../bar/./baz/qux'))));
        });

        test('symlinksToNotFoundAlwaysReturnedAsLinks', () {
          dir = fs.directory(ns('/bar'))..createSync();
          fs.link(ns('/bar/baz')).createSync('qux');
          for (bool followLinks in [true, false]) {
            var list = dir.listSync(followLinks: followLinks);
            expect(list, hasLength(1));
            expect(list[0], allOf(isLink, hasPath(ns('/bar/baz'))));
          }
        });
      });
    });

    group('Link', () {
      group('stat', () {
        test('targetNotFoundAtTailReturnsNotFound', () {});

        test('targetNotFoundViaTraversalReturnsNotFound', () {});
      });
    });
  });
}

const Matcher isDirectory = const _IsDirectory();
const Matcher isFile = const _IsFile();
const Matcher isLink = const _IsLink();

Matcher hasPath(String path) => new _HasPath(equals(path));

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
    if (item is FileSystemException) {
      return (msg == null ||
          item.message.contains(msg) ||
          (item.osError?.message?.contains(msg) ?? false));
    }
    return false;
  }
}

// TODO: make this provide a better description of errors.
class _HasPath extends Matcher {
  final Matcher _path;
  const _HasPath(this._path);
  Description describe(Description description) => _path.describe(description);
  bool matches(item, Map matchState) => _path.matches(item.path, matchState);
}

class _IsFile extends TypeMatcher {
  const _IsFile() : super("File");
  bool matches(item, Map matchState) => item is File;
}

class _IsDirectory extends TypeMatcher {
  const _IsDirectory() : super("Directory");
  bool matches(item, Map matchState) => item is Directory;
}

class _IsLink extends TypeMatcher {
  const _IsLink() : super("Link");
  bool matches(item, Map matchState) => item is Link;
}
