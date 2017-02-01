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
  final List<InvocationEvent<dynamic>> _events = <InvocationEvent<dynamic>>[];

  /// Creates a new `MutableRecording` that will serialize its data to the
  /// specified [destination].
  MutableRecording(this.destination);

  @override
  final Directory destination;

  @override
  List<InvocationEvent<dynamic>> get events =>
      new List<InvocationEvent<dynamic>>.unmodifiable(_events);

  // TODO(tvolkert): Add ability to wait for all Future and Stream results
  @override
  Future<Null> flush() async {
    Directory dir = destination;
    String json = new JsonEncoder.withIndent('  ', encode).convert(_events);
    String filename = dir.fileSystem.path.join(dir.path, kManifestName);
    await dir.fileSystem.file(filename).writeAsString(json, flush: true);
  }

  /// Adds the specified [event] to this recording.
  void add(InvocationEvent<dynamic> event) => _events.add(event);
}
