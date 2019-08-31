// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'codecs.dart';
import 'common.dart';
import 'recording.dart';
import 'result_reference.dart';

/// Base class for recordable file system invocation events.
///
/// Instances of this class will be aggregated in a [Recording]
abstract class InvocationEvent<T> {
  /// The object on which the invocation occurred. Will always be non-null.
  Object get object;

  /// The return value of the invocation if the invocation completed
  /// successfully.
  ///
  /// This may be null (and will always be `null` for setters).
  ///
  /// If the invocation completed with an error, this value will be `null`,
  /// and [error] will be set.
  T get result;

  /// The error that was thrown by the invocation if the invocation completed
  /// with an error.
  ///
  /// If the invocation completed successfully, this value will be `null`, and
  /// [result] will hold the result of the invocation (which may also be
  /// `null`).
  ///
  /// This field being non-null can be used as an indication that the invocation
  /// completed with an error.
  dynamic get error;

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

/// An [InvocationEvent] that's in the process of being recorded.
abstract class LiveInvocationEvent<T> implements InvocationEvent<T> {
  /// Creates a new [LiveInvocationEvent].
  LiveInvocationEvent(this.object, this._result, this.error, this.timestamp);

  final dynamic _result;

  @override
  final Object object;

  @override
  T get result {
    dynamic result = _result;
    while (result is ResultReference) {
      ResultReference<dynamic> reference = result;
      result = reference.recordedValue;
    }
    return result;
  }

  @override
  final dynamic error;

  @override
  final int timestamp;

  /// A [Future] that completes once [result] is ready for serialization.
  ///
  /// If [result] is a [Future], this future completes when [result] completes.
  /// If [result] is a [Stream], this future completes when the stream sends a
  /// "done" event. If [result] is neither a future nor a stream, this future
  /// completes immediately.
  ///
  /// It is legal for [serialize] to be called before this future completes,
  /// but doing so will cause incomplete results to be serialized. Results that
  /// are unfinished futures will be serialized as `null`, and results that are
  /// unfinished streams will be serialized as the data that has been received
  /// thus far.
  Future<void> get done async {
    dynamic result = _result;
    while (result is ResultReference) {
      ResultReference<dynamic> reference = result;
      await reference.complete;
      result = reference.recordedValue;
    }
  }

  /// Returns this event as a JSON-serializable object.
  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      kManifestObjectKey: encode(object),
      kManifestResultKey: encode(_result),
      kManifestErrorKey: encode(error),
      kManifestTimestampKey: timestamp,
    };
  }

  @override
  String toString() => serialize().toString();
}

/// A [PropertyGetEvent] that's in the process of being recorded.
class LivePropertyGetEvent<T> extends LiveInvocationEvent<T>
    implements PropertyGetEvent<T> {
  /// Creates a new [LivePropertyGetEvent].
  LivePropertyGetEvent(
      Object object, this.property, T result, dynamic error, int timestamp)
      : super(object, result, error, timestamp);

  @override
  final Symbol property;

  @override
  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      kManifestTypeKey: kGetType,
      kManifestPropertyKey: getSymbolName(property),
    }..addAll(super.serialize());
  }
}

/// A [PropertySetEvent] that's in the process of being recorded.
class LivePropertySetEvent<T> extends LiveInvocationEvent<Null>
    implements PropertySetEvent<T> {
  /// Creates a new [LivePropertySetEvent].
  LivePropertySetEvent(
      Object object, this.property, this.value, dynamic error, int timestamp)
      : super(object, null, error, timestamp);

  @override
  final Symbol property;

  @override
  final T value;

  @override
  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      kManifestTypeKey: kSetType,
      kManifestPropertyKey: getSymbolName(property),
      kManifestValueKey: encode(value),
    }..addAll(super.serialize());
  }
}

/// A [MethodEvent] that's in the process of being recorded.
class LiveMethodEvent<T> extends LiveInvocationEvent<T>
    implements MethodEvent<T> {
  /// Creates a new [LiveMethodEvent].
  LiveMethodEvent(
    Object object,
    this.method,
    List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments,
    T result,
    dynamic error,
    int timestamp,
  )   : positionalArguments = List<dynamic>.unmodifiable(positionalArguments),
        namedArguments = Map<Symbol, dynamic>.unmodifiable(namedArguments),
        super(object, result, error, timestamp);

  @override
  final Symbol method;

  @override
  final List<dynamic> positionalArguments;

  @override
  final Map<Symbol, dynamic> namedArguments;

  @override
  Map<String, dynamic> serialize() {
    return <String, dynamic>{
      kManifestTypeKey: kInvokeType,
      kManifestMethodKey: getSymbolName(method),
      kManifestPositionalArgumentsKey: encode(positionalArguments),
      kManifestNamedArgumentsKey: encode(namedArguments),
    }..addAll(super.serialize());
  }
}
