// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' as io;

import 'package:file/local.dart';
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

    Map<String, List<String>> skipOnPlatform = <String, List<String>>{
      'windows': <String>[
        'FileSystem > currentDirectory > throwsIfHasNonExistentPathInComplexChain',
        'FileSystem > currentDirectory > staysAtRootIfSetToParentOfRoot',
        'FileSystem > currentDirectory > throwsIfSetToFilePathSegmentAtTail',
        'FileSystem > currentDirectory > throwsIfSetToFilePathSegmentViaTraversal',
        'FileSystem > currentDirectory > resolvesLinksIfEncountered',
        'FileSystem > currentDirectory > succeedsIfSetToDirectoryLinkAtTail',
        'FileSystem > currentDirectory > throwsIfSetToLinkLoop',
        'FileSystem > stat > isFileForLinkToFile',
        'FileSystem > type > isFileForLinkToFileAndFollowLinksTrue',
        'FileSystem > type > isNotFoundForLinkWithCircularReferenceAndFollowLinksTrue',
        'Directory > uri',
        'Directory > exists > falseIfExistsAsLinkToFile',
        'Directory > exists > falseIfNotFoundSegmentExistsThenIsBackedOut',
        'Directory > create > throwsIfAlreadyExistsAsFile',
        'Directory > create > throwsIfAlreadyExistsAsLinkToFile',
        'Directory > create > throwsIfAlreadyExistsAsLinkToNotFoundViaTraversal',
        'Directory > create > throwsIfAncestorDoesntExistRecursiveFalse',
        'Directory > rename > throwsIfDestinationIsFile',
        'Directory > rename > throwsIfDestinationParentFolderDoesntExist',
        'Directory > rename > throwsIfDestinationIsNonEmptyDirectory',
        'Directory > rename > throwsIfSourceIsFile',
        'Directory > rename > throwsIfDestinationIsLinkToNotFound',
        'Directory > rename > throwsIfDestinationIsLinkToEmptyDirectory',
        'Directory > delete > throwsIfNonEmptyDirectoryExistsAndRecursiveFalse',
        'Directory > delete > throwsIfPathReferencesFileAndRecursiveFalse',
        'Directory > delete > throwsIfPathReferencesLinkToFileAndRecursiveFalse',
        'Directory > delete > throwsIfPathReferencesLinkToNotFoundAndRecursiveFalse',
        'Directory > resolveSymbolicLinks > throwsIfLoopInLinkChain',
        'Directory > resolveSymbolicLinks > throwsIfPathNotFoundInTraversal',
        'Directory > resolveSymbolicLinks > throwsIfPathNotFoundInMiddleThenBackedOut',
        'Directory > createTemp > throwsIfDirectoryDoesntExist',
        'Directory > createTemp > succeedsWithNestedPathPrefixThatExists',
        'Directory > createTemp > throwsWithNestedPathPrefixThatDoesntExist',
        'Directory > list > throwsIfDirectoryDoesntExist',
        'Directory > list > followsLinksIfFollowLinksTrue',
        'Directory > list > returnsLinkObjectsForRecursiveLinkIfFollowLinksTrue',
        'File > uri',
        'File > create > throwsIfAncestorDoesntExistRecursiveFalse',
        'File > create > succeedsIfAlreadyExistsAsLinkToFile',
        'File > create > succeedsIfAlreadyExistsAsLinkToNotFoundAtTail',
        'File > create > throwsIfAlreadyExistsAsLinkToNotFoundViaTraversal',
        'File > create > succeedsIfAlreadyExistsAsLinkToNotFoundInDifferentDirectory',
        'File > rename > throwsIfDestinationDoesntExistViaTraversal',
        'File > rename > throwsIfDestinationExistsAsDirectory',
        'File > rename > succeedsIfDestinationExistsAsLinkToFile',
        'File > rename > succeedsIfDestinationExistsAsLinkToNotFound',
        'File > rename > throwsIfSourceExistsAsDirectory',
        'File > rename > succeedsIfSourceExistsAsLinkToFile',
        'File > rename > throwsIfSourceExistsAsLinkToDirectory',
        'File > copy > throwsIfDestinationDoesntExistViaTraversal',
        'File > copy > throwsIfDestinationExistsAsDirectory',
        'File > copy > succeedsIfDestinationExistsAsLinkToFile',
        'File > copy > throwsIfDestinationExistsAsLinkToDirectory',
        'File > copy > throwsIfSourceExistsAsDirectory',
        'File > copy > succeedsIfSourceExistsAsLinkToFile',
        'File > copy > succeedsIfSourceIsLinkToFileInDifferentDirectory',
        'File > copy > succeedsIfDestinationIsLinkToFileInDifferentDirectory',
        'File > open > READ > throwsIfDoesntExistViaTraversal',
        'File > open > READ > RandomAccessFile > throwsIfWriteByte',
        'File > open > READ > RandomAccessFile > throwsIfWriteFrom',
        'File > open > READ > RandomAccessFile > throwsIfWriteString',
        'File > open > READ > RandomAccessFile > position > throwsIfSetToNegativeNumber',
        'File > open > READ > RandomAccessFile > throwsIfTruncate',
        'File > open > WRITE > throwsIfDoesntExistViaTraversal',
        'File > open > WRITE > RandomAccessFile > position > throwsIfSetToNegativeNumber',
        'File > open > APPEND > throwsIfDoesntExistViaTraversal',
        'File > open > APPEND > RandomAccessFile > position > throwsIfSetToNegativeNumber',
        'File > open > WRITE_ONLY > throwsIfDoesntExistViaTraversal',
        'File > open > WRITE_ONLY > RandomAccessFile > throwsIfReadByte',
        'File > open > WRITE_ONLY > RandomAccessFile > throwsIfRead',
        'File > open > WRITE_ONLY > RandomAccessFile > throwsIfReadInto',
        'File > open > WRITE_ONLY > RandomAccessFile > position > throwsIfSetToNegativeNumber',
        'File > open > WRITE_ONLY_APPEND > throwsIfDoesntExistViaTraversal',
        'File > open > WRITE_ONLY_APPEND > RandomAccessFile > throwsIfReadByte',
        'File > open > WRITE_ONLY_APPEND > RandomAccessFile > throwsIfRead',
        'File > open > WRITE_ONLY_APPEND > RandomAccessFile > throwsIfReadInto',
        'File > open > WRITE_ONLY_APPEND > RandomAccessFile > position > throwsIfSetToNegativeNumber',
        'File > openRead > throwsIfExistsAsDirectory',
        'File > openRead > succeedsIfExistsAsLinkToFile',
        'File > openWrite > throwsIfExistsAsDirectory',
        'File > openWrite > throwsIfExistsAsLinkToDirectory',
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
        'File > readAsBytes > throwsIfExistsAsDirectory',
        'File > readAsBytes > throwsIfExistsAsLinkToDirectory',
        'File > readAsBytes > succeedsIfExistsAsLinkToFile',
        'File > readAsString > throwsIfExistsAsDirectory',
        'File > readAsString > throwsIfExistsAsLinkToDirectory',
        'File > readAsString > succeedsIfExistsAsLinkToFile',
        'File > readAsLines > throwsIfExistsAsDirectory',
        'File > readAsLines > throwsIfExistsAsLinkToDirectory',
        'File > writeAsBytes > throwsIfExistsAsDirectory',
        'File > writeAsBytes > throwsIfExistsAsLinkToDirectory',
        'File > writeAsBytes > succeedsIfExistsAsLinkToFile',
        'File > writeAsBytes > throwsIfFileModeRead',
        'File > writeAsString > throwsIfExistsAsDirectory',
        'File > writeAsString > throwsIfExistsAsLinkToDirectory',
        'File > writeAsString > succeedsIfExistsAsLinkToFile',
        'File > writeAsString > throwsIfFileModeRead',
        'File > stat > isFileIfExistsAsLinkToFile',
        'File > delete > throwsIfExistsAsDirectoryAndRecursiveFalse',
        'File > delete > succeedsIfExistsAsLinkToFileAndRecursiveFalse',
        'File > delete > throwsIfExistsAsLinkToDirectoryAndRecursiveFalse',
        'Link > uri > whenTargetIsDirectory',
        'Link > uri > whenTargetIsFile',
        'Link > uri > whenLinkDoesntExist',
        'Link > stat > isFileIfTargetIsFile',
        'Link > stat > isDirectoryIfTargetIsDirectory',
        'Link > delete > throwsIfPathReferencesFileAndRecursiveFalse',
        'Link > delete > throwsIfPathReferencesDirectoryAndRecursiveFalse',
        'Link > create > throwsIfLinkDoesntExistViaTraversalAndRecursiveFalse',
        'Link > create > succeedsIfLinkDoesntExistViaTraversalAndRecursiveTrue',
        'Link > create > throwsIfAlreadyExistsAsFile',
        'Link > create > throwsIfAlreadyExistsAsDirectory',
        'Link > create > throwsIfAlreadyExistsWithSameTarget',
        'Link > create > throwsIfAlreadyExistsWithDifferentTarget',
        'Link > update > throwsIfPathReferencesFile',
        'Link > update > throwsIfPathReferencesDirectory',
        'Link > target > throwsIfLinkDoesntExistViaTraversal',
        'Link > target > throwsIfPathReferencesFile',
        'Link > target > throwsIfPathReferencesDirectory',
        'Link > rename > returnsCovariantType',
        'Link > rename > throwsIfSourceIsFile',
        'Link > rename > throwsIfSourceIsDirectory',
        'Link > rename > throwsIfDestinationDoesntExistViaTraversal',
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
