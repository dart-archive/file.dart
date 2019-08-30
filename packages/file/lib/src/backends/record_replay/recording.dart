// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import 'events.dart';
import 'replay_file_system.dart';

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
/// in [ReplayFileSystem].
///
/// Live recordings exist only in memory until [flush] is called.
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
  /// callers to call this method when they wish to write the recording to
  /// disk.
  ///
  /// If [pendingResultTimeout] is specified, this will wait the specified
  /// duration for any results that are `Future`s or `Stream`s to complete
  /// before serializing the recording to disk. Futures that don't complete
  /// within the specified duration will have their results recorded as `null`,
  /// and streams that don't send a "done" event within the specified duration
  /// will have their results recorded as the list of events the stream has
  /// fired thus far.
  ///
  /// If [pendingResultTimeout] is not specified (or is `null`), this will wait
  /// indefinitely for for any results that are `Future`s or `Stream`s to
  /// complete before serializing the recording to disk.
  ///
  /// Throws a [StateError] if a flush is already in progress.
  ///
  /// Returns a future that completes once the recording has been fully written
  /// to disk.
  Future<void> flush({Duration pendingResultTimeout});
}
