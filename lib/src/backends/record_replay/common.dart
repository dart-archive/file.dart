// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'events.dart';

/// Encoded value of the file system in a recording.
const String kFileSystemEncodedValue = '__fs__';

/// The name of the recording manifest file.
const String kManifestName = 'MANIFEST.txt';

/// The key in a serialized [InvocationEvent] map that is used to store the
/// type of invocation.
///
/// See also:
///   - [kGetType]
///   - [kSetType]
///   - [kInvokeType]
const String kManifestTypeKey = 'type';

/// The key in a serialized [InvocationEvent] map that is used to store the
/// target of the invocation.
const String kManifestObjectKey = 'object';

/// The key in a serialized [InvocationEvent] map that is used to store the
/// result (return value) of the invocation.
const String kManifestResultKey = 'result';

/// The key in a serialized [InvocationEvent] map that is used to store the
/// timestamp of the invocation.
const String kManifestTimestampKey = 'timestamp';

/// The key in a serialized [PropertyGetEvent] or [PropertySetEvent] map that
/// is used to store the property that was accessed or mutated.
const String kManifestPropertyKey = 'property';

/// The key in a serialized [PropertySetEvent] map that is used to store the
/// value to which the property was set.
const String kManifestValueKey = 'value';

/// The key in a serialized [MethodEvent] map that is used to store the name of
/// the method that was invoked.
const String kManifestMethodKey = 'method';

/// The key in a serialized [MethodEvent] map that is used to store the
/// positional arguments that were passed to the method.
const String kManifestPositionalArgumentsKey = 'positionalArguments';

/// The key in a serialized [MethodEvent] map that is used to store the
/// named arguments that were passed to the method.
const String kManifestNamedArgumentsKey = 'namedArguments';

/// The serialized [kManifestTypeKey] for property retrievals.
const String kGetType = 'get';

/// The serialized [kManifestTypeKey] for property mutations.
const String kSetType = 'set';

/// The serialized [kManifestTypeKey] for method invocations.
const String kInvokeType = 'invoke';

/// Gets an id guaranteed to be unique on this isolate for objects within this
/// library.
int newUid() => _nextUid++;
int _nextUid = 1;

/// Gets the name of the specified [symbol].
// TODO(tvolkert): Symbol.name (https://github.com/dart-lang/sdk/issues/28372)
String getSymbolName(Symbol symbol) {
  // Format of `str` is `Symbol("<name>")`
  String str = symbol.toString();
  int offset = str.indexOf('"') + 1;
  return str.substring(offset, str.indexOf('"', offset));
}

/// This class is a work-around for the "is" operator not accepting a variable
/// value as its right operand (https://github.com/dart-lang/sdk/issues/27680).
class TypeMatcher<T> {
  /// Creates a type matcher for the given type parameter.
  const TypeMatcher();

  /// Returns `true` if the given object is of type `T`.
  bool matches(dynamic object) => object is T;
}
