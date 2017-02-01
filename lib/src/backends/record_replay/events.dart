// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'recording.dart';

/// Base class for recordable file system invocation events.
///
/// Instances of this class will be aggregated in a [Recording]
abstract class InvocationEvent<T> {
  /// The object on which the invocation occurred. Will always be non-null.
  Object get object;

  /// The return value of the invocation. This may be null (and will always be
  /// `null` for setters).
  T get result;

  /// The stopwatch value (in milliseconds) when the invocation occurred.
  ///
  /// This value is recorded when the invocation first occurs, not when the
  /// delegate returns.
  int get timestamp;
}

/// A recordable invocation of a property getter on a file system object.
abstract class PropertyGetEvent<T> extends InvocationEvent<T> {
  /// The property that was retrieved.
  Symbol get property;
}

/// A recordable invocation of a property setter on a file system object.
abstract class PropertySetEvent<T> extends InvocationEvent<Null> {
  /// The property that was set.
  ///
  /// All setter property symbols will have a trailing equals sign. For example,
  /// if the `foo` property was set, this value will be a symbol of `foo=`.
  Symbol get property;

  /// The value to which [property] was set. This is distinct from [result],
  /// which is always `null` for setters.
  T get value;
}

/// A recordable invocation of a method on a file system object.
abstract class MethodEvent<T> extends InvocationEvent<T> {
  /// The method that was invoked.
  Symbol get method;

  /// The positional arguments that were passed to the method.
  List<dynamic> get positionalArguments;

  /// The named arguments that were passed to the method.
  Map<Symbol, dynamic> get namedArguments;
}

/// Non-exported implementation of [InvocationEvent].
abstract class EventImpl<T> implements InvocationEvent<T> {
  /// Creates a new `EventImpl`.
  EventImpl(this.object, this.result, this.timestamp);

  @override
  final Object object;

  @override
  final T result;

  @override
  final int timestamp;

  /// Encodes this event into a JSON-ready format.
  Map<String, dynamic> encode() => <String, dynamic>{
        'object': object,
        'result': result,
        'timestamp': timestamp,
      };

  @override
  String toString() => encode().toString();
}

/// Non-exported implementation of [PropertyGetEvent].
class PropertyGetEventImpl<T> extends EventImpl<T>
    implements PropertyGetEvent<T> {
  /// Create a new `PropertyGetEventImpl`.
  PropertyGetEventImpl(Object object, this.property, T result, int timestamp)
      : super(object, result, timestamp);

  @override
  final Symbol property;

  @override
  Map<String, dynamic> encode() => <String, dynamic>{
        'type': 'get',
        'property': property,
      }..addAll(super.encode());
}

/// Non-exported implementation of [PropertySetEvent].
class PropertySetEventImpl<T> extends EventImpl<Null>
    implements PropertySetEvent<T> {
  /// Create a new `PropertySetEventImpl`.
  PropertySetEventImpl(Object object, this.property, this.value, int timestamp)
      : super(object, null, timestamp);

  @override
  final Symbol property;

  @override
  final T value;

  @override
  Map<String, dynamic> encode() => <String, dynamic>{
        'type': 'set',
        'property': property,
        'value': value,
      }..addAll(super.encode());
}

/// Non-exported implementation of [MethodEvent].
class MethodEventImpl<T> extends EventImpl<T> implements MethodEvent<T> {
  /// Create a new `MethodEventImpl`.
  MethodEventImpl(
    Object object,
    this.method,
    List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments,
    T result,
    int timestamp,
  )
      : this.positionalArguments =
            new List<dynamic>.unmodifiable(positionalArguments),
        this.namedArguments =
            new Map<Symbol, dynamic>.unmodifiable(namedArguments),
        super(object, result, timestamp);

  @override
  final Symbol method;

  @override
  final List<dynamic> positionalArguments;

  @override
  final Map<Symbol, dynamic> namedArguments;

  @override
  Map<String, dynamic> encode() => <String, dynamic>{
        'type': 'invoke',
        'method': method,
        'positionalArguments': positionalArguments,
        'namedArguments': namedArguments,
      }..addAll(super.encode());
}
