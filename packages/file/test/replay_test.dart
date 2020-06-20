// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file/record_replay.dart';
import 'package:file_testing/file_testing.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'common_tests.dart';
import 'record_replay_matchers.dart';

void main() {
  group('Replay', () {
    RecordingFileSystem recordingFileSystem;
    MemoryFileSystem memoryFileSystem;
    LiveRecording recording;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      recordingFileSystem = RecordingFileSystem(
        delegate: memoryFileSystem,
        destination: MemoryFileSystem().directory('/tmp')..createSync(),
      );
      recording = recordingFileSystem.recording;
    });

    /// Creates a new [ReplayFileSystem] that will replay a recording of the
    /// events that have been recorded within [recordingFileSystem] thus far.
    Future<ReplayFileSystem> replay() async {
      await recording.flush();
      return ReplayFileSystem(recording: recording.destination);
    }

    runCommonTests(
      () => recordingFileSystem,
      replay: replay,
      skip: <String>[
        // ReplayFileSystem does not yet support futures & streams that throw
        'File > openRead > throws.*',
        'File > openWrite > throws.*',
        'File > openWrite > ioSink > throwsIfAddError',
        'File > openWrite > ioSink > addStream > blocks.*',
        'File > openWrite > ioSink > ignoresDataWrittenAfterClose',

        'File > open', // Not yet implemented in MemoryFileSystem
      ],
    );

    group('ReplayFileSystem', () {
      test('directory', () async {
        recordingFileSystem.directory('/foo');
        ReplayFileSystem fs = await replay();
        Directory dir = fs.directory('/foo');
        expect(dir, isDirectory);
        expect(() => dir.path, throwsNoMatchingInvocationError);
        expect(() => fs.directory('/foo'), throwsNoMatchingInvocationError);
      });

      test('file', () async {
        recordingFileSystem.file('/foo');
        ReplayFileSystem fs = await replay();
        expect(fs.file('/foo'), isFile);
        expect(() => fs.file('/foo'), throwsNoMatchingInvocationError);
      });

      test('link', () async {
        recordingFileSystem.link('/foo');
        ReplayFileSystem fs = await replay();
        expect(fs.link('/foo'), isLink);
        expect(() => fs.link('/foo'), throwsNoMatchingInvocationError);
      });

      test('path', () async {
        path.Context context = recordingFileSystem.path;
        ReplayFileSystem fs = await replay();
        path.Context replayContext = fs.path;
        expect(() => fs.path, throwsNoMatchingInvocationError);
        expect(replayContext.style, context.style);
        expect(replayContext.current, context.current);
      });

      test('systemTempDirectory', () async {
        recordingFileSystem.systemTempDirectory;
        ReplayFileSystem fs = await replay();
        Directory dir = fs.systemTempDirectory;
        expect(dir, isDirectory);
        expect(() => dir.path, throwsNoMatchingInvocationError);
        expect(() => fs.systemTempDirectory, throwsNoMatchingInvocationError);
      });

      group('currentDirectory', () {
        test('get', () async {
          recordingFileSystem.currentDirectory;
          ReplayFileSystem fs = await replay();
          Directory dir = fs.currentDirectory;
          expect(dir, isDirectory);
          expect(() => dir.path, throwsNoMatchingInvocationError);
          expect(() => fs.currentDirectory, throwsNoMatchingInvocationError);
        });

        test('setToString', () async {
          memoryFileSystem.directory('/foo').createSync();
          recordingFileSystem.currentDirectory = '/foo';
          ReplayFileSystem fs = await replay();
          expect(() => fs.currentDirectory = '/bar',
              throwsNoMatchingInvocationError);
          fs.currentDirectory = '/foo';
          expect(() => fs.currentDirectory = '/foo',
              throwsNoMatchingInvocationError);
        });

        test('setToDirectory', () async {
          Directory dir = await recordingFileSystem.directory('/foo').create();
          recordingFileSystem.currentDirectory = dir;
          ReplayFileSystem fs = await replay();
          Directory replayDir = fs.directory('/foo');
          expect(() => fs.directory('/foo'), throwsNoMatchingInvocationError);
          fs.currentDirectory = replayDir;
          expect(() => fs.currentDirectory = replayDir,
              throwsNoMatchingInvocationError);
        });
      });

      test('stat', () async {
        FileStat stat = await recordingFileSystem.stat('/');
        ReplayFileSystem fs = await replay();
        Future<FileStat> replayStatFuture = fs.stat('/');
        expect(() => fs.stat('/'), throwsNoMatchingInvocationError);
        expect(replayStatFuture, isFuture);
        FileStat replayStat = await replayStatFuture;
        expect(replayStat.accessed, stat.accessed);
        expect(replayStat.changed, stat.changed);
        expect(replayStat.modified, stat.modified);
        expect(replayStat.mode, stat.mode);
        expect(replayStat.type, stat.type);
        expect(replayStat.size, stat.size);
        expect(replayStat.modeString(), stat.modeString());
      });

      test('statSync', () async {
        FileStat stat = recordingFileSystem.statSync('/');
        ReplayFileSystem fs = await replay();
        FileStat replayStat = fs.statSync('/');
        expect(() => fs.statSync('/'), throwsNoMatchingInvocationError);
        expect(replayStat.accessed, stat.accessed);
        expect(replayStat.changed, stat.changed);
        expect(replayStat.modified, stat.modified);
        expect(replayStat.mode, stat.mode);
        expect(replayStat.type, stat.type);
        expect(replayStat.size, stat.size);
        expect(replayStat.modeString(), stat.modeString());
      });

      test('identical', () async {
        memoryFileSystem.directory('/foo').createSync();
        bool identical = await recordingFileSystem.identical('/', '/foo');
        ReplayFileSystem fs = await replay();
        Future<bool> replayIdenticalFuture = fs.identical('/', '/foo');
        expect(
            () => fs.identical('/', '/foo'), throwsNoMatchingInvocationError);
        expect(replayIdenticalFuture, isFuture);
        expect(await replayIdenticalFuture, identical);
      });

      test('identicalSync', () async {
        memoryFileSystem.directory('/foo').createSync();
        bool identical = recordingFileSystem.identicalSync('/', '/foo');
        ReplayFileSystem fs = await replay();
        bool replayIdentical = fs.identicalSync('/', '/foo');
        expect(() => fs.identicalSync('/', '/foo'),
            throwsNoMatchingInvocationError);
        expect(replayIdentical, identical);
      });

      test('isWatchSupported', () async {
        bool isWatchSupported = recordingFileSystem.isWatchSupported;
        ReplayFileSystem fs = await replay();
        expect(fs.isWatchSupported, isWatchSupported);
        expect(() => fs.isWatchSupported, throwsNoMatchingInvocationError);
      });

      test('type', () async {
        FileSystemEntityType type = await recordingFileSystem.type('/');
        ReplayFileSystem fs = await replay();
        Future<FileSystemEntityType> replayTypeFuture = fs.type('/');
        expect(() => fs.type('/'), throwsNoMatchingInvocationError);
        expect(replayTypeFuture, isFuture);
        expect(await replayTypeFuture, type);
      });

      test('typeSync', () async {
        FileSystemEntityType type = recordingFileSystem.typeSync('/');
        ReplayFileSystem fs = await replay();
        FileSystemEntityType replayType = fs.typeSync('/');
        expect(() => fs.typeSync('/'), throwsNoMatchingInvocationError);
        expect(replayType, type);
      });
    });
  });
}

/// Successfully matches against an instance of [Future].
const Matcher isFuture = TypeMatcher<Future<dynamic>>();
