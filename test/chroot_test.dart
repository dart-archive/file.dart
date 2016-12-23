@TestOn('vm')
import 'package:file/chroot.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('ChrootFileSystem', () {
    runCommonTests(
      () {
        MemoryFileSystem fs = new MemoryFileSystem();
        fs.directory('/tmp').createSync();
        return new ChrootFileSystem(fs, '/tmp');
      },
      skip: <String>[
        'File > open', // Not yet implemented in MemoryFileSystem

        // Bugs in MemoryFileSystem are blocking these from passing
        'File > create > succeedsIfAlreadyExistsAsLinkToFile',
        'File > rename > throwsIfTargetExistsAsDirectory',
        'File > rename > throwsIfTargetExistsAsLinkToDirectory',
        'File > rename > succeedsIfTargetExistsAsLinkToFile',
        'File > rename > throwsIfSourceExistsAsDirectory',
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

        // TODO: Fix bugs causing these tests to fail, and re-enable.
        'File > copy',
      ],
    );
  });
}
