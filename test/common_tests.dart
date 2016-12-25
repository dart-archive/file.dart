@TestOn("vm")
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:test/test.dart';
import 'package:test/test.dart' as testpkg show group, test;

/// Runs a suite of tests common to all file system implementations. All file
/// system implementations should run *at least* these tests to ensure
/// compliance with file system API.
///
/// If [root] is specified, its return value will be used as the root folder
/// in which all file system entities will be created. If not specified, the
/// tests will attempt to create entities in the file system root.
///
/// [skip] may be used to skip certain tests (or entire groups of tests) in
/// this suite (to be used, for instance, if a file system implementation is
/// not yet fully complete). The format of each entry in the list is:
/// `$group1Description > $group2Description > ... > $testDescription`.
/// Entries may use regular expression syntax.
void runCommonTests(
  FileSystem createFileSystem(), {
  String root(),
  List<String> skip: const <String>[],
}) {
  var rootfn = root;

  group('common', () {
    FileSystem fs;
    String root;

    List<String> stack = <String>[];

    void skipIfNecessary(description, callback()) {
      stack.add(description);
      bool matchesCurrentFrame(String input) =>
          new RegExp('^$input\$').hasMatch(stack.join(' > '));
      if (skip.where(matchesCurrentFrame).isEmpty) {
        callback();
      }
      stack.removeLast();
    }

    void group(description, body()) =>
        skipIfNecessary(description, () => testpkg.group(description, body));

    void test(description, body()) =>
        skipIfNecessary(description, () => testpkg.test(description, body));

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

        test('isDirectoryForAncestorOfRoot', () {
          var type = fs.typeSync('../../../../../../../..');
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
          expect(fs.directory(ns('/foo/bar')).existsSync(), false);
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
          expect(src.existsSync(), false);
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
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.NOT_FOUND);
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

        test('succeedsWhenDestinationIsInDifferentDirectory', () {
          var src = fs.directory(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          src.renameSync(ns('/bar/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar/baz')), FileSystemEntityType.DIRECTORY);
        });

        test('succeedsWhenSourceIsSymlinkToDifferentDirectory', () {
          fs.directory(ns('/foo/subfoo')).createSync(recursive: true);
          fs.directory(ns('/bar/subbar')).createSync(recursive: true);
          fs.directory(ns('/baz/subbaz')).createSync(recursive: true);
          fs.link(ns('/foo/subfoo/lnk')).createSync(ns('/bar/subbar'));
          fs.directory(ns('/foo/subfoo/lnk')).renameSync(ns('/baz/subbaz/dst'));
          expect(fs.typeSync(ns('/foo/subfoo/lnk')),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/baz/subbaz/dst'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/baz/subbaz/dst'), followLinks: true),
              FileSystemEntityType.DIRECTORY);
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

        test('succeedsWhenExistsAsLinkToDirectoryInDifferentDirectory', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.link(ns('/baz/qux')).createSync(ns('/foo/bar'), recursive: true);
          fs.directory(ns('/baz/qux')).deleteSync();
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
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
          expect(fs.directory('foo/qux').resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
        });

        test('handlesAbsoluteSymlinks', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar/baz/qux')).createSync(recursive: true);
          fs.link(ns('/foo/quux')).createSync(ns('/bar/baz/qux'));
          expect(fs.directory(ns('/foo/quux')).resolveSymbolicLinksSync(),
              ns('/bar/baz/qux'));
        });

        test('handlesSymlinksWhoseTargetsHaveNestedSymlinks', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/foo/quuz')).createSync(ns('/bar'));
          fs.link(ns('/foo/grault')).createSync(ns('/baz/quux'));
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/bar/qux')).createSync(ns('/baz'));
          fs.link(ns('/bar/garply')).createSync(ns('/foo'));
          fs.directory(ns('/baz')).createSync();
          fs.link(ns('/baz/quux')).createSync(ns('/bar/garply/quuz'));
          expect(fs.directory(ns('/foo/grault/qux')).resolveSymbolicLinksSync(),
              ns('/baz'));
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

    group('File', () {
      test('uri', () {
        expect(fs.file(ns('/foo')).uri.toString(), 'file://${ns('/foo')}');
        expect(fs.file('foo').uri.toString(), 'foo');
      });

      group('create', () {
        test('succeedsIfTailDoesntAlreadyExist', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).existsSync(), true);
        });

        test('succeedsIfAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).existsSync(), true);
        });

        test('throwsIfAncestorDoesntExistRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo/bar')).createSync();
          });
        });

        test('succeedsIfAncestorDoesntExistRecursiveTrue', () {
          fs.file(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.file(ns('/foo/bar')).existsSync(), true);
        });

        test('throwsIfAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Creation failed', () {
            fs.file(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Creation failed', () {
            fs.file(ns('/bar')).createSync();
          });
        });

        test('succeedsIfAlreadyExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).createSync();
          expect(fs.file(ns('/bar')).existsSync(), true);
        });
      });

      group('rename', () {
        test('succeedsIfTargetDoesntExistAtTail', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.renameSync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), false);
          expect(fs.file(ns('/bar')).existsSync(), true);
        });

        test('throwsIfTargetDoesntExistViaTraversal', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            f.renameSync(ns('/bar/baz'));
          });
        });

        test('succeedsIfTargetExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.file(ns('/bar')).createSync();
          f.renameSync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), false);
          expect(fs.file(ns('/bar')).existsSync(), true);
        });

        test('throwsIfTargetExistsAsDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          expectFileSystemException('Is a directory', () {
            f.renameSync(ns('/bar'));
          });
        });

        test('succeedsIfTargetExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.file(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          f.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.FILE);
        });

        test('throwsIfTargetExistsAsLinkToDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException('Is a directory', () {
            f.renameSync(ns('/baz'));
          });
        });

        test('throwsIfSourceDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsIfSourceExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/baz'), followLinks: true),
              FileSystemEntityType.FILE);
        });
      });

      group('copy', () {
        test('succeedsIfTargetDoesntExistAtTail', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          f.copySync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), true);
          expect(fs.file(ns('/bar')).existsSync(), true);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
        });

        test('throwsIfTargetDoesntExistViaTraversal', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            f.copySync(ns('/bar/baz'));
          });
        });

        test('succeedsIfTargetExistsAsFile', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          fs.file(ns('/bar'))
            ..createSync()
            ..writeAsStringSync('bar');
          f.copySync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), true);
          expect(fs.file(ns('/bar')).existsSync(), true);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/bar')).readAsStringSync(), 'foo');
        });

        test('throwsIfTargetExistsAsDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          expectFileSystemException('Is a directory', () {
            f.copySync(ns('/bar'));
          });
        });

        test('succeedsIfTargetExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          fs.file(ns('/bar'))
            ..createSync()
            ..writeAsStringSync('bar');
          fs.link(ns('/baz')).createSync(ns('/bar'));
          f.copySync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/bar')).readAsStringSync(), 'foo');
        });

        test('throwsIfTargetExistsAsLinkToDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException('Is a directory', () {
            f.copySync(ns('/baz'));
          });
        });

        test('throwsIfSourceDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).copySync(ns('/bar'));
          });
        });

        test('throwsIfSourceExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).copySync(ns('/bar'));
          });
        });

        test('succeedsIfSourceExistsAsLinkToFile', () {
          fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).copySync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/baz')).readAsStringSync(), 'foo');
        });

        test('succeedsIfDestinationIsInDifferentDirectoryThanSource', () {
          File f = fs.file(ns('/foo/bar'))
            ..createSync(recursive: true)
            ..writeAsStringSync('foo');
          fs.directory(ns('/baz')).createSync();
          f.copySync(ns('/baz/qux'));
          expect(fs.file(ns('/foo/bar')).existsSync(), isTrue);
          expect(fs.file(ns('/baz/qux')).existsSync(), isTrue);
          expect(fs.file(ns('/foo/bar')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/baz/qux')).readAsStringSync(), 'foo');
        });

        test('succeedsIfSourceIsLinkToFileInDifferentDirectory', () {
          fs.file(ns('/foo/bar'))
            ..createSync(recursive: true)
            ..writeAsStringSync('foo');
          fs.link(ns('/baz/qux')).createSync(ns('/foo/bar'), recursive: true);
          fs.file(ns('/baz/qux')).copySync(ns('/baz/quux'));
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/baz/quux'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.file(ns('/foo/bar')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/baz/quux')).readAsStringSync(), 'foo');
        });

        test('succeedsIfDestinationIsLinkToFileInDifferentDirectory', () {
          fs.file(ns('/foo/bar'))
            ..createSync(recursive: true)
            ..writeAsStringSync('bar');
          fs.file(ns('/baz/qux'))
            ..createSync(recursive: true)
            ..writeAsStringSync('qux');
          fs.link(ns('/baz/quux')).createSync(ns('/foo/bar'));
          fs.file(ns('/baz/qux')).copySync(ns('/baz/quux'));
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/baz/quux'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.file(ns('/foo/bar')).readAsStringSync(), 'qux');
          expect(fs.file(ns('/baz/qux')).readAsStringSync(), 'qux');
        });
      });

      group('length', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).lengthSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).lengthSync();
          });
        });

        test('returnsZeroForNewlyCreatedFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.lengthSync(), 0);
        });

        test('writeNBytesReturnsLengthN', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2, 3, 4], flush: true);
          expect(f.lengthSync(), 4);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync('foo');
          expect(fs.file(ns('/bar')).lengthSync(), 0);
        });
      });

      group('absolute', () {
        test('returnsSamePathWhenAlreadyAbsolute', () {
          expect(fs.file(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.file('foo').absolute.path, ns('/foo'));
        });
      });

      group('lastModified', () {
        test('isNowForNewlyCreatedFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(new DateTime.now().difference(f.lastModifiedSync()).abs(),
              lessThan(new Duration(seconds: 2)));
        });

        test('throwsIfDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).lastModifiedSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).lastModifiedSync();
          });
        });
      });

      group('open', () {
        void testIfDoesntExistAtTail(FileMode mode) {
          if (mode == FileMode.READ) {
            test('throwsIfDoesntExistAtTail', () {
              expectFileSystemException('No such file or directory', () {
                fs.file(ns('/bar')).openSync(mode: mode);
              });
            });
          } else {
            test('createsFileIfDoesntExistAtTail', () {
              var raf = fs.file(ns('/bar')).openSync(mode: mode);
              raf.closeSync();
              expect(fs.file(ns('/bar')).existsSync(), true);
            });
          }
        }

        void testThrowsIfDoesntExistViaTraversal(FileMode mode) {
          test('throwsIfDoesntExistViaTraversal', () {
            expectFileSystemException('No such file or directory', () {
              fs.file(ns('/bar/baz')).openSync(mode: mode);
            });
          });
        }

        void testRandomAccessFileOperations(FileMode mode) {
          group('RandomAccessFile', () {
            File f;
            RandomAccessFile raf;

            setUp(() {
              f = fs.file(ns('/foo'))..createSync();
              f.writeAsStringSync('pre-existing content\n', flush: true);
              raf = f.openSync(mode: mode);
            });

            tearDown(() {
              try {
                raf.closeSync();
              } on FileSystemException {
                // Ignore; a test may have already closed it.
              }
            });

            test('succeedsIfClosedAfterClosed', () {
              raf.closeSync();
              expectFileSystemException('File closed', () {
                raf.closeSync();
              });
            });

            test('throwsIfReadAfterClose', () {
              raf.closeSync();
              expectFileSystemException('File closed', () {
                raf.readByteSync();
              });
            });

            test('throwsIfWriteAfterClose', () {
              raf.closeSync();
              expectFileSystemException('File closed', () {
                raf.writeByteSync(0xBAD);
              });
            });

            test('throwsIfTruncateAfterClose', () {
              raf.closeSync();
              expectFileSystemException('File closed', () {
                raf.truncateSync(0);
              });
            });

            if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
              test('lengthIsResetToZeroWhenOpened', () {
                expect(raf.lengthSync(), equals(0));
              });
            } else {
              test('lengthIsNotModifiedWhenOpened', () {
                expect(raf.lengthSync(), isNot(equals(0)));
              });
            }

            if (mode == FileMode.WRITE_ONLY ||
                mode == FileMode.WRITE_ONLY_APPEND) {
              test('throwsIfReadByte', () {
                expectFileSystemException('Bad file descriptor', () {
                  raf.readByteSync();
                });
              });

              test('throwsIfRead', () {
                expectFileSystemException('Bad file descriptor', () {
                  raf.readSync(2);
                });
              });

              test('throwsIfReadInto', () {
                expectFileSystemException('Bad file descriptor', () {
                  raf.readIntoSync(new List<int>(5));
                });
              });
            } else {
              group('read', () {
                setUp(() {
                  if (mode == FileMode.WRITE) {
                    // Write data back that we truncated when opening the file.
                    raf.writeStringSync('pre-existing content\n');
                  }
                  // Reset the position to zero so we can read the content.
                  raf.setPositionSync(0);
                });

                test('readByte', () {
                  expect(UTF8.decode(<int>[raf.readByteSync()]), 'p');
                });

                test('read', () {
                  List<int> bytes = raf.readSync(1024);
                  expect(bytes.length, 21);
                  expect(UTF8.decode(bytes), 'pre-existing content\n');
                });

                test('readIntoWithBufferLargerThanContent', () {
                  List<int> buffer = new List<int>(1024);
                  int numRead = raf.readIntoSync(buffer);
                  expect(numRead, 21);
                  expect(UTF8.decode(buffer.sublist(0, 21)),
                      'pre-existing content\n');
                });

                test('readIntoWithBufferSmallerThanContent', () {
                  List<int> buffer = new List<int>(10);
                  int numRead = raf.readIntoSync(buffer);
                  expect(numRead, 10);
                  expect(UTF8.decode(buffer), 'pre-existi');
                });

                test('readIntoWithStart', () {
                  List<int> buffer = new List<int>(10);
                  int numRead = raf.readIntoSync(buffer, 2);
                  expect(numRead, 8);
                  expect(UTF8.decode(buffer.sublist(2)), 'pre-exis');
                });

                test('readIntoWithStartAndEnd', () {
                  List<int> buffer = new List<int>(10);
                  int numRead = raf.readIntoSync(buffer, 2, 5);
                  expect(numRead, 3);
                  expect(UTF8.decode(buffer.sublist(2, 5)), 'pre');
                });
              });
            }

            if (mode == FileMode.READ) {
              test('throwsIfWriteByte', () {
                expectFileSystemException('Bad file descriptor', () {
                  raf.writeByteSync(0xBAD);
                });
              });

              test('throwsIfWriteFrom', () {
                expectFileSystemException('Bad file descriptor', () {
                  raf.writeFromSync(<int>[1, 2, 3, 4]);
                });
              });

              test('throwsIfWriteString', () {
                expectFileSystemException('Bad file descriptor', () {
                  raf.writeStringSync('This should throw.');
                });
              });
            } else {
              test('lengthGrowsAsDataIsWritten', () {
                int lengthBefore = f.lengthSync();
                raf.writeByteSync(0xFACE);
                expect(raf.lengthSync(), lengthBefore + 1);
              });

              test('flush', () {
                int lengthBefore = f.lengthSync();
                raf.writeByteSync(0xFACE);
                raf.flushSync();
                expect(f.lengthSync(), lengthBefore + 1);
              });

              test('writeByte', () {
                raf.writeByteSync(UTF8.encode('A').first);
                raf.flushSync();
                if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                  expect(f.readAsStringSync(), 'A');
                } else {
                  expect(f.readAsStringSync(), 'pre-existing content\nA');
                }
              });

              test('writeFrom', () {
                raf.writeFromSync(UTF8.encode('Hello world'));
                raf.flushSync();
                if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                  expect(f.readAsStringSync(), 'Hello world');
                } else {
                  expect(f.readAsStringSync(),
                      'pre-existing content\nHello world');
                }
              });

              test('writeFromWithStart', () {
                raf.writeFromSync(UTF8.encode('Hello world'), 2);
                raf.flushSync();
                if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                  expect(f.readAsStringSync(), 'llo world');
                } else {
                  expect(
                      f.readAsStringSync(), 'pre-existing content\nllo world');
                }
              });

              test('writeFromWithStartAndEnd', () {
                raf.writeFromSync(UTF8.encode('Hello world'), 2, 5);
                raf.flushSync();
                if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                  expect(f.readAsStringSync(), 'llo');
                } else {
                  expect(f.readAsStringSync(), 'pre-existing content\nllo');
                }
              });

              test('writeString', () {
                raf.writeStringSync('Hello world');
                raf.flushSync();
                if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                  expect(f.readAsStringSync(), 'Hello world');
                } else {
                  expect(f.readAsStringSync(),
                      'pre-existing content\nHello world');
                }
              });
            }

            if (mode == FileMode.APPEND || mode == FileMode.WRITE_ONLY_APPEND) {
              test('positionInitializedToEndOfFile', () {
                expect(raf.positionSync(), 21);
              });
            } else {
              test('positionInitializedToZero', () {
                expect(raf.positionSync(), 0);
              });
            }

            group('position', () {
              setUp(() {
                if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                  // Write data back that we truncated when opening the file.
                  raf.writeStringSync('pre-existing content\n');
                }
              });

              if (mode != FileMode.WRITE_ONLY &&
                  mode != FileMode.WRITE_ONLY_APPEND) {
                test('growsAfterRead', () {
                  raf.setPositionSync(0);
                  raf.readSync(10);
                  expect(raf.positionSync(), 10);
                });

                test('affectsRead', () {
                  raf.setPositionSync(5);
                  expect(UTF8.decode(raf.readSync(5)), 'xisti');
                });
              }

              if (mode == FileMode.READ) {
                test('succeedsIfSetPastEndOfFile', () {
                  raf.setPositionSync(32);
                  expect(raf.positionSync(), 32);
                });
              } else {
                test('growsAfterWrite', () {
                  int positionBefore = raf.positionSync();
                  raf.writeStringSync('Hello world');
                  expect(raf.positionSync(), positionBefore + 11);
                });

                test('affectsWrite', () {
                  raf.setPositionSync(5);
                  raf.writeStringSync('-yo-');
                  raf.flushSync();
                  expect(f.readAsStringSync(), 'pre-e-yo-ing content\n');
                });

                test('succeedsIfSetAndWrittenPastEndOfFile', () {
                  raf.setPositionSync(32);
                  expect(raf.positionSync(), 32);
                  raf.writeStringSync('here');
                  raf.flushSync();
                  List<int> bytes = f.readAsBytesSync();
                  expect(bytes.length, 36);
                  expect(UTF8.decode(bytes.sublist(0, 21)),
                      'pre-existing content\n');
                  expect(UTF8.decode(bytes.sublist(32, 36)), 'here');
                  expect(bytes.sublist(21, 32), everyElement(0));
                });
              }

              test('throwsIfSetToNegativeNumber', () {
                expectFileSystemException('Invalid argument', () {
                  raf.setPositionSync(-12);
                });
              });
            });

            if (mode == FileMode.READ) {
              test('throwsIfTruncate', () {
                expectFileSystemException('Invalid argument', () {
                  raf.truncateSync(5);
                });
              });
            } else {
              group('truncate', () {
                setUp(() {
                  if (mode == FileMode.WRITE || mode == FileMode.WRITE_ONLY) {
                    // Write data back that we truncated when opening the file.
                    raf.writeStringSync('pre-existing content\n');
                  }
                });

                test('succeedsIfSetWithinRangeOfContent', () {
                  raf.truncateSync(5);
                  raf.flushSync();
                  expect(f.lengthSync(), 5);
                  expect(f.readAsStringSync(), 'pre-e');
                });

                test('succeedsIfSetToZero', () {
                  raf.truncateSync(0);
                  raf.flushSync();
                  expect(f.lengthSync(), 0);
                  expect(f.readAsStringSync(), isEmpty);
                });

                test('throwsIfSetToNegativeNumber', () {
                  expectFileSystemException('Invalid argument', () {
                    raf.truncateSync(-2);
                  });
                });

                test('extendsFileIfSetPastEndOfFile', () {
                  raf.truncateSync(32);
                  raf.flushSync();
                  List<int> bytes = f.readAsBytesSync();
                  expect(bytes.length, 32);
                  expect(UTF8.decode(bytes.sublist(0, 21)),
                      'pre-existing content\n');
                  expect(bytes.sublist(21, 32), everyElement(0));
                });
              });
            }
          });
        }

        void testOpenWithMode(FileMode mode) {
          testIfDoesntExistAtTail(mode);
          testThrowsIfDoesntExistViaTraversal(mode);
          testRandomAccessFileOperations(mode);
        }

        group('READ', () => testOpenWithMode(FileMode.READ));
        group('WRITE', () => testOpenWithMode(FileMode.WRITE));
        group('APPEND', () => testOpenWithMode(FileMode.APPEND));
        group('WRITE_ONLY', () => testOpenWithMode(FileMode.WRITE_ONLY));
        group('WRITE_ONLY_APPEND',
            () => testOpenWithMode(FileMode.WRITE_ONLY_APPEND));
      });

      group('openRead', () {
        test('throwsIfDoesntExist', () {
          Stream<List<int>> stream = fs.file(ns('/foo')).openRead();
          expect(stream.drain(),
              throwsFileSystemException('No such file or directory'));
        });

        test('succeedsIfExistsAsFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          var stream = f.openRead();
          var data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'Hello world');
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          Stream<List<int>> stream = fs.file(ns('/foo')).openRead();
          expect(stream.drain(), throwsFileSystemException('Is a directory'));
        });

        test('succeedsIfExistsAsLinkToFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          f.writeAsStringSync('Hello world', flush: true);
          var stream = fs.file(ns('/bar')).openRead();
          var data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'Hello world');
        });

        test('respectsStartAndEndParameters', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          var stream = f.openRead(2);
          var data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'llo world');
          stream = f.openRead(2, 5);
          data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'llo');
        });

        test('throwsIfStartParameterIsNegative', () async {
          File f = fs.file(ns('/foo'))..createSync();
          var stream = f.openRead(-2);
          expect(stream.drain(), throwsRangeError);
        });

        test('stopsAtEndOfFileIfEndParameterIsPastEndOfFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          var stream = f.openRead(2, 1024);
          var data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'llo world');
        });

        test('providesSingleSubscriptionStream', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          var stream = f.openRead();
          StreamSubscription sub1, sub2;
          sub1 = stream.listen((data) {});
          sub2 = stream.listen((data) {}, onError: expectAsync1((error) {
            sub1.cancel();
            sub2.cancel();
            expect(
                error,
                isFileSystemException(
                    'An async operation is currently pending'));
          }));
        });
      });

      group('openWrite', () {
        test('createsFileIfDoesntExist', () async {
          await fs.file(ns('/foo')).openWrite().close();
          expect(fs.file(ns('/foo')).existsSync(), true);
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).openWrite().close(),
              throwsFileSystemException('Is a directory'));
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).openWrite().close(),
              throwsFileSystemException('Is a directory'));
        });

        test('throwsIfModeIsRead', () {
          expect(() => fs.file(ns('/foo')).openWrite(mode: FileMode.READ),
              throwsArgumentError);
        });

        test('succeedsIfExistsAsEmptyFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          IOSink sink = f.openWrite();
          sink.write('Hello world');
          await sink.flush();
          await sink.close();
          expect(f.readAsStringSync(), 'Hello world');
        });

        test('succeedsIfExistsAsLinkToFile', () async {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          IOSink sink = fs.file(ns('/bar')).openWrite();
          sink.write('Hello world');
          await sink.flush();
          await sink.close();
          expect(fs.file(ns('/foo')).readAsStringSync(), 'Hello world');
        });

        test('overwritesContentInWriteMode', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello');
          IOSink sink = f.openWrite();
          sink.write('Goodbye');
          await sink.flush();
          await sink.close();
          expect(fs.file(ns('/foo')).readAsStringSync(), 'Goodbye');
        });

        test('appendsContentInAppendMode', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello');
          IOSink sink = f.openWrite(mode: FileMode.APPEND);
          sink.write('Goodbye');
          await sink.flush();
          await sink.close();
          expect(fs.file(ns('/foo')).readAsStringSync(), 'HelloGoodbye');
        });

        group('ioSink', () {
          File f;
          IOSink sink;
          bool isSinkClosed = false;

          Future<dynamic> closeSink() {
            var future = sink.close();
            isSinkClosed = true;
            return future;
          }

          setUp(() {
            f = fs.file(ns('/foo'));
            sink = f.openWrite();
          });

          tearDown(() async {
            if (!isSinkClosed) {
              await closeSink();
            }
          });

          test('throwsIfAddError', () async {
            sink.addError(new ArgumentError());
            expect(sink.done, throwsArgumentError);
            isSinkClosed = true;
          });

          test('throwsIfEncodingIsNullAndWriteObject', () {
            sink.encoding = null;
            expect(() => sink.write('Hello world'), throwsNoSuchMethodError);
          });

          test('allowsChangingEncoding', () async {
            sink.encoding = LATIN1;
            sink.write('ÿ');
            sink.encoding = UTF8;
            sink.write('ÿ');
            await sink.flush();
            expect(await f.readAsBytes(), <int>[255, 195, 191]);
          });

          test('succeedsIfAddRawData', () async {
            sink.add(<int>[1, 2, 3, 4]);
            await sink.flush();
            expect(await f.readAsBytes(), <int>[1, 2, 3, 4]);
          });

          test('succeedsIfWrite', () async {
            sink.write('Hello world');
            await sink.flush();
            expect(await f.readAsString(), 'Hello world');
          });

          test('succeedsIfWriteAll', () async {
            sink.writeAll(<String>['foo', 'bar', 'baz'], ' ');
            await sink.flush();
            expect(await f.readAsString(), 'foo bar baz');
          });

          test('succeedsIfWriteCharCode', () async {
            sink.writeCharCode(35);
            await sink.flush();
            expect(await f.readAsString(), '#');
          });

          test('succeedsIfWriteln', () async {
            sink.writeln('Hello world');
            await sink.flush();
            expect(await f.readAsString(), 'Hello world\n');
          });

          test('ignoresDataWrittenAfterClose', () async {
            sink.write('Before close');
            await closeSink();
            sink.write('After close');
            expect(await f.readAsString(), 'Before close');
          });

          test('ignoresCloseAfterAlreadyClosed', () async {
            sink.write('Hello world');
            Future f1 = closeSink();
            Future f2 = closeSink();
            await Future.wait([f1, f2]);
          });

          test('returnsAccurateDoneFuture', () async {
            bool done = false;
            sink.done.then((_) => done = true);
            expect(done, isFalse);
            sink.write('foo');
            expect(done, isFalse);
            await sink.close();
            expect(done, isTrue);
          });

          group('addStream', () {
            StreamController<List<int>> controller;
            bool isControllerClosed = false;

            Future<dynamic> closeController() {
              var future = controller.close();
              isControllerClosed = true;
              return future;
            }

            setUp(() {
              controller = new StreamController<List<int>>();
              sink.addStream(controller.stream);
            });

            tearDown(() async {
              if (!isControllerClosed) {
                await closeController();
              }
            });

            test('succeedsIfStreamProducesData', () async {
              controller.add(<int>[1, 2, 3, 4, 5]);
              await closeController();
              await sink.flush();
              expect(await f.readAsBytes(), <int>[1, 2, 3, 4, 5]);
            });

            test('blocksCallToAddWhileStreamIsActive', () {
              expect(() => sink.add(<int>[1, 2, 3]), throwsStateError);
            });

            test('blocksCallToWriteWhileStreamIsActive', () {
              expect(() => sink.write('foo'), throwsStateError);
            });

            test('blocksCallToWriteAllWhileStreamIsActive', () {
              expect(() => sink.writeAll(<String>['a', 'b']), throwsStateError);
            });

            test('blocksCallToWriteCharCodeWhileStreamIsActive', () {
              expect(() => sink.writeCharCode(35), throwsStateError);
            });

            test('blocksCallToWritelnWhileStreamIsActive', () {
              expect(() => sink.writeln('foo'), throwsStateError);
            });

            test('blocksCallToFlushWhileStreamIsActive', () {
              expect(sink.flush, throwsStateError);
            });
          });
        });
      });

      group('readAsBytes', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).readAsBytesSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).readAsBytesSync();
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/bar')).readAsBytesSync();
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/foo')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(fs.file(ns('/bar')).readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('returnsEmptyListForZeroByteFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.readAsBytesSync(), isEmpty);
        });
      });

      group('readAsString', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).readAsStringSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).readAsStringSync();
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/bar')).readAsStringSync();
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world');
          expect(f.readAsStringSync(), 'Hello world');
        });

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/foo')).writeAsStringSync('Hello world');
          expect(fs.file(ns('/bar')).readAsStringSync(), 'Hello world');
        });

        test('returnsEmptyStringForZeroByteFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.readAsStringSync(), isEmpty);
        });

        test('throwsIfEncodingIsNull', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world');
          expect(() => f.readAsStringSync(encoding: null),
              throwsNoSuchMethodError);
        });
      });

      group('readAsLines', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).readAsLinesSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).readAsLinesSync();
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/bar')).readAsLinesSync();
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world\nHow are you?\nI am fine');
          expect(f.readAsLinesSync(), <String>[
            'Hello world',
            'How are you?',
            'I am fine',
          ]);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          f.writeAsStringSync('Hello world\nHow are you?\nI am fine');
          expect(f.readAsLinesSync(), <String>[
            'Hello world',
            'How are you?',
            'I am fine',
          ]);
        });

        test('returnsEmptyListForZeroByteFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.readAsLinesSync(), isEmpty);
        });
      });

      group('writeAsBytes', () {
        test('createsFileIfDoesntExist', () {
          File f = fs.file(ns('/foo'));
          expect(f.existsSync(), isFalse);
          f.writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(f.existsSync(), isTrue);
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          });
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('throwsIfFileModeRead', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException('Bad file descriptor', () {
            f.writeAsBytesSync(<int>[1], mode: FileMode.READ);
          });
        });

        test('overwritesContentIfFileModeWrite', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2]);
          expect(f.readAsBytesSync(), <int>[1, 2]);
          f.writeAsBytesSync(<int>[3, 4]);
          expect(f.readAsBytesSync(), <int>[3, 4]);
        });

        test('appendsContentIfFileModeAppend', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2], mode: FileMode.APPEND);
          expect(f.readAsBytesSync(), <int>[1, 2]);
          f.writeAsBytesSync(<int>[3, 4], mode: FileMode.APPEND);
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('acceptsEmptyBytesList', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[]);
          expect(f.readAsBytesSync(), <int>[]);
        });
      });

      group('writeAsString', () {
        test('createsFileIfDoesntExist', () {
          File f = fs.file(ns('/foo'));
          expect(f.existsSync(), isFalse);
          f.writeAsStringSync('Hello world');
          expect(f.existsSync(), isTrue);
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).writeAsStringSync('Hello world');
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).writeAsStringSync('Hello world');
          });
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).writeAsStringSync('Hello world');
          expect(f.readAsStringSync(), 'Hello world');
        });

        test('throwsIfFileModeRead', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException('Bad file descriptor', () {
            f.writeAsStringSync('Hello world', mode: FileMode.READ);
          });
        });

        test('overwritesContentIfFileModeWrite', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world');
          expect(f.readAsStringSync(), 'Hello world');
          f.writeAsStringSync('Goodbye cruel world');
          expect(f.readAsStringSync(), 'Goodbye cruel world');
        });

        test('appendsContentIfFileModeAppend', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello', mode: FileMode.APPEND);
          expect(f.readAsStringSync(), 'Hello');
          f.writeAsStringSync('Goodbye', mode: FileMode.APPEND);
          expect(f.readAsStringSync(), 'HelloGoodbye');
        });

        test('acceptsEmptyString', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('');
          expect(f.readAsStringSync(), isEmpty);
        });

        test('throwsIfNullEncoding', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(() => f.writeAsStringSync('Hello world', encoding: null),
              throwsNoSuchMethodError);
        });
      });

      group('exists', () {
        test('trueIfExists', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).existsSync(), isTrue);
        });

        test('falseIfDoesntExistAtTail', () {
          expect(fs.file(ns('/foo')).existsSync(), isFalse);
        });

        test('falseIfDoesntExistViaTraversal', () {
          expect(fs.file(ns('/foo/bar')).existsSync(), isFalse);
        });

        test('falseIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).existsSync(), isFalse);
        });

        test('falseIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).existsSync(), isFalse);
        });

        test('trueIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).existsSync(), isTrue);
        });
      });

      group('stat', () {
        test('isNotFoundIfDoesntExistAtTail', () {
          FileStat stat = fs.file(ns('/foo')).statSync();
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundIfDoesntExistViaTraversal', () {
          FileStat stat = fs.file(ns('/foo/bar')).statSync();
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });

        test('isDirectoryIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          FileStat stat = fs.file(ns('/foo')).statSync();
          expect(stat.type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileIfExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          FileStat stat = fs.file(ns('/foo')).statSync();
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isFileIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileStat stat = fs.file(ns('/bar')).statSync();
          expect(stat.type, FileSystemEntityType.FILE);
        });
      });

      group('delete', () {
        test('succeedsIfExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).existsSync(), isTrue);
          fs.file(ns('/foo')).deleteSync();
          expect(fs.file(ns('/foo')).existsSync(), isFalse);
        });

        test('throwsIfDoesntExistAndRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).deleteSync();
          });
        });

        test('throwsIfDoesntExistAndRecursiveTrue', () {
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).deleteSync(recursive: true);
          });
        });

        test('succeedsIfExistsAsDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.file(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
        });

        test('throwsIfExistsAsDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfExistsAsLinkToFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).existsSync(), isTrue);
          fs.file(ns('/bar')).deleteSync(recursive: true);
          expect(fs.file(ns('/bar')).existsSync(), isFalse);
        });

        test('succeedsIfExistsAsLinkToFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).existsSync(), isTrue);
          fs.file(ns('/bar')).deleteSync();
          expect(fs.file(ns('/bar')).existsSync(), isFalse);
        });

        test('succeedsIfExistsAsLinkToDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.DIRECTORY);
          fs.file(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.NOT_FOUND);
        });

        test('throwsIfExistsAsLinkToDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/bar')).deleteSync();
          });
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
