// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

/// Base class for recordable file system invocation events.
abstract class _Event<T> {
  /// The object on which the invocation occurred.
  final Object object;

  /// The return value of the invocation (always `null` for setters).
  final T result;

  /// The stopwatch value (in milliseconds) when the invocation occurred.
  final int timestamp;

  _Event(this.object, this.result, this.timestamp);

  /// Encodes this event into a JSON-ready format.
  Map<String, dynamic> encode() => <String, dynamic>{
        'object': object,
        'result': result,
        'timestamp': timestamp,
      };
}

/// A recordable invocation of a property getter on a file system object.
class _PropertyGetEvent<T> extends _Event<T> {
  /// The property that was retrieved.
  final Symbol property;

  _PropertyGetEvent(Object object, this.property, T result, int timestamp)
      : super(object, result, timestamp);

  @override
  Map<String, dynamic> encode() => <String, dynamic>{
        'type': 'get',
        'property': property,
      }..addAll(super.encode());
}

/// A recordable invocation of a property setter on a file system object.
class _PropertySetEvent<T> extends _Event<Null> {
  /// The property that was set.
  final Symbol property;

  /// The value to which [property] was set.
  final T value;

  _PropertySetEvent(Object object, this.property, this.value, int timestamp)
      : super(object, null, timestamp);

  @override
  Map<String, dynamic> encode() => <String, dynamic>{
        'type': 'set',
        'property': property,
        'value': value,
      }..addAll(super.encode());
}

/// A recordable invocation of a method on a file system object.
class _MethodEvent<T> extends _Event<T> {
  /// The method that was invoked.
  final Symbol method;

  /// The positional arguments that were passed to the method.
  final List<dynamic> positionalArguments;

  /// The named arguments that were passed to the method.
  final Map<Symbol, dynamic> namedArguments;

  _MethodEvent(Object object, this.method, this.positionalArguments,
      this.namedArguments, T result, int timestamp)
      : super(object, result, timestamp);

  @override
  Map<String, dynamic> encode() => <String, dynamic>{
        'type': 'invoke',
        'method': method,
        'positionalArguments': positionalArguments,
        'namedArguments': namedArguments,
      }..addAll(super.encode());
}
