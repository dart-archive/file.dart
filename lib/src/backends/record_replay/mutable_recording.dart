// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';

import 'common.dart';
import 'encoding.dart';
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
      new List<LiveInvocationEvent<dynamic>>.unmodifiable(_events);

  @override
  Future<Null> flush({Duration awaitPendingResults}) async {
    if (_flushing) {
      throw new StateError('Recording is already flushing');
    }
    _flushing = true;
    try {
      if (awaitPendingResults != null) {
        Iterable<Future<Null>> futures =
            _events.map((LiveInvocationEvent<dynamic> event) => event.done);
        await Future
            .wait<String>(futures)
            .timeout(awaitPendingResults, onTimeout: () {});
      }
      Directory dir = destination;
      String json = new JsonEncoder.withIndent('  ', encode).convert(_events);
      String filename = dir.fileSystem.path.join(dir.path, kManifestName);
      await dir.fileSystem.file(filename).writeAsString(json, flush: true);
    } finally {
      _flushing = false;
    }
  }

  /// Adds the specified [event] to this recording.
  void add(LiveInvocationEvent<dynamic> event) => _events.add(event);
}
