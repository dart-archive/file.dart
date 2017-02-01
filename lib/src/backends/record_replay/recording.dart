// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import 'events.dart';

/// A recording of a series of invocations on a [FileSystem] and its associated
/// objects (`File`, `Directory`, `IOSink`, etc).
///
/// Recorded invocations include property getters, property setters, and
/// standard method invocations. A recording exists as an ordered series of
/// "invocation events".
abstract class Recording {
  /// The invocation events that have been captured by this recording.
  List<InvocationEvent<dynamic>> get events;
}

/// An [Recording] in progress that can be serialized to disk for later use
/// in `ReplayFileSystem`.
///
/// Live recordings exist only in memory until [flush] is called.
// TODO(tvolkert): Link to ReplayFileSystem in docs once it's implemented
abstract class LiveRecording extends Recording {
  /// The directory in which recording files will be stored.
  ///
  /// These contents of these files, while human readable, do not constitute an
  /// API or contract. Their makeup and structure is subject to change from
  /// one version of `package:file` to the next.
  Directory get destination;

  /// Writes this recording to disk.
  ///
  /// Live recordings will *not* call `flush` on themselves, so it is up to
  /// callers to call this method when they wish to write the recording to disk.
  ///
  /// Returns a future that completes once the recording has been fully written
  /// to disk.
  Future<Null> flush();
}
