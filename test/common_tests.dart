@TestOn("vm")
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:test/test.dart';

void runCommonTests(FileSystem fileSystemFactory()) {
  group('FileSystem', () {
    FileSystem fs;

    setUp(() async {
      fs = fileSystemFactory();
    });

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
    test('uri', () {});

    group('exists', () {
      test('falseWhenNotExists', () {});

      test('trueWhenExistsAsDirectory', () {});

      test('falseWhenExistsAsFile', () {});

      test('trueWhenExistsAsSymlinkToDirectory', () {});

      test('falseWhenExistsAsSymlinkToFile', () {});
    });

    group('create', () {
      test('succeedsWhenAlreadyExistsAsDirectory', () {});

      test('failsWhenAlreadyExistsAsFile', () {});

      test('succeedsWhenAlreadyExistsAsSymlinkToDirectory', () {});

      test('succeedsWhenTailDoesntExist', () {});

      test('failsWhenAncestorDoesntExistRecursiveFalse', () {});

      test('succeedsWhenAncestorDoesntExistRecursiveTrue', () {});
    });

    group('rename', () {
      test('succeedsWhenDestinationDoesntExist', () {});

      test('succeedsWhenDestinationIsEmptyDirectory', () {});

      test('failsWhenDestinationIsFile', () {});

      test('failsWhenDestinationParentFolderDoesntExist', () {});

      test('failsWhenDestinationIsNonEmptyDirectory', () {});

      test('failsWhenSourceDoesntExist', () {});

      test('failsWhenSourceIsFile', () {});

      test('failsWhenSourceIsSymlinkToDirectory', () {});

      test('failsWhenDestinationIsSymlinkToEmptyDirectory', () {});
    });

    group('delete', () {
      test('succeedsWhenEmptyDirectoryExistsAndRecursiveFalse', () {});

      test('succeedsWhenEmptyDirectoryExistsAndRecursiveTrue', () {});

      test('throwsWhenNonEmptyDirectoryExistsAndRecursiveFalse', () {});

      test('succeedsWhenNonEmptyDirectoryExistsAndRecursiveTrue', () {});

      test('throwsWhenDirectoryDoesntExistAndRecursiveFalse', () {});

      test('throwsWhenDirectoryDoesntExistAndRecursiveTrue', () {});

      test('succeedsWhenPathReferencesFileAndRecursiveTrue', () {});

      test('throwsWhenPathReferencesFileAndRecursiveFalse', () {});

      test('succeedsWhenPathReferencesLinkAndRecursiveTrue', () {});

      test('throwsWhenPathReferencesLinkAndRecursiveFalse', () {});
    });

    group('resolveSymbolicLinks', () {
      test('throwsIfLoopInLinkChain', () {});

      test('throwsPathNotFoundInTraversal', () {});

      test('throwsPathNotFoundAtTail', () {});

      test('resolvesRelativePathToCurrentDirectory', () {});

      test('handlesRelativeSymlinks', () {});

      test('handlesAbsoluteSymlinks', () {});

      test('handlesParentAndThisFolderReferences', () {});

      test('handlesBackToBackSlashesInPath', () {});

      test('handlesComplexPathWithMultipleSymlinks', () {});
    });

    group('absolute', () {
      test('returnsSameEntityWhenAlreadyAbsolute', () {});

      test('succeedsForRelativePaths', () {});
    });

    group('parent', () {
      test('returnsRootForRoot', () {});

      test('succeedsForNonRoot', () {});
    });

    group('createTemp', () {
      test('throwsIfDirectoryDoesntExist', () {});

      test('resolvesNameCollisions', () {});

      test('succeedsWithoutPrefix', () {});

      test('succeedsWithPrefix', () {});
    });

    group('list', () {
      test('returnsEmptyListForEmptyDirectory', () {});

      test('listsBasicContents', () {});

      test('throwsIfDirectoryDoesntExist', () {});

      test('returnsLinkObjectsIfFollowLinksFalse', () {});

      test('followsLinksIfFollowLinksTrue', () {});

      test('returnsLinkObjectsForSecondLinkEncounterIfFollowLinksTrue', () {});

      test('recurseIntoDirectoriesIfRecursiveTrue', () {});

      test('recurseIntoDirectorySymlinksIfFollowLinksTrueRecursiveTrue', () {});
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
    if (item is FileSystemException) {
      return (msg == null ||
          item.message.contains(msg) ||
          item.osError.message.contains(msg));
    }
    return false;
  }
}
