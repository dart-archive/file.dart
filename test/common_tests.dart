@TestOn("vm")
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:test/test.dart';

void runCommonTests(FileSystem createFileSystem()) {
  group('common', () {
    FileSystem fs;

    setUp(() async {
      fs = createFileSystem();
    });

    group('FileSystem', () {
      group('currentDirectory', () {
        test('defaultsToRoot', () {
          expect(fs.currentDirectory.path, '/');
        });

        test('throwsIfSetToNonExistentPath', () {
          expectFileSystemException('No such file or directory', () {
            fs.currentDirectory = '/foo';
          });
        });

        test('succeedsWhenSetToValidStringPath', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = '/foo';
          expect(fs.currentDirectory.path, '/foo');
        });

        test('succeedsWhenSetToValidDirectory', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = new io.Directory('/foo');
          expect(fs.currentDirectory.path, '/foo');
        });

        test('throwsWhenArgumentIsNotStringOrDirectory', () {
          expect(() {
            fs.currentDirectory = 123;
          }, throwsArgumentError);
        });

        test('succeedsWhenSetToRelativePath', () {
          fs.directory('/foo/bar').createSync(recursive: true);
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, '/foo');
          fs.currentDirectory = 'bar';
          expect(fs.currentDirectory.path, '/foo/bar');
        });

        test('succeedsWhenSetToParentDirectory', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, '/foo');
          fs.currentDirectory = '..';
          expect(fs.currentDirectory.path, '/');
        });

        test('staysAtRootWhenSetToParentOfRoot', () {
          fs.currentDirectory = '../../..';
          expect(fs.currentDirectory.path, '/');
        });

        test('removesTrailingSlashWhenSet', () {
          fs.directory('/foo').createSync();
          fs.currentDirectory = '/foo/';
          expect(fs.currentDirectory.path, '/foo');
        });

        test('throwsWhenSetToFilePath', () {
          fs.file('/foo').createSync();
          expectFileSystemException('Not a directory', () {
            fs.currentDirectory = '/foo';
          });
        });

        test('resolvesSymlinksWhenEncountered', () {
          fs.link('/foo/bar/baz').createSync('/qux', recursive: true);
          fs.directory('/qux').createSync();
          fs.directory('/quux').createSync();
          fs.currentDirectory = '/foo/bar/baz/../quux/';
          expect(fs.currentDirectory.path, '/quux');
        });
      });

      group('stat', () {
        test('isNotFoundForPathToNonExistentEntityAtTail', () {
          FileStat stat = fs.statSync('/foo');
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundForPathToNonExistentEntityInTraversal', () {
          FileStat stat = fs.statSync('/foo/bar');
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });

        test('isDirectoryForDirectory', () {
          fs.directory('/foo').createSync();
          var stat = fs.statSync('/foo');
          expect(stat.type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileForFile', () {
          fs.file('/foo').createSync();
          var stat = fs.statSync('/foo');
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isFileForSymlinkToFile', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          var stat = fs.statSync('/bar');
          expect(stat.type, FileSystemEntityType.FILE);
        });

        test('isNotFoundForSymlinkWithCircularReference', () {
          fs.link('/foo').createSync('/bar');
          fs.link('/bar').createSync('/baz');
          fs.link('/baz').createSync('/foo');
          var stat = fs.statSync('/foo');
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
        });
      });

      group('identical', () {
        test('isTrueForIdenticalPathsToExistentFile', () {
          fs.file('/foo').createSync();
          expect(fs.identicalSync('/foo', '/foo'), true);
        });

        test('isFalseForDifferentPathsToDifferentFiles', () {
          fs.file('/foo').createSync();
          fs.file('/bar').createSync();
          expect(fs.identicalSync('/foo', '/bar'), false);
        });

        test('isTrueForDifferentPathsToSameFileViaLinkInTraversal', () {
          fs.file('/foo/file').createSync(recursive: true);
          fs.link('/bar').createSync('/foo');
          expect(fs.identicalSync('/foo/file', '/bar/file'), true);
        });

        test('isFalseForDifferentPathsToSameFileViaLinkAtTail', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          expect(fs.identicalSync('/foo', '/bar'), false);
        });

        test('throwsForDifferentPathsToNonExistentEntities', () {
          expectFileSystemException('No such file or directory', () {
            fs.identicalSync('/foo', '/bar');
          });
        });

        test('throwsForDifferentPathsToOneFileOneNonExistentEntity', () {
          fs.file('/foo').createSync();
          expectFileSystemException('No such file or directory', () {
            fs.identicalSync('/foo', '/bar');
          });
        });
      });

      group('type', () {
        test('isFileForFile', () {
          fs.file('/foo').createSync();
          var type = fs.typeSync('/foo');
          expect(type, FileSystemEntityType.FILE);
        });

        test('isDirectoryForDirectory', () {
          fs.directory('/foo').createSync();
          var type = fs.typeSync('/foo');
          expect(type, FileSystemEntityType.DIRECTORY);
        });

        test('isFileForSymlinkToFileAndFollowLinksTrue', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          var type = fs.typeSync('/bar');
          expect(type, FileSystemEntityType.FILE);
        });

        test('isLinkForSymlinkToFileAndFollowLinksFalse', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          var type = fs.typeSync('/bar', followLinks: false);
          expect(type, FileSystemEntityType.LINK);
        });

        test('isNotFoundForNoEntityAtTail', () {
          var type = fs.typeSync('/foo');
          expect(type, FileSystemEntityType.NOT_FOUND);
        });

        test('isNotFoundForNoDirectoryInTraversal', () {
          var type = fs.typeSync('/foo/bar/baz');
          expect(type, FileSystemEntityType.NOT_FOUND);
        });
      });
    });

    group('Directory', () {
      test('uri', () {
        expect(fs.directory('/foo').uri.toString(), 'file:///foo/');
        expect(fs.directory('foo').uri.toString(), 'foo/');
      });

      group('exists', () {
        test('falseWhenNotExists', () {
          expect(fs.directory('/foo').existsSync(), false);
          expect(fs.directory('foo').existsSync(), false);
        });

        test('trueWhenExistsAsDirectory', () {
          fs.directory('/foo').createSync();
          expect(fs.directory('/foo').existsSync(), true);
          expect(fs.directory('foo').existsSync(), true);
        });

        test('falseWhenExistsAsFile', () {
          fs.file('/foo').createSync();
          expect(fs.directory('/foo').existsSync(), false);
          expect(fs.directory('foo').existsSync(), false);
        });

        test('trueWhenExistsAsSymlinkToDirectory', () {
          fs.directory('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          expect(fs.directory('/bar').existsSync(), true);
          expect(fs.directory('bar').existsSync(), true);
        });

        test('falseWhenExistsAsSymlinkToFile', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          expect(fs.directory('/bar').existsSync(), false);
          expect(fs.directory('bar').existsSync(), false);
        });
      });

      group('create', () {
        test('succeedsWhenAlreadyExistsAsDirectory', () {
          fs.directory('/foo').createSync();
          fs.directory('/foo').createSync();
        });

        test('failsWhenAlreadyExistsAsFile', () {
          fs.file('/foo').createSync();
          expectFileSystemException('Creation failed', () {
            fs.directory('/foo').createSync();
          });
        });

        test('succeedsWhenAlreadyExistsAsSymlinkToDirectory', () {
          fs.directory('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          fs.directory('/bar').createSync();
        });

        test('succeedsWhenTailDoesntExist', () {
          expect(fs.directory('/').existsSync(), true);
          fs.directory('/foo').createSync();
          expect(fs.directory('/foo').existsSync(), true);
        });

        test('failsWhenAncestorDoesntExistRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo/bar').createSync();
          });
        });

        test('succeedsWhenAncestorDoesntExistRecursiveTrue', () {
          fs.directory('/foo/bar').createSync(recursive: true);
          expect(fs.directory('/foo').existsSync(), true);
          expect(fs.directory('/foo/bar').existsSync(), true);
        });
      });

      group('rename', () {
        test('succeedsWhenDestinationDoesntExist', () {
          var src = fs.directory('/foo')..createSync();
          var dest = src.renameSync('/bar');
          expect(dest.path, '/bar');
          expect(dest.existsSync(), true);
        });

        test('succeedsWhenDestinationIsEmptyDirectory', () {
          fs.directory('/bar').createSync();
          var src = fs.directory('/foo')..createSync();
          var dest = src.renameSync('/bar');
          expect(dest.existsSync(), true);
        });

        test('failsWhenDestinationIsFile', () {
          fs.file('/bar').createSync();
          var src = fs.directory('/foo')..createSync();
          expectFileSystemException('Not a directory', () {
            src.renameSync('/bar');
          });
        });

        test('failsWhenDestinationParentFolderDoesntExist', () {
          var src = fs.directory('/foo')..createSync();
          expectFileSystemException('No such file or directory', () {
            src.renameSync('/bar/baz');
          });
        });

        test('failsWhenDestinationIsNonEmptyDirectory', () {
          fs.file('/bar/baz').createSync(recursive: true);
          var src = fs.directory('/foo')..createSync();
          expectFileSystemException('Directory not empty', () {
            src.renameSync('/bar');
          });
        });

        test('failsWhenSourceDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo').renameSync('/bar');
          });
        });

        test('failsWhenSourceIsFile', () {
          fs.file('/foo').createSync();
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo').renameSync('/bar');
          });
        });

        test('succeedsWhenSourceIsSymlinkToDirectory', () {
          fs.directory('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          fs.directory('/bar').renameSync('/baz');
          expect(fs.directory('/foo').existsSync(), true);
          expect(fs.link('/bar').existsSync(), false);
          expect(fs.typeSync('/baz', followLinks: false),
              FileSystemEntityType.LINK);
          expect(fs.link('/baz').targetSync(), '/foo');
        });

        test('failsWhenDestinationIsSymlinkToEmptyDirectory', () {
          var src = fs.directory('/foo')..createSync();
          fs.directory('/bar').createSync();
          fs.link('/baz').createSync('/bar');
          expectFileSystemException('Not a directory', () {
            src.renameSync('/baz');
          });
        });
      });

      group('delete', () {
        test('succeedsWhenEmptyDirectoryExistsAndRecursiveFalse', () {
          var dir = fs.directory('/foo')..createSync();
          dir.deleteSync();
          expect(dir.existsSync(), false);
        });

        test('succeedsWhenEmptyDirectoryExistsAndRecursiveTrue', () {
          var dir = fs.directory('/foo')..createSync();
          dir.deleteSync(recursive: true);
          expect(dir.existsSync(), false);
        });

        test('throwsWhenNonEmptyDirectoryExistsAndRecursiveFalse', () {
          var dir = fs.directory('/foo')..createSync();
          fs.file('/foo/bar').createSync();
          expectFileSystemException('Directory not empty', () {
            dir.deleteSync();
          });
        });

        test('succeedsWhenNonEmptyDirectoryExistsAndRecursiveTrue', () {
          var dir = fs.directory('/foo')..createSync();
          fs.file('/foo/bar').createSync();
          dir.deleteSync(recursive: true);
          expect(fs.directory('/foo').existsSync(), false);
          expect(fs.file('/foo/bar').existsSync(), false);
        });

        test('throwsWhenDirectoryDoesntExistAndRecursiveFalse', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo').deleteSync();
          });
        });

        test('throwsWhenDirectoryDoesntExistAndRecursiveTrue', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo').deleteSync(recursive: true);
          });
        });

        test('succeedsWhenPathReferencesFileAndRecursiveTrue', () {
          fs.file('/foo').createSync();
          fs.directory('/foo').deleteSync(recursive: true);
          expect(fs.typeSync('/foo'), FileSystemEntityType.NOT_FOUND);
        });

        test('throwsWhenPathReferencesFileAndRecursiveFalse', () {
          fs.file('/foo').createSync();
          expectFileSystemException('Not a directory', () {
            fs.directory('/foo').deleteSync();
          });
        });

        test('succeedsWhenPathReferencesLinkToDirectoryAndRecursiveTrue', () {
          fs.directory('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          fs.directory('/bar').deleteSync(recursive: true);
          expect(fs.typeSync('/foo', followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync('/bar', followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsWhenPathReferencesLinkToDirectoryAndRecursiveFalse', () {
          fs.directory('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          fs.directory('/bar').deleteSync();
          expect(fs.typeSync('/foo', followLinks: false),
              FileSystemEntityType.DIRECTORY);
          expect(fs.typeSync('/bar', followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('succeedsWhenPathReferencesLinkToFileAndRecursiveTrue', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          fs.directory('/bar').deleteSync(recursive: true);
          expect(fs.typeSync('/foo', followLinks: false),
              FileSystemEntityType.FILE);
          expect(fs.typeSync('/bar', followLinks: false),
              FileSystemEntityType.NOT_FOUND);
        });

        test('failsWhenPathReferencesLinkToFileAndRecursiveFalse', () {
          fs.file('/foo').createSync();
          fs.link('/bar').createSync('/foo');
          expectFileSystemException('Not a directory', () {
            fs.directory('/bar').deleteSync();
          });
        });
      });

      group('resolveSymbolicLinks', () {
        test('succeedsForRootDirectory', () {
          expect(fs.directory('/').resolveSymbolicLinksSync(), '/');
        });

        test('throwsIfLoopInLinkChain', () {
          fs.link('/foo').createSync('/bar');
          fs.link('/bar').createSync('/baz');
          fs.link('/baz')..createSync('/foo');
          expectFileSystemException('Too many levels of symbolic links', () {
            fs.directory('/foo').resolveSymbolicLinksSync();
          });
        });

        test('throwsPathNotFoundInTraversal', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo/bar').resolveSymbolicLinksSync();
          });
        });

        test('throwsPathNotFoundAtTail', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/foo').resolveSymbolicLinksSync();
          });
        });

        test('resolvesRelativePathToCurrentDirectory', () {
          fs.directory('/foo/bar').createSync(recursive: true);
          fs.link('/foo/baz').createSync('/foo/bar');
          fs.currentDirectory = '/foo';
          expect(fs.directory('baz').resolveSymbolicLinksSync(), '/foo/bar');
        });

        test('handlesRelativeSymlinks', () {
          fs.directory('/foo/bar/baz').createSync(recursive: true);
          fs.link('/foo/qux').createSync('bar/baz');
          expect(fs.directory('/foo/qux').resolveSymbolicLinksSync(),
              '/foo/bar/baz');
        });

        test('handlesAbsoluteSymlinks', () {
          fs.directory('/foo').createSync();
          fs.directory('/bar/baz/qux').createSync(recursive: true);
          fs.link('/foo/quux').createSync('/bar/baz/qux');
          expect(fs.directory('/foo/quux').resolveSymbolicLinksSync(),
              '/bar/baz/qux');
        });

        test('handlesParentAndThisFolderReferences', () {
          fs.directory('/foo/bar/baz').createSync(recursive: true);
          fs.link('/foo/bar/baz/qux').createSync('../..');
          var resolved = fs
              .directory('/foo/./bar/baz/../baz/qux/bar')
              .resolveSymbolicLinksSync();
          expect(resolved, '/foo/bar');
        });

        test('handlesBackToBackSlashesInPath', () {
          fs.directory('/foo/bar/baz').createSync(recursive: true);
          expect(fs.directory('//foo/bar///baz').resolveSymbolicLinksSync(),
              '/foo/bar/baz');
        });

        test('handlesComplexPathWithMultipleSymlinks', () {
          fs.link('/foo/bar/baz').createSync('../../qux', recursive: true);
          fs.link('/qux').createSync('quux');
          fs.link('/quux/quuz').createSync('/foo', recursive: true);
          var resolved = fs
              .directory('/foo//bar/./baz/quuz/bar/..///bar/baz/')
              .resolveSymbolicLinksSync();
          expect(resolved, '/quux');
        });
      });

      group('absolute', () {
        test('returnsSamePathWhenAlreadyAbsolute', () {
          expect(fs.directory('/foo').absolute.path, '/foo');
        });

        test('succeedsForRelativePaths', () {
          expect(fs.directory('foo').absolute.path, '/foo');
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
            fs.directory('/foo').createTempSync();
          });
        });

        test('resolvesNameCollisions', () {
          fs.directory('/foo/bar').createSync(recursive: true);
          var tmp = fs.directory('/foo').createTempSync('bar');
          expect(tmp.path, allOf(isNot('/foo/bar'), startsWith('/foo/bar')));
        });

        test('succeedsWithoutPrefix', () {
          var dir = fs.directory('/foo')..createSync();
          expect(dir.createTempSync().path, startsWith('/foo/'));
        });

        test('succeedsWithPrefix', () {
          var dir = fs.directory('/foo')..createSync();
          expect(dir.createTempSync('bar').path, startsWith('/foo/bar'));
        });

        test('succeedsWithNestedPathPrefixThatExists', () {
          fs.directory('/foo/bar').createSync(recursive: true);
          var tmp = fs.directory('/foo').createTempSync('bar/baz');
          expect(tmp.path, startsWith('/foo/bar/baz'));
        });

        test('throwsWithNestedPathPrefixThatDoesntExist', () {
          var dir = fs.directory('/foo')..createSync();
          expectFileSystemException('No such file or directory', () {
            dir.createTempSync('bar/baz');
          });
        });
      });

      group('list', () {
        Directory dir;

        setUp(() {
          dir = fs.currentDirectory = fs.directory('/foo')..createSync();
          fs.file('bar').createSync();
          fs.file('baz/qux').createSync(recursive: true);
          fs.link('quux').createSync('baz/qux');
          fs.link('baz/quuz').createSync('../quux');
          fs.link('baz/grault').createSync('.');
          fs.currentDirectory = '/';
        });

        test('returnsEmptyListForEmptyDirectory', () {
          var empty = fs.directory('/bar')..createSync();
          expect(empty.listSync(), isEmpty);
        });

        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException('No such file or directory', () {
            fs.directory('/bar').listSync();
          });
        });

        test('returnsLinkObjectsIfFollowLinksFalse', () {
          var list = dir.listSync(followLinks: false);
          expect(list, hasLength(3));
          expect(list[0], allOf(isFile, hasPath('/foo/bar')));
          expect(list[1], allOf(isDirectory, hasPath('/foo/baz')));
          expect(list[2], allOf(isLink, hasPath('/foo/quux')));
        });

        test('followsLinksIfFollowLinksTrue', () {
          var list = dir.listSync();
          expect(list, hasLength(3));
          expect(list[0], allOf(isFile, hasPath('/foo/bar')));
          expect(list[1], allOf(isDirectory, hasPath('/foo/baz')));
          expect(list[2], allOf(isFile, hasPath('/foo/quux')));
        });

        test('returnsLinkObjectsForRecursiveLinkIfFollowLinksTrue', () {
          expect(
            dir.listSync(recursive: true),
            allOf(
              hasLength(9),
              allOf(
                contains(allOf(isFile, hasPath('/foo/bar'))),
                contains(allOf(isFile, hasPath('/foo/quux'))),
                contains(allOf(isFile, hasPath('/foo/baz/qux'))),
                contains(allOf(isFile, hasPath('/foo/baz/quuz'))),
                contains(allOf(isFile, hasPath('/foo/baz/grault/qux'))),
                contains(allOf(isFile, hasPath('/foo/baz/grault/quuz'))),
              ),
              allOf(
                contains(allOf(isDirectory, hasPath('/foo/baz'))),
                contains(allOf(isDirectory, hasPath('/foo/baz/grault'))),
              ),
              contains(allOf(isLink, hasPath('/foo/baz/grault/grault'))),
            ),
          );
        });

        test('recurseIntoDirectoriesIfRecursiveTrueFollowLinksFalse', () {
          expect(
            dir.listSync(recursive: true, followLinks: false),
            allOf(
              hasLength(6),
              contains(allOf(isFile, hasPath('/foo/bar'))),
              contains(allOf(isFile, hasPath('/foo/baz/qux'))),
              contains(allOf(isLink, hasPath('/foo/quux'))),
              contains(allOf(isLink, hasPath('/foo/baz/quuz'))),
              contains(allOf(isLink, hasPath('/foo/baz/grault'))),
              contains(allOf(isDirectory, hasPath('/foo/baz'))),
            ),
          );
        });

        test('childEntriesNotNormalized', () {
          dir = fs.directory('/bar/baz')..createSync(recursive: true);
          fs.file('/bar/baz/qux').createSync();
          var list = fs.directory('/bar//../bar/./baz').listSync();
          expect(list, hasLength(1));
          expect(list[0], allOf(isFile, hasPath('/bar//../bar/./baz/qux')));
        });

        test('symlinksToNotFoundAlwaysReturnedAsLinks', () {
          dir = fs.directory('/bar')..createSync();
          fs.link('/bar/baz').createSync('qux');
          for (bool followLinks in [true, false]) {
            var list = dir.listSync(followLinks: followLinks);
            expect(list, hasLength(1));
            expect(list[0], allOf(isLink, hasPath('/bar/baz')));
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
