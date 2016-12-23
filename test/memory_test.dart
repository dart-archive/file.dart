@TestOn('vm')
library file.test.local_test;

import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('MemoryFileSystem', () {
    runCommonTests(
      () => new MemoryFileSystem(),
      skip: <String>[
        'File > open', // Not yet implemented

        // TODO: Fix bugs causing these tests to fail, and re-enable.
        'File > create > succeedsIfAlreadyExistsAsLinkToFile',
        'File > rename > throwsIfTargetExistsAsDirectory',
        'File > rename > throwsIfTargetExistsAsLinkToDirectory',
        'File > rename > succeedsIfTargetExistsAsLinkToFile',
        'File > rename > throwsIfSourceExistsAsDirectory',
        'File > copy > throwsIfSourceExistsAsDirectory',
        'File > copy > succeedsIfSourceExistsAsLinkToFile',
        'File > length > throwsIfExistsAsDirectory',
        'File > length > succeedsIfExistsAsLinkToFile',
        'File > lastModified > throwsIfExistsAsDirectory',
        'File > openRead > throwsIfDoesntExist',
        'File > openRead > throwsIfExistsAsDirectory',
        'File > openRead > succeedsIfExistsAsLinkToFile',
        'File > openRead > respectsStartAndEndParameters',
        'File > openRead > throwsIfStartParameterIsNegative',
        'File > openRead > stopsAtEndOfFileIfEndParameterIsPastEndOfFile',
        'File > openRead > providesSingleSubscriptionStream',
        'File > openWrite > throwsIfExistsAsDirectory',
        'File > openWrite > throwsIfExistsAsLinkToDirectory',
        'File > openWrite > succeedsIfExistsAsLinkToFile',
        'File > openWrite > ioSink > throwsIfAddError',
        'File > openWrite > ioSink > throwsIfEncodingIsNullAndWriteObject',
        'File > openWrite > ioSink > addStream > blocksCallToFlushWhileStreamIsActive',
        'File > readAsBytes > throwsIfExistsAsDirectory',
        'File > readAsBytes > throwsIfExistsAsLinkToDirectory',
        'File > readAsBytes > succeedsIfExistsAsLinkToFile',
        'File > readAsString > throwsIfExistsAsDirectory',
        'File > readAsString > throwsIfExistsAsLinkToDirectory',
        'File > readAsString > succeedsIfExistsAsLinkToFile',
        'File > readAsLines > throwsIfExistsAsDirectory',
        'File > readAsLines > throwsIfExistsAsLinkToDirectory',
        'File > readAsLines > succeedsIfExistsAsLinkToFile',
        'File > readAsLines > returnsEmptyListForZeroByteFile',
        'File > writeAsBytes > throwsIfExistsAsDirectory',
        'File > writeAsBytes > throwsIfExistsAsLinkToDirectory',
        'File > writeAsBytes > succeedsIfExistsAsLinkToFile',
        'File > writeAsBytes > throwsIfFileModeRead',
        'File > writeAsString > throwsIfExistsAsDirectory',
        'File > writeAsString > throwsIfExistsAsLinkToDirectory',
        'File > writeAsString > succeedsIfExistsAsLinkToFile',
        'File > writeAsString > throwsIfFileModeRead',
        'File > delete > throwsIfExistsAsDirectoryAndRecursiveFalse',
        'File > delete > throwsIfExistsAsLinkToDirectoryAndRecursiveFalse',
      ],
    );
  });
}
