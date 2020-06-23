// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common.dart';

/// Error thrown during replay when there is no matching invocation in the
/// recording.
class NoMatchingInvocationError extends Error {
  /// Creates a new `NoMatchingInvocationError` caused by the failure to replay
  /// the specified [invocation].
  NoMatchingInvocationError(this.invocation);

  /// The invocation that was unable to be replayed.
  final Invocation invocation;

  @override
  String toString() =>
      'No matching invocation found: ${describeInvocation(invocation)}';
}

/// Exception thrown during replay when an invocation recorded error, but we
/// were unable to find a type-specific converter to deserialize the recorded
/// error into a more specific exception type.
class InvocationException implements Exception {}
