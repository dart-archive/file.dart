// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file/record_replay.dart';
import 'package:file/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('RecordingFileSystem', () {
    RecordingFileSystem fs;
    MemoryFileSystem delegate;
    Recording recording;

    setUp(() {
      delegate = new MemoryFileSystem();
      fs = new RecordingFileSystem(
        delegate: delegate,
        destination: new MemoryFileSystem().directory('/tmp')..createSync(),
      );
      recording = fs.recording;
    });

    runCommonTests(
      () => fs,
      skip: <String>[
        'File > open', // Not yet implemented in MemoryFileSystem
      ],
    );

    group('recording', () {
      test('supportsMultipleActions', () {
        fs.directory('/foo').createSync();
        fs.file('/foo/bar').writeAsStringSync('BAR');
        var events = recording.events;
        expect(events, hasLength(4));
        expect(events[0], invokesMethod('directory'));
        expect(events[1], invokesMethod('createSync'));
        expect(events[2], invokesMethod('file'));
        expect(events[3], invokesMethod('writeAsStringSync'));
        expect(events[0].result, events[1].object);
        expect(events[2].result, events[3].object);
      });

      group('FileSystem', () {
        test('directory', () {
          fs.directory('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('directory')
                  .on(fs)
                  .withPositionalArguments(['/foo']).withResult(isDirectory));
        });

        test('file', () {
          fs.file('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('file')
                  .on(fs)
                  .withPositionalArguments(['/foo']).withResult(isFile));
        });

        test('link', () {
          fs.link('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('link')
                  .on(fs)
                  .withPositionalArguments(['/foo']).withResult(isLink));
        });

        test('path', () {
          fs.path;
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              getsProperty('path')
                  .on(fs)
                  .withResult(const isInstanceOf<p.Context>()));
        });

        test('systemTempDirectory', () {
          fs.systemTempDirectory;
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              getsProperty('systemTempDirectory')
                  .on(fs)
                  .withResult(isDirectory));
        });

        group('currentDirectory', () {
          test('get', () {
            fs.currentDirectory;
            var events = recording.events;
            expect(events, hasLength(1));
            expect(
                events[0],
                getsProperty('currentDirectory')
                    .on(fs)
                    .withResult(isDirectory));
          });

          test('setToString', () {
            delegate.directory('/foo').createSync();
            fs.currentDirectory = '/foo';
            var events = recording.events;
            expect(events, hasLength(1));
            expect(events[0],
                setsProperty('currentDirectory').on(fs).toValue('/foo'));
          });

          test('setToRecordingDirectory', () {
            delegate.directory('/foo').createSync();
            fs.currentDirectory = fs.directory('/foo');
            var events = recording.events;
            expect(events.length, greaterThanOrEqualTo(2));
            expect(events[0], invokesMethod().withResult(isDirectory));
            Directory directory = events[0].result;
            expect(
                events,
                contains(setsProperty('currentDirectory')
                    .on(fs)
                    .toValue(directory)));
          });

          test('setToNonRecordingDirectory', () {
            Directory dir = delegate.directory('/foo');
            dir.createSync();
            fs.currentDirectory = dir;
            var events = recording.events;
            expect(events, hasLength(1));
            expect(events[0],
                setsProperty('currentDirectory').on(fs).toValue(isDirectory));
          });
        });

        test('stat', () async {
          delegate.file('/foo').createSync();
          await fs.stat('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
            events[0],
            invokesMethod('stat')
                .on(fs)
                .withPositionalArguments(['/foo']).withResult(isFileStat),
          );
        });

        test('statSync', () {
          delegate.file('/foo').createSync();
          fs.statSync('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
            events[0],
            invokesMethod('statSync')
                .on(fs)
                .withPositionalArguments(['/foo']).withResult(isFileStat),
          );
        });

        test('identical', () async {
          delegate.file('/foo').createSync();
          delegate.file('/bar').createSync();
          await fs.identical('/foo', '/bar');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('identical').on(fs).withPositionalArguments(
                  ['/foo', '/bar']).withResult(isFalse));
        });

        test('identicalSync', () {
          delegate.file('/foo').createSync();
          delegate.file('/bar').createSync();
          fs.identicalSync('/foo', '/bar');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('identicalSync').on(fs).withPositionalArguments(
                  ['/foo', '/bar']).withResult(isFalse));
        });

        test('isWatchSupported', () {
          fs.isWatchSupported;
          var events = recording.events;
          expect(events, hasLength(1));
          expect(events[0],
              getsProperty('isWatchSupported').on(fs).withResult(isFalse));
        });

        test('type', () async {
          delegate.file('/foo').createSync();
          await fs.type('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('type').on(fs).withPositionalArguments(
                  ['/foo']).withResult(FileSystemEntityType.FILE));
        });

        test('typeSync', () {
          delegate.file('/foo').createSync();
          fs.typeSync('/foo');
          var events = recording.events;
          expect(events, hasLength(1));
          expect(
              events[0],
              invokesMethod('typeSync').on(fs).withPositionalArguments(
                  ['/foo']).withResult(FileSystemEntityType.FILE));
        });
      });

      group('Directory', () {
        test('create', () async {
          await fs.directory('/foo').create();
          expect(
              recording.events,
              contains(invokesMethod('create')
                  .on(isDirectory)
                  .withResult(isDirectory)));
        });

        test('createSync', () {});
      });

      group('File', () {});

      group('Link', () {});
    });
  });
}
