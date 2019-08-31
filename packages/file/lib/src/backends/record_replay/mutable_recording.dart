// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:intl/intl.dart';

import 'codecs.dart';
import 'common.dart';
import 'events.dart';
import 'recording.dart';

/// A mutable live recording.
class MutableRecording implements LiveRecording {
  /// Creates a new `MutableRecording` that will serialize its data to the
  /// specified [destination].
  MutableRecording(this.destination);

  final List<LiveInvocationEvent<dynamic>> _events =
      <LiveInvocationEvent<dynamic>>[];

  bool _flushing = false;

  @override
  final Directory destination;

  @override
  List<LiveInvocationEvent<dynamic>> get events =>
      List<LiveInvocationEvent<dynamic>>.unmodifiable(_events);

  @override
  Future<void> flush({Duration pendingResultTimeout}) async {
    if (_flushing) {
      throw StateError('Recording is already flushing');
    }
    _flushing = true;
    try {
      Iterable<Future<void>> futures =
          _events.map((LiveInvocationEvent<dynamic> event) => event.done);
      Future<List<void>> results = Future.wait<void>(futures);
      if (pendingResultTimeout != null) {
        results = results.timeout(pendingResultTimeout, onTimeout: () {
          return null;
        });
      }
      await results;
      Directory dir = destination;
      String json = const JsonEncoder.withIndent('  ').convert(encode(_events));
      String filename = dir.fileSystem.path.join(dir.path, kManifestName);
      await dir.fileSystem.file(filename).writeAsString(json, flush: true);
    } finally {
      _flushing = false;
    }
  }

  /// Returns a new file for use with this recording.
  ///
  /// The file name will combine the specified [name] with [newUid] to ensure
  /// that its name is unique among all recording files.
  ///
  /// It is up to the caller to create the file - it will not exist in the
  /// file system when it is returned from this method.
  File newFile(String name) {
    String basename = '${NumberFormat('000').format(newUid())}.$name';
    String dirname = destination.path;
    String path = destination.fileSystem.path.join(dirname, basename);
    return destination.fileSystem.file(path);
  }

  /// Adds the specified [event] to this recording.
  void add(LiveInvocationEvent<dynamic> event) => _events.add(event);
}
