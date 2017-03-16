// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' as io;

import 'package:file/local.dart';
import 'package:file/src/testing/internal.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('LocalFileSystem', () {
    LocalFileSystem fs;
    io.Directory tmp;
    String cwd;

    setUp(() {
      fs = new LocalFileSystem();
      tmp = io.Directory.systemTemp.createTempSync('file_test_');
      tmp = new io.Directory(tmp.resolveSymbolicLinksSync());
      cwd = io.Directory.current.path;
      io.Directory.current = tmp;
    });

    tearDown(() {
      io.Directory.current = cwd;
      tmp.deleteSync(recursive: true);
    });

    setUpAll(() {
      if (io.Platform.isWindows) {
        // TODO(tvolkert): Remove once all more serious test failures are fixed
        // https://github.com/google/file.dart/issues/56
        ignoreOsErrorCodes = true;
      }
    });

    tearDownAll(() {
      ignoreOsErrorCodes = false;
    });

    Map<String, List<String>> skipOnPlatform = <String, List<String>>{
      'windows': <String>[
        'FileSystem > currentDirectory > throwsIfHasNonExistentPathInComplexChain',
        'FileSystem > currentDirectory > staysAtRootIfSetToParentOfRoot',
        'FileSystem > currentDirectory > resolvesLinksIfEncountered',
        'FileSystem > currentDirectory > succeedsIfSetToDirectoryLinkAtTail',
        'FileSystem > stat > isFileForLinkToFile',
        'FileSystem > type > isFileForLinkToFileAndFollowLinksTrue',
        'FileSystem > type > isNotFoundForLinkWithCircularReferenceAndFollowLinksTrue',
        'Directory > uri',
        'Directory > exists > falseIfExistsAsLinkToFile',
        'Directory > exists > falseIfNotFoundSegmentExistsThenIsBackedOut',
        'Directory > create > throwsIfAlreadyExistsAsLinkToFile',
        'Directory > rename > throwsIfDestinationIsNonEmptyDirectory',
        'Directory > rename > throwsIfDestinationIsLinkToEmptyDirectory',
        'Directory > delete > throwsIfPathReferencesLinkToFileAndRecursiveFalse',
        'Directory > resolveSymbolicLinks > throwsIfPathNotFoundInMiddleThenBackedOut',
        'Directory > createTemp > succeedsWithNestedPathPrefixThatExists',
        'Directory > list > followsLinksIfFollowLinksTrue',
        'Directory > list > returnsLinkObjectsForRecursiveLinkIfFollowLinksTrue',
        'File > uri',
        'File > create > succeedsIfAlreadyExistsAsLinkToFile',
        'File > create > succeedsIfAlreadyExistsAsLinkToNotFoundAtTail',
        'File > create > succeedsIfAlreadyExistsAsLinkToNotFoundInDifferentDirectory',
        'File > rename > succeedsIfDestinationExistsAsLinkToFile',
        'File > rename > succeedsIfDestinationExistsAsLinkToNotFound',
        'File > rename > succeedsIfSourceExistsAsLinkToFile',
        'File > copy > succeedsIfDestinationExistsAsLinkToFile',
        'File > copy > succeedsIfSourceExistsAsLinkToFile',
        'File > copy > succeedsIfSourceIsLinkToFileInDifferentDirectory',
        'File > copy > succeedsIfDestinationIsLinkToFileInDifferentDirectory',
        'File > openRead > succeedsIfExistsAsLinkToFile',
        'File > openWrite > succeedsIfExistsAsLinkToFile',
        'File > openWrite > ioSink > throwsIfEncodingIsNullAndWriteObject',
        'File > openWrite > ioSink > allowsChangingEncoding',
        'File > openWrite > ioSink > succeedsIfAddRawData',
        'File > openWrite > ioSink > succeedsIfWrite',
        'File > openWrite > ioSink > succeedsIfWriteAll',
        'File > openWrite > ioSink > succeedsIfWriteCharCode',
        'File > openWrite > ioSink > succeedsIfWriteln',
        'File > openWrite > ioSink > addStream > succeedsIfStreamProducesData',
        'File > openWrite > ioSink > addStream > blocksCallToAddWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWriteWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWriteAllWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWriteCharCodeWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWritelnWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToFlushWhileStreamIsActive',
        'File > readAsBytes > succeedsIfExistsAsLinkToFile',
        'File > readAsString > succeedsIfExistsAsLinkToFile',
        'File > writeAsBytes > succeedsIfExistsAsLinkToFile',
        'File > writeAsString > succeedsIfExistsAsLinkToFile',
        'File > stat > isFileIfExistsAsLinkToFile',
        'File > delete > succeedsIfExistsAsLinkToFileAndRecursiveFalse',
        'Link > uri > whenTargetIsDirectory',
        'Link > uri > whenTargetIsFile',
        'Link > uri > whenLinkDoesntExist',
        'Link > stat > isFileIfTargetIsFile',
        'Link > stat > isDirectoryIfTargetIsDirectory',
        'Link > create > succeedsIfLinkDoesntExistViaTraversalAndRecursiveTrue',
        'Link > rename > returnsCovariantType',
        'Link > rename > succeedsIfDestinationExistsAsLinkToFile',
        'Link > rename > throwsIfDestinationExistsAsLinkToDirectory',
        'Link > rename > succeedsIfDestinationExistsAsLinkToNotFound',

        // Fixed in SDK 1.23 (https://github.com/dart-lang/sdk/issues/28852)
        'File > open > WRITE > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
        'File > open > APPEND > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
        'File > open > WRITE_ONLY > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
        'File > open > WRITE_ONLY_APPEND > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
      ],
    };

    runCommonTests(
      () => fs,
      root: () => tmp.path,
      skip: <String>[
        // API doesn't exit in dart:io until Dart 1.23
        'File > lastAccessed',
        'File > setLastAccessed',
        'File > setLastModified',

        // https://github.com/dart-lang/sdk/issues/28170
        'File > create > throwsIfAlreadyExistsAsDirectory',
        'File > create > throwsIfAlreadyExistsAsLinkToDirectory',

        // https://github.com/dart-lang/sdk/issues/28171
        'File > rename > throwsIfDestinationExistsAsLinkToDirectory',

        // https://github.com/dart-lang/sdk/issues/28172
        'File > length > throwsIfExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28173
        'File > lastModified > throwsIfExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28174
        '.+ > RandomAccessFile > writeFromWithStart',
        '.+ > RandomAccessFile > writeFromWithStartAndEnd',

        // https://github.com/dart-lang/sdk/issues/28201
        'Link > delete > throwsIfLinkDoesntExistAtTail',
        'Link > delete > throwsIfLinkDoesntExistViaTraversal',
        'Link > update > throwsIfLinkDoesntExistAtTail',
        'Link > update > throwsIfLinkDoesntExistViaTraversal',

        // https://github.com/dart-lang/sdk/issues/28202
        'Link > rename > throwsIfSourceDoesntExistAtTail',
        'Link > rename > throwsIfSourceDoesntExistViaTraversal',

        // https://github.com/dart-lang/sdk/issues/28275
        'Link > rename > throwsIfDestinationExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28277
        'Link > rename > throwsIfDestinationExistsAsFile',
      ]..addAll(skipOnPlatform[io.Platform.operatingSystem] ?? <String>[]),
    );

    group('toString', () {
      test('File', () {
        expect(fs.file('/foo').toString(), "LocalFile: '/foo'");
      });

      test('Directory', () {
        expect(fs.directory('/foo').toString(), "LocalDirectory: '/foo'");
      });

      test('Link', () {
        expect(fs.link('/foo').toString(), "LocalLink: '/foo'");
      });
    });
  });
}
