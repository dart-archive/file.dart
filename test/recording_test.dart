// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file/record_replay.dart';
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
        var manifest = recording.getManifest();
        expect(manifest, hasLength(4));
        expect(manifest[0], invokesMethod('directory'));
        expect(manifest[1], invokesMethod('createSync'));
        expect(manifest[2], invokesMethod('file'));
        expect(manifest[3], invokesMethod('writeAsStringSync'));
        expect(manifest[0]['result'], manifest[1]['object']);
        expect(manifest[2]['result'], manifest[3]['object']);
      });

      group('FileSystem', () {
        test('directory', () {
          fs.directory('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('directory').on('__fs__').withPositionalArguments(
                  ['/foo']).withResult(matches('_RecordingDirectory@[0-9]+')));
        });

        test('file', () {
          fs.file('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('file').on('__fs__').withPositionalArguments(
                  ['/foo']).withResult(matches('_RecordingFile@[0-9]+')));
        });

        test('link', () {
          fs.link('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('link').on('__fs__').withPositionalArguments(
                  ['/foo']).withResult(matches('_RecordingLink@[0-9]+')));
        });

        test('path', () {
          fs.path;
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              getsProperty('path').on('__fs__').withResult(<String, String>{
                'style': 'posix',
                'cwd': '/',
              }));
        });

        test('systemTempDirectory', () {
          fs.systemTempDirectory;
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              getsProperty('systemTempDirectory')
                  .on('__fs__')
                  .withResult(matches('_RecordingDirectory@[0-9]+')));
        });

        group('currentDirectory', () {
          test('get', () {
            fs.currentDirectory;
            var manifest = recording.getManifest();
            expect(manifest, hasLength(1));
            expect(
                manifest[0],
                getsProperty('currentDirectory')
                    .on('__fs__')
                    .withResult(matches('_RecordingDirectory@[0-9]+')));
          });

          test('setToString', () {
            delegate.directory('/foo').createSync();
            fs.currentDirectory = '/foo';
            var manifest = recording.getManifest();
            expect(manifest, hasLength(1));
            expect(manifest[0],
                setsProperty('currentDirectory').on('__fs__').toValue('/foo'));
          });

          test('setToRecordingDirectory', () {
            delegate.directory('/foo').createSync();
            fs.currentDirectory = fs.directory('/foo');
            var manifest = recording.getManifest();
            expect(manifest.length, greaterThanOrEqualTo(2));
            String directoryReference = manifest[0]['result'];
            expect(
                manifest,
                contains(setsProperty('currentDirectory')
                    .on('__fs__')
                    .toValue(directoryReference)));
          });

          test('setToNonRecordingDirectory', () {
            Directory dir = delegate.directory('/foo');
            dir.createSync();
            fs.currentDirectory = dir;
            var manifest = recording.getManifest();
            expect(manifest, hasLength(1));
            expect(
                manifest[0],
                setsProperty('currentDirectory')
                    .on('__fs__')
                    .toValue(matches(r'^.*Directory$')));
          });
        });

        test('stat', () async {
          delegate.file('/foo').createSync();
          await fs.stat('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
            manifest[0],
            invokesMethod('stat')
                .on('__fs__')
                .withPositionalArguments(['/foo']).withResult(allOf(
              contains('changed'),
              contains('modified'),
              contains('accessed'),
              contains('mode'),
              contains('modeString'),
              containsPair('size', 0),
              containsPair('type', 'FILE'),
            )),
          );
        });

        test('statSync', () {
          delegate.file('/foo').createSync();
          fs.statSync('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
            manifest[0],
            invokesMethod('statSync')
                .on('__fs__')
                .withPositionalArguments(['/foo']).withResult(allOf(
              contains('changed'),
              contains('modified'),
              contains('accessed'),
              contains('mode'),
              contains('modeString'),
              containsPair('size', 0),
              containsPair('type', 'FILE'),
            )),
          );
        });

        test('identical', () async {
          delegate.file('/foo').createSync();
          delegate.file('/bar').createSync();
          await fs.identical('/foo', '/bar');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('identical').on('__fs__').withPositionalArguments(
                  ['/foo', '/bar']).withResult(isFalse));
        });

        test('identicalSync', () {
          delegate.file('/foo').createSync();
          delegate.file('/bar').createSync();
          fs.identicalSync('/foo', '/bar');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('identicalSync')
                  .on('__fs__')
                  .withPositionalArguments(['/foo', '/bar']).withResult(
                      isFalse));
        });

        test('isWatchSupported', () {
          fs.isWatchSupported;
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              getsProperty('isWatchSupported')
                  .on('__fs__')
                  .withResult(isFalse));
        });

        test('type', () async {
          delegate.file('/foo').createSync();
          await fs.type('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('type')
                  .on('__fs__')
                  .withPositionalArguments(['/foo']).withResult('FILE'));
        });

        test('typeSync', () {
          delegate.file('/foo').createSync();
          fs.typeSync('/foo');
          var manifest = recording.getManifest();
          expect(manifest, hasLength(1));
          expect(
              manifest[0],
              invokesMethod('typeSync')
                  .on('__fs__')
                  .withPositionalArguments(['/foo']).withResult('FILE'));
        });
      });

      group('Directory', () {
        test('create', () async {
          await fs.directory('/foo').create();
          expect(
              recording.getManifest(),
              contains(invokesMethod('create')
                  .on(matches(r'^_RecordingDirectory@[0-9]+$'))
                  .withResult(matches(r'^_RecordingDirectory@[0-9]+$'))));
        });

        test('createSync', () {});
      });

      group('File', () {});

      group('Link', () {});
    });
  });
}

MethodInvocation invokesMethod(String name) => new MethodInvocation(name);
PropertyGet getsProperty(String name) => new PropertyGet(name);
PropertySet setsProperty(String name) => new PropertySet(name);

abstract class ManifestMatcher<T extends ManifestMatcher<T>> extends Matcher {
  final List<Matcher> _matchers = <Matcher>[];

  T on(dynamic object) {
    _matchers.add(containsPair('object', object));
    return this;
  }

  T withResult(dynamic result) {
    _matchers.add(containsPair('result', result));
    return this;
  }

  bool matches(item, Map<dynamic, dynamic> matchState) {
    for (var matcher in _matchers) {
      if (!matcher.matches(item, matchState)) {
        addStateInfo(matchState, {'matcher': matcher});
        return false;
      }
    }
    return true;
  }

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    var matcher = matchState['matcher'];
    matcher.describeMismatch(
        item, mismatchDescription, matchState['state'], verbose);
    return mismatchDescription;
  }

  Description describe(Description description) =>
      description.addAll('(', ' and ', ')', _matchers);
}

class MethodInvocation extends ManifestMatcher<MethodInvocation> {
  MethodInvocation(dynamic methodName) {
    _matchers.add(containsPair('type', 'invoke'));
    _matchers.add(containsPair('method', methodName));
  }

  MethodInvocation withPositionalArguments(List<dynamic> args) {
    _matchers.add(containsPair('positionalArguments', args));
    return this;
  }

  MethodInvocation withNamedArgument(String name, dynamic value) {
    _matchers.add(containsPair('namedArguments', containsPair(name, value)));
    return this;
  }
}

class PropertyGet extends ManifestMatcher<PropertyGet> {
  PropertyGet(dynamic propertyName) {
    _matchers.add(containsPair('type', 'get'));
    _matchers.add(containsPair('property', propertyName));
  }
}

class PropertySet extends ManifestMatcher<PropertySet> {
  PropertySet(dynamic propertyName) {
    withResult(null);
    _matchers.add(containsPair('type', 'set'));
    _matchers.add(containsPair('property', '$propertyName='));
  }

  PropertySet toValue(dynamic value) {
    _matchers.add(containsPair('value', value));
    return this;
  }
}
