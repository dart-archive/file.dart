// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' as io;

import 'package:file/chroot.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('ChrootFileSystem', () {
    ChrootFileSystem createMemoryBackedChrootFileSystem() {
      MemoryFileSystem fs = MemoryFileSystem();
      fs.directory('/tmp').createSync();
      return ChrootFileSystem(fs, '/tmp');
    }

    group('memoryBacked', () {
      runCommonTests(
        createMemoryBackedChrootFileSystem,
        skip: <String>[
          'File > open', // Not yet implemented in MemoryFileSystem
        ],
      );
    });

    group('localBacked', () {
      ChrootFileSystem fs;
      io.Directory tmp;

      setUp(() {
        tmp = io.Directory.systemTemp.createTempSync('file_test_');
        tmp = io.Directory(tmp.resolveSymbolicLinksSync());
        fs = ChrootFileSystem(const LocalFileSystem(), tmp.path);
      });

      tearDown(() {
        tmp.deleteSync(recursive: true);
      });

      runCommonTests(
        () => fs,
        skip: <String>[
          // https://github.com/dart-lang/sdk/issues/28275
          'Link > rename > throwsIfDestinationExistsAsDirectory',

          // https://github.com/dart-lang/sdk/issues/28277
          'Link > rename > throwsIfDestinationExistsAsFile',
        ],
      );
    }, skip: io.Platform.isWindows);

    group('chrootSpecific', () {
      ChrootFileSystem fs;
      MemoryFileSystem mem;

      setUp(() {
        fs = createMemoryBackedChrootFileSystem();
        mem = fs.delegate;
      });

      group('FileSystem', () {
        group('currentDirectory', () {
          test('staysInJailIfSetToParentOfRoot', () {
            fs.currentDirectory = '../../../..';
            fs.file('foo').createSync();
            expect(mem.file('/tmp/foo').existsSync(), isTrue);
          });

          test('throwsIfSetToSymlinkToDirectoryOutsideJail', () {
            mem.directory('/bar').createSync();
            mem.link('/tmp/foo').createSync('/bar');
            expectFileSystemException(ErrorCodes.ENOENT, () {
              fs.currentDirectory = '/foo';
            });
          });
        });

        group('stat', () {
          test('isNotFoundForJailbreakPath', () {
            mem.file('/foo').createSync();
            expect(fs.statSync('../foo').type, FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkWithJailbreakTarget', () {
            mem.file('/foo').createSync();
            mem.link('/tmp/bar').createSync('/foo');
            expect(mem.statSync('/tmp/bar').type, FileSystemEntityType.file);
            expect(fs.statSync('/bar').type, FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkToOutsideAndBackInsideJail', () {
            mem.file('/tmp/bar').createSync();
            mem.link('/foo').createSync('/tmp/bar');
            mem.link('/tmp/baz').createSync('/foo');
            expect(mem.statSync('/tmp/baz').type, FileSystemEntityType.file);
            expect(fs.statSync('/baz').type, FileSystemEntityType.notFound);
          });
        });

        group('type', () {
          test('isNotFoundForJailbreakPath', () {
            mem.file('/foo').createSync();
            expect(fs.typeSync('../foo'), FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkWithJailbreakTarget', () {
            mem.file('/foo').createSync();
            mem.link('/tmp/bar').createSync('/foo');
            expect(mem.typeSync('/tmp/bar'), FileSystemEntityType.file);
            expect(fs.typeSync('/bar'), FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkToOutsideAndBackInsideJail', () {
            mem.file('/tmp/bar').createSync();
            mem.link('/foo').createSync('/tmp/bar');
            mem.link('/tmp/baz').createSync('/foo');
            expect(mem.typeSync('/tmp/baz'), FileSystemEntityType.file);
            expect(fs.typeSync('/baz'), FileSystemEntityType.notFound);
          });
        });
      });

      group('File', () {
        group('delegate', () {
          test('referencesRootEntityForJailbreakPath', () {
            mem.file('/foo').createSync();
            dynamic f = fs.file('../foo');
            expect(f.delegate.path, '/tmp/foo');
          });
        });

        group('create', () {
          test('createsAtRootIfPathReferencesJailbreakFile', () {
            fs.file('../foo').createSync();
            expect(mem.file('/foo').existsSync(), isFalse);
            expect(mem.file('/tmp/foo').existsSync(), isTrue);
          });
        });

        group('copy', () {
          test('copiesToRootDirectoryIfDestinationIsJailbreakPath', () {
            File f = fs.file('/foo')..createSync();
            f.copySync('../bar');
            expect(mem.file('/bar').existsSync(), isFalse);
            expect(mem.file('/tmp/bar').existsSync(), isTrue);
          });
        });
      });

      group('Link', () {
        group('target', () {
          test('chrootAndDelegateFileSystemsReturnSameValue', () {
            mem.file('/foo').createSync();
            mem.link('/tmp/bar').createSync('/foo');
            mem.link('/tmp/baz').createSync('../foo');
            expect(mem.link('/tmp/bar').targetSync(), '/foo');
            expect(fs.link('/bar').targetSync(), '/foo');
            expect(mem.link('/tmp/baz').targetSync(), '../foo');
            expect(fs.link('/baz').targetSync(), '../foo');
          });
        });
      });
    });
  });
}
