// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn("vm")
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/testing.dart';
import 'package:test/test.dart';
import 'package:test/test.dart' as testpkg show group, test;

/// Callback used in [runCommonTests] to produce the root folder in which all
/// file system entities will be created.
typedef String RootPathGenerator();

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
  RootPathGenerator root,
  List<String> skip: const <String>[],
}) {
  RootPathGenerator rootfn = root;

  group('common', () {
    FileSystem fs;
    String root;

    List<String> stack = <String>[];

    void skipIfNecessary(String description, callback()) {
      stack.add(description);
      bool matchesCurrentFrame(String input) =>
          new RegExp('^$input\$').hasMatch(stack.join(' > '));
      if (skip.where(matchesCurrentFrame).isEmpty) {
        callback();
      }
      stack.removeLast();
    }

    void group(String description, body()) =>
        skipIfNecessary(description, () => testpkg.group(description, body));

    void test(String description, body()) =>
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

    setUp(() {
      root = rootfn != null ? rootfn() : '/';
      assert(root.startsWith('/') && (root == '/' || !root.endsWith('/')));
      fs = createFileSystem();
    });

    group('FileSystem', () {
      group('directory', () {
        test('allowsStringArgument', () {
          expect(fs.directory(ns('/foo')), isDirectory);
        });

        test('allowsUriArgument', () {
          expect(fs.directory(Uri.parse('file:///')), isDirectory);
        });

        test('allowsDirectoryArgument', () {
          expect(fs.directory(new io.Directory(ns('/foo'))), isDirectory);
        });

        test('disallowsOtherArgumentType', () {
          expect(() => fs.directory(123), throwsArgumentError);
        });
      });

      group('file', () {
        test('allowsStringArgument', () {
          expect(fs.file(ns('/foo')), isFile);
        });

        test('allowsUriArgument', () {
          expect(fs.file(Uri.parse('file:///')), isFile);
        });

        test('allowsDirectoryArgument', () {
          expect(fs.file(new io.File(ns('/foo'))), isFile);
        });

        test('disallowsOtherArgumentType', () {
          expect(() => fs.file(123), throwsArgumentError);
        });
      });

      group('link', () {
        test('allowsStringArgument', () {
          expect(fs.link(ns('/foo')), isLink);
        });

        test('allowsUriArgument', () {
          expect(fs.link(Uri.parse('file:///')), isLink);
        });

        test('allowsDirectoryArgument', () {
          expect(fs.link(new io.File(ns('/foo'))), isLink);
        });

        test('disallowsOtherArgumentType', () {
          expect(() => fs.link(123), throwsArgumentError);
        });
      });

      group('path', () {
        test('hasCorrectCurrentWorkingDirectory', () {
          expect(fs.path.current, fs.currentDirectory.path);
        });

        test('separatorIsAmongExpectedValues', () {
          expect(fs.path.separator, anyOf('/', r'\'));
        });
      });

      group('systemTempDirectory', () {
        test('existsAsDirectory', () {
          Directory tmp = fs.systemTempDirectory;
          expect(tmp, isDirectory);
          expect(tmp.existsSync(), isTrue);
        });
      });

      group('currentDirectory', () {
        test('defaultsToRoot', () {
          expect(fs.currentDirectory.path, root);
        });

        test('throwsIfSetToNonExistentPath', () {
          expectFileSystemException('No such file or directory', () {
            fs.currentDirectory = ns('/foo');
          });
        });

        test('throwsIfHasNonExistentPathInComplexChain', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('No such file or directory', () {
            fs.currentDirectory = ns('/bar/../foo');
          });
        });

        test('succeedsIfSetToValidStringPath', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = ns('/foo');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('succeedsIfSetToValidDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = new io.Directory(ns('/foo'));
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsIfArgumentIsNotStringOrDirectory', () {
          expect(() {
            fs.currentDirectory = 123;
          }, throwsArgumentError);
        });

        test('succeedsIfSetToRelativePath', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, ns('/foo'));
          fs.currentDirectory = 'bar';
          expect(fs.currentDirectory.path, ns('/foo/bar'));
        });

        test('succeedsIfSetToAbsolutePathWhenCwdIsNotRoot', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.directory(ns('/baz/qux')).createSync(recursive: true);
          fs.currentDirectory = ns('/foo/bar');
          expect(fs.currentDirectory.path, ns('/foo/bar'));
          fs.currentDirectory = fs.directory(ns('/baz/qux'));
          expect(fs.currentDirectory.path, ns('/baz/qux'));
        });

        test('succeedsIfSetToParentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, ns('/foo'));
          fs.currentDirectory = '..';
          expect(fs.currentDirectory.path, ns('/'));
        });

        test('staysAtRootIfSetToParentOfRoot', () {
          fs.currentDirectory = '../../../../../../../../../..';
          expect(fs.currentDirectory.path, '/');
        });

        test('removesTrailingSlashIfSet', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = ns('/foo/');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsIfSetToFilePathSegmentAtTail', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Not a directory', () {
            fs.currentDirectory = ns('/foo');
          });
        });

        test('throwsIfSetToFilePathSegmentViaTraversal', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Not a directory', () {
            fs.currentDirectory = ns('/foo/bar/baz');
          });
        });

        test('resolvesLinksIfEncountered', () {
          fs.link(ns('/foo/bar/baz')).createSync(ns('/qux'), recursive: true);
          fs.directory(ns('/qux')).createSync();
          fs.directory(ns('/quux')).createSync();
          fs.currentDirectory = ns('/foo/bar/baz/../quux/');
          expect(fs.currentDirectory.path, ns('/quux'));
        });

        test('succeedsIfSetToDirectoryLinkAtTail', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.currentDirectory = ns('/bar');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsIfSetToLinkLoop', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Too many levels of symbolic links', () {
            fs.currentDirectory = ns('/foo');
          });
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
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileForFile', () {
          fs.file(ns('/foo')).createSync();
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isFileForLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileStat stat = fs.statSync(ns('/bar'));
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isNotFoundForLinkWithCircularReference', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz')).createSync(ns('/foo'));
          FileStat stat = fs.statSync(ns('/foo'));
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
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.FILE);
        });

        test('isDirectoryForDirectory', () {
          fs.directory(ns('/foo')).createSync();
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.DIRECTORY);
        });

        test('isDirectoryForAncestorOfRoot', () {
          FileSystemEntityType type = fs.typeSync('../../../../../../../..');
          expect(type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileForLinkToFileAndFollowLinksTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileSystemEntityType type = fs.typeSync(ns('/bar'));
          expect(type, FileSystemEntityType.FILE);
        });

        test('isLinkForLinkToFileAndFollowLinksFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileSystemEntityType type =
              fs.typeSync(ns('/bar'), followLinks: false);
          expect(type, FileSystemEntityType.LINK);
        });

        test('isNotFoundForLinkWithCircularReferenceAndFollowLinksTrue', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz')).createSync(ns('/foo'));
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundForNoEntityAtTail', () {
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundForNoDirectoryInTraversal', () {
          FileSystemEntityType type = fs.typeSync(ns('/foo/bar/baz'));
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
        test('falseIfNotExists', () {
          expect(fs.directory(ns('/foo')).existsSync(), false);
          expect(fs.directory('foo').existsSync(), false);
          expect(fs.directory(ns('/foo/bar')).existsSync(), false);
        });

        test('trueIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')).existsSync(), true);
          expect(fs.directory('foo').existsSync(), true);
        });

        test('falseIfExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')).existsSync(), false);
          expect(fs.directory('foo').existsSync(), false);
        });

        test('trueIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.directory(ns('/bar')).existsSync(), true);
          expect(fs.directory('bar').existsSync(), true);
        });

        test('falseIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.directory(ns('/bar')).existsSync(), false);
          expect(fs.directory('bar').existsSync(), false);
        });

        test('falseIfNotFoundSegmentExistsThenIsBackedOut', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/bar/../foo')).existsSync(), isFalse);
        });
      });

      group('create', () {
        test('returnsCovariantType', () async {
          expect(await fs.directory(ns('/foo')).create(), isDirectory);
        });

        test('succeedsIfAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/foo')).createSync();
        });

        test('throwsIfAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          // TODO(tvolkert): Change this to just be 'Not a directory'
          // once Dart 1.22 is stable.
          String pattern = '(File exists|Not a directory)';
          expectFileSystemException(matches(pattern), () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('succeedsIfAlreadyExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).createSync();
        });

        test('throwsIfAlreadyExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          // TODO(tvolkert): Change this to just be 'Not a directory'
          // once Dart 1.22 is stable.
          String pattern = '(File exists|Not a directory)';
          expectFileSystemException(matches(pattern), () {
            fs.directory(ns('/bar')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundAtTail', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundViaTraversal', () {
          fs.link(ns('/foo')).createSync(ns('/bar/baz'));
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundInDifferentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/bar/baz')).createSync(ns('/foo/qux'));
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/bar/baz')).createSync();
          });
        });

        test('succeedsIfTailDoesntExist', () {
          expect(fs.directory(ns('/')).existsSync(), true);
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')).existsSync(), true);
        });

        test('throwsIfAncestorDoesntExistRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo/bar')).createSync();
          });
        });

        test('succeedsIfAncestorDoesntExistRecursiveTrue', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.directory(ns('/foo')).existsSync(), true);
          expect(fs.directory(ns('/foo/bar')).existsSync(), true);
        });
      });

      group('rename', () {
        test('returnsCovariantType', () async {
          Directory src() => fs.directory(ns('/foo'))..createSync();
          expect(src().renameSync(ns('/bar')), isDirectory);
          expect(await src().rename(ns('/baz')), isDirectory);
        });

        test('succeedsIfDestinationDoesntExist', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          Directory dest = src.renameSync(ns('/bar'));
          expect(dest.path, ns('/bar'));
          expect(dest.existsSync(), true);
        });

        test('succeedsIfDestinationIsEmptyDirectory', () {
          fs.directory(ns('/bar')).createSync();
          Directory src = fs.directory(ns('/foo'))..createSync();
          Directory dest = src.renameSync(ns('/bar'));
          expect(src.existsSync(), false);
          expect(dest.existsSync(), true);
        });

        test('throwsIfDestinationIsFile', () {
          fs.file(ns('/bar')).createSync();
          Directory src = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException('Not a directory', () {
            src.renameSync(ns('/bar'));
          });
        });

        test('throwsIfDestinationParentFolderDoesntExist', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            src.renameSync(ns('/bar/baz'));
          });
        });

        test('throwsIfDestinationIsNonEmptyDirectory', () {
          fs.file(ns('/bar/baz')).createSync(recursive: true);
          Directory src = fs.directory(ns('/foo'))..createSync();
          // The error will be 'Directory not empty' on OS X, but it will be
          // 'File exists' on Linux, so we just ignore it here in the test.
          expectFileSystemException(null, () {
            src.renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceIsFile', () {
          fs.file(ns('/foo')).createSync();
          // The error message is usually 'No such file or directory', but
          // it's occasionally 'Not a directory', 'Directory not empty',
          // 'File exists', or 'Undefined error'.
          // https://github.com/dart-lang/sdk/issues/28147
          expectFileSystemException(null, () {
            fs.directory(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsIfSourceIsLinkToDirectory', () {
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

        test('succeedsIfDestinationIsLinkToNotFound', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/baz'));
          expectFileSystemException('Not a directory', () {
            src.renameSync(ns('/bar'));
          });
        });

        test('throwsIfDestinationIsLinkToEmptyDirectory', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException('Not a directory', () {
            src.renameSync(ns('/baz'));
          });
        });

        test('succeedsIfDestinationIsInDifferentDirectory', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          src.renameSync(ns('/bar/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar/baz')), FileSystemEntityType.DIRECTORY);
        });

        test('succeedsIfSourceIsLinkToDifferentDirectory', () {
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
        test('returnsCovariantType', () async {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expect(await dir.delete(), isDirectory);
        });

        test('succeedsIfEmptyDirectoryExistsAndRecursiveFalse', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          dir.deleteSync();
          expect(dir.existsSync(), false);
        });

        test('succeedsIfEmptyDirectoryExistsAndRecursiveTrue', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          dir.deleteSync(recursive: true);
          expect(dir.existsSync(), false);
        });

        test('throwsIfNonEmptyDirectoryExistsAndRecursiveFalse', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          fs.file(ns('/foo/bar')).createSync();
          expectFileSystemException('Directory not empty', () {
            dir.deleteSync();
          });
        });

        test('succeedsIfNonEmptyDirectoryExistsAndRecursiveTrue', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          fs.file(ns('/foo/bar')).createSync();
          dir.deleteSync(recursive: true);
          expect(fs.directory(ns('/foo')).existsSync(), false);
          expect(fs.file(ns('/foo/bar')).existsSync(), false);
        });

        test('throwsIfDirectoryDoesntExistAndRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });

        test('throwsIfDirectoryDoesntExistAndRecursiveTrue', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).deleteSync(recursive: true);
          });
        });

        test('succeedsIfPathReferencesFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.directory(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
        });

        test('throwsIfPathReferencesFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Not a directory', () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfPathReferencesLinkToDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsIfPathReferencesLinkToDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsIfExistsAsLinkToDirectoryInDifferentDirectory', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.link(ns('/baz/qux')).createSync(ns('/foo/bar'), recursive: true);
          fs.directory(ns('/baz/qux')).deleteSync();
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsIfPathReferencesLinkToFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('throwsIfPathReferencesLinkToFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Not a directory', () {
            fs.directory(ns('/bar')).deleteSync();
          });
        });

        test('throwsIfPathReferencesLinkToNotFoundAndRecursiveFalse', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException('Not a directory', () {
            fs.directory(ns('/foo')).deleteSync();
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

        test('throwsIfPathNotFoundInTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo/bar')).resolveSymbolicLinksSync();
          });
        });

        test('throwsIfPathNotFoundAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).resolveSymbolicLinksSync();
          });
        });

        test('throwsIfPathNotFoundInMiddleThenBackedOut', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo/baz/../bar')).resolveSymbolicLinksSync();
          });
        });

        test('resolvesRelativePathToCurrentDirectory', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.link(ns('/foo/baz')).createSync(ns('/foo/bar'));
          fs.currentDirectory = ns('/foo');
          expect(
              fs.directory('baz').resolveSymbolicLinksSync(), ns('/foo/bar'));
        });

        test('resolvesAbsolutePathsAbsolutely', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.currentDirectory = ns('/foo');
          expect(fs.directory(ns('/foo/bar')).resolveSymbolicLinksSync(),
              ns('/foo/bar'));
        });

        test('handlesRelativeLinks', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          fs.link(ns('/foo/qux')).createSync('bar/baz');
          expect(fs.directory(ns('/foo/qux')).resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
          expect(fs.directory('foo/qux').resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
        });

        test('handlesAbsoluteLinks', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar/baz/qux')).createSync(recursive: true);
          fs.link(ns('/foo/quux')).createSync(ns('/bar/baz/qux'));
          expect(fs.directory(ns('/foo/quux')).resolveSymbolicLinksSync(),
              ns('/bar/baz/qux'));
        });

        test('handlesLinksWhoseTargetsHaveNestedLinks', () {
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
          String resolved = fs
              .directory(ns('/foo/./bar/baz/../baz/qux/bar'))
              .resolveSymbolicLinksSync();
          expect(resolved, ns('/foo/bar'));
        });

        test('handlesBackToBackSlashesInPath', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          expect(fs.directory(ns('//foo/bar///baz')).resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
        });

        test('handlesComplexPathWithMultipleLinks', () {
          fs.link(ns('/foo/bar/baz')).createSync('../../qux', recursive: true);
          fs.link(ns('/qux')).createSync('quux');
          fs.link(ns('/quux/quuz')).createSync(ns('/foo'), recursive: true);
          String resolved = fs
              .directory(ns('/foo//bar/./baz/quuz/bar/..///bar/baz/'))
              .resolveSymbolicLinksSync();
          expect(resolved, ns('/quux'));
        });
      });

      group('absolute', () {
        test('returnsCovariantType', () {
          expect(fs.directory('foo').absolute, isDirectory);
        });

        test('returnsSamePathIfAlreadyAbsolute', () {
          expect(fs.directory(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.directory('foo').absolute.path, ns('/foo'));
        });
      });

      group('parent', () {
        test('returnsCovariantType', () {
          expect(fs.directory('/').parent, isDirectory);
        });

        test('returnsRootForRoot', () {
          expect(fs.directory('/').parent.path, '/');
        });

        test('succeedsForNonRoot', () {
          expect(fs.directory('/foo/bar').parent.path, '/foo');
        });
      });

      group('createTemp', () {
        test('returnsCovariantType', () {
          expect(fs.directory(ns('/')).createTempSync(), isDirectory);
        });

        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/foo')).createTempSync();
          });
        });

        test('resolvesNameCollisions', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          Directory tmp = fs.directory(ns('/foo')).createTempSync('bar');
          expect(tmp.path,
              allOf(isNot(ns('/foo/bar')), startsWith(ns('/foo/bar'))));
        });

        test('succeedsWithoutPrefix', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expect(dir.createTempSync().path, startsWith(ns('/foo/')));
        });

        test('succeedsWithPrefix', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expect(dir.createTempSync('bar').path, startsWith(ns('/foo/bar')));
        });

        test('succeedsWithNestedPathPrefixThatExists', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          Directory tmp = fs.directory(ns('/foo')).createTempSync('bar/baz');
          expect(tmp.path, startsWith(ns('/foo/bar/baz')));
        });

        test('throwsWithNestedPathPrefixThatDoesntExist', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
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

        test('returnsCovariantType', () async {
          void expectIsFileSystemEntity(dynamic entity) {
            expect(entity, isFileSystemEntity);
          }

          dir.listSync().forEach(expectIsFileSystemEntity);
          (await dir.list().toList()).forEach(expectIsFileSystemEntity);
        });

        test('returnsEmptyListForEmptyDirectory', () {
          Directory empty = fs.directory(ns('/bar'))..createSync();
          expect(empty.listSync(), isEmpty);
        });

        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory(ns('/bar')).listSync();
          });
        });

        test('returnsLinkObjectsIfFollowLinksFalse', () {
          List<FileSystemEntity> list = dir.listSync(followLinks: false);
          expect(list, hasLength(3));
          expect(list, contains(allOf(isFile, hasPath(ns('/foo/bar')))));
          expect(list, contains(allOf(isDirectory, hasPath(ns('/foo/baz')))));
          expect(list, contains(allOf(isLink, hasPath(ns('/foo/quux')))));
        });

        test('followsLinksIfFollowLinksTrue', () {
          List<FileSystemEntity> list = dir.listSync();
          expect(list, hasLength(3));
          expect(list, contains(allOf(isFile, hasPath(ns('/foo/bar')))));
          expect(list, contains(allOf(isDirectory, hasPath(ns('/foo/baz')))));
          expect(list, contains(allOf(isFile, hasPath(ns('/foo/quux')))));
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
          List<FileSystemEntity> list =
              fs.directory(ns('/bar//../bar/./baz')).listSync();
          expect(list, hasLength(1));
          expect(list[0], allOf(isFile, hasPath(ns('/bar//../bar/./baz/qux'))));
        });

        test('symlinksToNotFoundAlwaysReturnedAsLinks', () {
          dir = fs.directory(ns('/bar'))..createSync();
          fs.link(ns('/bar/baz')).createSync('qux');
          for (bool followLinks in const <bool>[true, false]) {
            List<FileSystemEntity> list =
                dir.listSync(followLinks: followLinks);
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
        test('returnsCovariantType', () async {
          expect(await fs.file(ns('/foo')).create(), isFile);
        });

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
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/bar')).createSync();
          });
        });

        test('succeedsIfAlreadyExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).createSync();
          expect(fs.file(ns('/bar')).existsSync(), true);
        });

        test('succeedsIfAlreadyExistsAsLinkToNotFoundAtTail', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.file(ns('/foo')).createSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundViaTraversal', () {
          fs.link(ns('/foo')).createSync(ns('/bar/baz'));
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).createSync();
          });
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).createSync(recursive: true);
          });
        });

        /*
        test('throwsIfPathSegmentIsLinkToNotFoundAndRecursiveTrue', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo/baz')).createSync(recursive: true);
          });
        });
        */

        test('succeedsIfAlreadyExistsAsLinkToNotFoundInDifferentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/bar/baz')).createSync(ns('/foo/qux'));
          fs.file(ns('/bar/baz')).createSync();
          expect(fs.typeSync(ns('/bar/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/foo/qux'), followLinks: false),
              FileSystemEntityType.FILE);
        });
      });

      group('rename', () {
        test('returnsCovariantType', () async {
          File f() => fs.file(ns('/foo'))..createSync();
          expect(await f().rename(ns('/bar')), isFile);
          expect(f().renameSync(ns('/baz')), isFile);
        });

        test('succeedsIfDestinationDoesntExistAtTail', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.renameSync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), false);
          expect(fs.file(ns('/bar')).existsSync(), true);
        });

        test('throwsIfDestinationDoesntExistViaTraversal', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            f.renameSync(ns('/bar/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.file(ns('/bar')).createSync();
          f.renameSync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), false);
          expect(fs.file(ns('/bar')).existsSync(), true);
        });

        test('throwsIfDestinationExistsAsDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          expectFileSystemException('Is a directory', () {
            f.renameSync(ns('/bar'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToFile', () {
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

        test('throwsIfDestinationExistsAsLinkToDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException('Is a directory', () {
            f.renameSync(ns('/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToNotFound', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/baz'));
          f.renameSync(ns('/bar'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
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

        test('throwsIfSourceExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException('Is a directory', () {
            fs.file(ns('/bar')).renameSync(ns('/baz'));
          });
        });

        test('throwsIfSourceExistsAsLinkToNotFound', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException('No such file or directory', () {
            fs.file(ns('/foo')).renameSync(ns('/baz'));
          });
        });
      });

      group('copy', () {
        test('returnsCovariantType', () async {
          File f() => fs.file(ns('/foo'))..createSync();
          expect(await f().copy(ns('/bar')), isFile);
          expect(f().copySync(ns('/baz')), isFile);
        });

        test('succeedsIfDestinationDoesntExistAtTail', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          f.copySync(ns('/bar'));
          expect(fs.file(ns('/foo')).existsSync(), true);
          expect(fs.file(ns('/bar')).existsSync(), true);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
        });

        test('throwsIfDestinationDoesntExistViaTraversal', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException('No such file or directory', () {
            f.copySync(ns('/bar/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsFile', () {
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

        test('throwsIfDestinationExistsAsDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          expectFileSystemException('Is a directory', () {
            f.copySync(ns('/bar'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToFile', () {
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

        test('throwsIfDestinationExistsAsLinkToDirectory', () {
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
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).lengthSync(), 0);
        });
      });

      group('absolute', () {
        test('returnsSamePathIfAlreadyAbsolute', () {
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

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(
            new DateTime.now()
                .difference(fs.file(ns('/bar')).lastModifiedSync())
                .abs(),
            lessThan(new Duration(seconds: 2)),
          );
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
              RandomAccessFile raf = fs.file(ns('/bar')).openSync(mode: mode);
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
              test('lengthIsResetToZeroIfOpened', () {
                expect(raf.lengthSync(), equals(0));
              });
            } else {
              test('lengthIsNotModifiedIfOpened', () {
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
          Stream<List<int>> stream = f.openRead();
          List<List<int>> data = await stream.toList();
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
          Stream<List<int>> stream = fs.file(ns('/bar')).openRead();
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'Hello world');
        });

        test('respectsStartAndEndParameters', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead(2);
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'llo world');
          stream = f.openRead(2, 5);
          data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'llo');
        });

        test('throwsIfStartParameterIsNegative', () async {
          File f = fs.file(ns('/foo'))..createSync();
          Stream<List<int>> stream = f.openRead(-2);
          expect(stream.drain(), throwsRangeError);
        });

        test('stopsAtEndOfFileIfEndParameterIsPastEndOfFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead(2, 1024);
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(UTF8.decode(data[0]), 'llo world');
        });

        test('providesSingleSubscriptionStream', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead();
          expect(stream.isBroadcast, isFalse);
          await stream.drain();
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
            Future<dynamic> future = sink.close();
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
            Future<dynamic> f1 = closeSink();
            Future<dynamic> f2 = closeSink();
            await Future.wait(<Future<dynamic>>[f1, f2]);
          });

          test('returnsAccurateDoneFuture', () async {
            bool done = false;
            sink.done.then((_) => done = true); // ignore: unawaited_futures
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
              Future<dynamic> future = controller.close();
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
        test('returnsCovariantType', () async {
          expect(await fs.file(ns('/foo')).writeAsBytes(<int>[]), isFile);
        });

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
        test('returnsCovariantType', () async {
          expect(await fs.file(ns('/foo')).writeAsString('foo'), isFile);
        });

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

        test('falseIfNotFoundSegmentExistsThenIsBackedOut', () {
          fs.file(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.directory(ns('/baz/../foo/bar')).existsSync(), isFalse);
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
        test('returnsCovariantType', () async {
          File f = fs.file(ns('/foo'))..createSync();
          expect(await f.delete(), isFile);
        });

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
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.DIRECTORY);
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
      group('uri', () {
        test('whenTargetIsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          Link l = fs.link(ns('/bar'))..createSync(ns('/foo'));
          expect(l.uri.toString(), 'file://${ns('/bar')}');
          expect(fs.link('bar').uri.toString(), 'bar');
        });

        test('whenTargetIsFile', () {
          fs.file(ns('/foo')).createSync();
          Link l = fs.link(ns('/bar'))..createSync(ns('/foo'));
          expect(l.uri.toString(), 'file://${ns('/bar')}');
          expect(fs.link('bar').uri.toString(), 'bar');
        });

        test('whenLinkDoesntExist', () {
          expect(fs.link(ns('/foo')).uri.toString(), 'file://${ns('/foo')}');
          expect(fs.link('foo').uri.toString(), 'foo');
        });
      });

      group('exists', () {
        test('isFalseIfLinkDoesntExistAtTail', () {
          expect(fs.link(ns('/foo')).existsSync(), isFalse);
        });

        test('isFalseIfLinkDoesntExistViaTraversal', () {
          expect(fs.link(ns('/foo/bar')).existsSync(), isFalse);
        });

        test('isFalseIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.link(ns('/foo')).existsSync(), isFalse);
        });

        test('isFalseIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.link(ns('/foo')).existsSync(), isFalse);
        });

        test('isTrueIfTargetIsNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l.existsSync(), isTrue);
        });

        test('isTrueIfTargetIsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          expect(l.existsSync(), isTrue);
        });

        test('isTrueIfTargetIsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          expect(l.existsSync(), isTrue);
        });

        test('isTrueIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(l.existsSync(), isTrue);
        });
      });

      group('stat', () {
        test('isNotFoundIfLinkDoesntExistAtTail', () {
          expect(fs.link(ns('/foo')).statSync().type,
              FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundIfLinkDoesntExistViaTraversal', () {
          expect(fs.link(ns('/foo/bar')).statSync().type,
              FileSystemEntityType.NOT_FOUND);
        });

        test('isFileIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expect(
              fs.link(ns('/foo')).statSync().type, FileSystemEntityType.FILE);
        });

        test('isDirectoryIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.link(ns('/foo')).statSync().type,
              FileSystemEntityType.DIRECTORY);
        });

        test('isNotFoundIfTargetNotFoundAtTail', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l.statSync().type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundIfTargetNotFoundViaTraversal', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar/baz'));
          expect(l.statSync().type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(l.statSync().type, FileSystemEntityType.NOT_FOUND);
        });

        test('isFileIfTargetIsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          expect(l.statSync().type, FileSystemEntityType.FILE);
        });

        test('isDirectoryIfTargetIsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          expect(l.statSync().type, FileSystemEntityType.DIRECTORY);
        });
      });

      group('delete', () {
        test('returnsCovariantType', () async {
          Link link = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(await link.delete(), isLink);
        });

        test('throwsIfLinkDoesntExistAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo')).deleteSync();
          });
        });

        test('throwsIfLinkDoesntExistViaTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo/bar')).deleteSync();
          });
        });

        test('throwsIfPathReferencesFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Invalid argument', () {
            fs.link(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfPathReferencesFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('throwsIfPathReferencesDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          // TODO(tvolkert): Change this to just be 'Is a directory'
          // once Dart 1.22 is stable.
          String pattern = '(Invalid argument|Is a directory)';
          expectFileSystemException(matches(pattern), () {
            fs.link(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfPathReferencesDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('unlinksIfTargetIsFileAndRecursiveFalse', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          l.deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
        });

        test('unlinksIfTargetIsFileAndRecursiveTrue', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          l.deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
        });

        test('unlinksIfTargetIsDirectoryAndRecursiveFalse', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          l.deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
        });

        test('unlinksIfTargetIsDirectoryAndRecursiveTrue', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          l.deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
        });

        test('unlinksIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar'))..createSync(ns('/foo'));
          l.deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.LINK);
        });
      });

      group('parent', () {
        test('returnsCovariantType', () {
          expect(fs.link(ns('/foo')).parent, isDirectory);
        });

        test('succeedsIfLinkDoesntExist', () {
          expect(fs.link(ns('/foo')).parent.path, ns('/'));
        });

        test('ignoresLinkTarget', () {
          Link l = fs.link(ns('/foo/bar'))
            ..createSync(ns('/baz/qux'), recursive: true);
          expect(l.parent.path, ns('/foo'));
        });
      });

      group('create', () {
        test('returnsCovariantType', () async {
          expect(await fs.link(ns('/foo')).create(ns('/bar')), isLink);
        });

        test('succeedsIfLinkDoesntExistAtTail', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(l.targetSync(), ns('/bar'));
        });

        test('throwsIfLinkDoesntExistViaTraversalAndRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo/bar')).createSync('baz');
          });
        });

        test('succeedsIfLinkDoesntExistViaTraversalAndRecursiveTrue', () {
          Link l = fs.link(ns('/foo/bar'))..createSync('baz', recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(l.targetSync(), 'baz');
        });

        test('throwsIfAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('File exists', () {
            fs.link(ns('/foo')).createSync(ns('/bar'));
          });
        });

        test('throwsIfAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('File exists', () {
            fs.link(ns('/foo')).createSync(ns('/bar'));
          });
        });

        test('throwsIfAlreadyExistsWithSameTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException('File exists', () {
            fs.link(ns('/foo')).createSync(ns('/bar'));
          });
        });

        test('throwsIfAlreadyExistsWithDifferentTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException('File exists', () {
            fs.link(ns('/foo')).createSync(ns('/baz'));
          });
        });
      });

      group('update', () {
        test('returnsCovariantType', () async {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(await l.update(ns('/baz')), isLink);
        });

        test('throwsIfLinkDoesntExistAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo')).updateSync(ns('/bar'));
          });
        });

        test('throwsIfLinkDoesntExistViaTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo/bar')).updateSync(ns('/baz'));
          });
        });

        test('throwsIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Invalid argument', () {
            fs.link(ns('/foo')).updateSync(ns('/bar'));
          });
        });

        test('throwsIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          // TODO(tvolkert): Change this to just be 'Is a directory'
          // once Dart 1.22 is stable.
          String pattern = '(Invalid argument|Is a directory)';
          expectFileSystemException(matches(pattern), () {
            fs.link(ns('/foo')).updateSync(ns('/bar'));
          });
        });

        test('succeedsIfNewTargetSameAsOldTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/foo')).updateSync(ns('/bar'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/foo')).targetSync(), ns('/bar'));
        });

        test('succeedsIfNewTargetDifferentFromOldTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/foo')).updateSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/foo')).targetSync(), ns('/baz'));
        });
      });

      group('absolute', () {
        test('returnsCovariantType', () {
          expect(fs.link('foo').absolute, isLink);
        });

        test('returnsSamePathIfAlreadyAbsolute', () {
          expect(fs.link(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.link('foo').absolute.path, ns('/foo'));
        });
      });

      group('target', () {
        test('throwsIfLinkDoesntExistAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo')).targetSync();
          });
        });

        test('throwsIfLinkDoesntExistViaTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo/bar')).targetSync();
          });
        });

        test('throwsIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo')).targetSync();
          });
        });

        test('throwsIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo')).targetSync();
          });
        });

        test('succeedsIfTargetIsNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l.targetSync(), ns('/bar'));
        });

        test('succeedsIfTargetIsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          expect(l.targetSync(), ns('/bar'));
        });

        test('succeedsIfTargetIsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          expect(l.targetSync(), ns('/bar'));
        });

        test('succeedsIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(l.targetSync(), ns('/bar'));
        });
      });

      group('rename', () {
        test('returnsCovariantType', () async {
          Link l() => fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l().renameSync(ns('/bar')), isLink);
          expect(await l().rename(ns('/bar')), isLink);
        });

        test('throwsIfSourceDoesntExistAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceDoesntExistViaTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.link(ns('/foo/bar')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceIsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException('Invalid argument', () {
            fs.link(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceIsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException('Is a directory', () {
            fs.link(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsIfSourceIsLinkToFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          l.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfSourceIsLinkToNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          l.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfSourceIsLinkToDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          l.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfSourceIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          l.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfDestinationDoesntExistAtTail', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          l.renameSync(ns('/baz'));
          expect(fs.link(ns('/foo')).existsSync(), false);
          expect(fs.link(ns('/baz')).existsSync(), true);
        });

        test('throwsIfDestinationDoesntExistViaTraversal', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expectFileSystemException('No such file or directory', () {
            l.renameSync(ns('/baz/qux'));
          });
        });

        test('throwsIfDestinationExistsAsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/baz')).createSync();
          expectFileSystemException('Invalid argument', () {
            l.renameSync(ns('/baz'));
          });
        });

        test('throwsIfDestinationExistsAsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/baz')).createSync();
          expectFileSystemException('Invalid argument', () {
            l.renameSync(ns('/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/baz')).createSync();
          fs.link(ns('/qux')).createSync(ns('/baz'));
          l.renameSync(ns('/qux'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync(ns('/qux'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/qux')).targetSync(), ns('/bar'));
        });

        test('throwsIfDestinationExistsAsLinkToDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/baz')).createSync();
          fs.link(ns('/qux')).createSync(ns('/baz'));
          l.renameSync(ns('/qux'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync(ns('/qux'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/qux')).targetSync(), ns('/bar'));
        });

        test('succeedsIfDestinationExistsAsLinkToNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/baz')).createSync(ns('/qux'));
          l.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.NOT_FOUND);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });
      });
    });
  });
}
