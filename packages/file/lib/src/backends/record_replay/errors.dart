// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'codecs.dart';
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
  String toString() {
    StringBuffer buf = StringBuffer();
    buf.write('No matching invocation found: ');
    buf.write(getSymbolName(invocation.memberName));
    if (invocation.isMethod) {
      buf.write('(');
      int i = 0;
      for (dynamic arg in invocation.positionalArguments) {
        buf.write(Error.safeToString(encode(arg)));
        if (i++ > 0) {
          buf.write(', ');
        }
      }
      invocation.namedArguments.forEach((Symbol name, dynamic value) {
        if (i++ > 0) {
          buf.write(', ');
        }
        buf.write('${getSymbolName(name)}: ${encode(value)}');
      });
      buf.write(')');
    } else if (invocation.isSetter) {
      buf.write(Error.safeToString(encode(invocation.positionalArguments[0])));
    }
    return buf.toString();
  }
}

/// Exception thrown during replay when an invocation recorded error, but we
/// were unable to find a type-specific converter to deserialize the recorded
/// error into a more specific exception type.
class InvocationException implements Exception {}
