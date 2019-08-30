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
/// error that was thrown during the invocation.
const String kManifestErrorKey = 'error';

/// The key in a serialized error that is used to store the runtime type of
/// the error that was thrown.
const String kManifestErrorTypeKey = 'type';

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

/// The key in a serialized [InvocationEvent] map that is used to store the
/// order in which the invocation has been replayed (if it has been replayed).
const String kManifestOrdinalKey = 'ordinal';

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

  static const TypeMatcher<void> _void = TypeMatcher<void>();

  /// This matcher's type, `T`.
  Type get type => T;

  /// Returns `true` if the given object is of type `T`.
  bool matches(dynamic object) {
    return T == _void.type ? object == T : object is T;
  }
}

/// Marks a class that, when serialized, will be referred to merely by an
/// opaque identifier.
///
/// Unlike other objects, objects that are replay-aware don't need to serialize
/// meaningful metadata about their state for the sake of revival. Rather, they
/// derive all the information they need to operate from the recording. As such,
/// they are serialized using only an opaque unique identifier. When they are
/// revived during replay, their identifier allows them to find invocations in
/// the recording for which they are the target.
abstract class ReplayAware {
  /// The identifier of this object, guaranteed to be unique within a single
  /// recording.
  String get identifier;
}

/// Tells whether two objects are equal using deep equality checking.
///
/// Two lists are deeply equal if they have the same runtime type, the same
/// length, and every element in list A is pairwise deeply equal with the
/// corresponding element in list B.
///
/// Two maps are deeply equal if they have the same runtime type, the same
/// length, the same set of keys, and the value for every key in map A is
/// deeply equal to the corresponding value in map B.
///
/// All other types of objects are deeply equal if they have the same runtime
/// type and are logically equal (according to `operator==`).
bool deeplyEqual(dynamic object1, dynamic object2) {
  if (object1.runtimeType != object2.runtimeType) {
    return false;
  } else if (object1 is List) {
    return _areListsEqual<dynamic>(object1, object2);
  } else if (object1 is Map) {
    return _areMapsEqual<dynamic, dynamic>(object1, object2);
  } else {
    return object1 == object2;
  }
}

bool _areListsEqual<T>(List<T> list1, List<T> list2) {
  int i = 0;
  return list1.length == list2.length &&
      list1.every((T element) => deeplyEqual(element, list2[i++]));
}

bool _areMapsEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
  return map1.length == map2.length &&
      map1.keys.every((K key) {
        return map1.containsKey(key) == map2.containsKey(key) &&
            deeplyEqual(map1[key], map2[key]);
      });
}
