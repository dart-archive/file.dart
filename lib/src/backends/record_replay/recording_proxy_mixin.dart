// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'events.dart';
import 'mutable_recording.dart';
import 'result_reference.dart';

/// Mixin that enables recording of property accesses, property mutations, and
/// method invocations.
///
/// This class uses `noSuchMethod` to record a well-defined set of invocations
/// (including property gets and sets) on an object before passing the
/// invocation on to a delegate. Subclasses wire this up by doing the following:
///
///   - Populate the list of method invocations to record in the [methods] map.
///   - Populate the list of property invocations to record in the [properties]
///     map. The symbol name for getters should be the property name, and the
///     symbol name for setters should be the property name immediately
///     followed by an equals sign (e.g. `propertyName=`).
///   - Do not implement a concrete getter, setter, or method that you wish to
///     record, as doing so will circumvent the machinery that this mixin uses
///     (`noSuchMethod`) to record invocations.
///
/// **Example use**:
///
///     abstract class Foo {
///       void sampleMethod();
///
///       int sampleProperty;
///     }
///
///     class RecordingFoo extends Object with _RecordingProxyMixin implements Foo {
///       final Foo delegate;
///
///       RecordingFoo(this.delegate) {
///         methods.addAll(<Symbol, Function>{
///           #sampleMethod: delegate.sampleMethod,
///         });
///
///         properties.addAll(<Symbol, Function>{
///           #sampleProperty: () => delegate.sampleProperty,
///           const Symbol('sampleProperty='): (int value) {
///             delegate.sampleProperty = value;
///           },
///         });
///       }
///     }
///
/// **Behavioral notes**:
///
/// Methods that return [Future]s will not be recorded until the future
/// completes.
///
/// Methods that return [Stream]s will be recorded immediately, but their
/// return values will be recorded as a [List] that will grow as the stream
/// produces data.
abstract class RecordingProxyMixin {
  /// Maps method names to delegate functions.
  ///
  /// Invocations of methods listed in this map will be recorded after
  /// invoking the underlying delegate function.
  @protected
  final Map<Symbol, Function> methods = <Symbol, Function>{};

  /// Maps property getter and setter names to delegate functions.
  ///
  /// Access and mutation of properties listed in this map will be recorded
  /// after invoking the underlying delegate function.
  ///
  /// The keys for property getters are the simple property names, whereas the
  /// keys for property setters are the property names followed by an equals
  /// sign (e.g. `propertyName=`).
  @protected
  final Map<Symbol, Function> properties = <Symbol, Function>{};

  /// The object to which invocation events will be recorded.
  @protected
  MutableRecording get recording;

  /// The stopwatch used to record invocation timestamps.
  @protected
  Stopwatch get stopwatch;

  /// Handles invocations for which there is no concrete implementation
  /// function.
  ///
  /// For invocations that have matching entries in [methods] (for method
  /// invocations) or [properties] (for property access and mutation), this
  /// will record the invocation in [recording] after invoking the underlying
  /// delegate method. All other invocations will throw a [NoSuchMethodError].
  @override
  dynamic noSuchMethod(Invocation invocation) {
    Symbol name = invocation.memberName;
    List<dynamic> args = invocation.positionalArguments;
    Map<Symbol, dynamic> namedArgs = invocation.namedArguments;
    Function method = invocation.isAccessor ? properties[name] : methods[name];
    int time = stopwatch.elapsedMilliseconds;

    if (method == null) {
      // No delegate function generally means that there truly is no such
      // method on this object. The exception is when the invocation represents
      // a getter on a method, in which case we return a method proxy that,
      // when invoked, will perform the desired recording.
      return invocation.isGetter && methods[name] != null
          ? new _MethodProxy(this, name)
          : super.noSuchMethod(invocation);
    }

    // Invoke the configured delegate method, wrapping Future and Stream
    // results so that we record their values as they become available.
    // TODO(tvolkert): record exceptions.
    dynamic value = Function.apply(method, args, namedArgs);
    if (value is Stream) {
      value = new StreamReference<dynamic>(value);
    } else if (value is Future) {
      value = new FutureReference<dynamic>(value);
    }

    // Record the invocation event associated with this invocation.
    InvocationEvent<dynamic> event;
    if (invocation.isGetter) {
      event = new LivePropertyGetEvent<dynamic>(this, name, value, time);
    } else if (invocation.isSetter) {
      // TODO(tvolkert): Remove indirection once SDK 1.22 is in stable branch
      dynamic temp =
          new LivePropertySetEvent<dynamic>(this, name, args[0], time);
      event = temp;
    } else {
      event = new LiveMethodEvent<dynamic>(
          this, name, args, namedArgs, value, time);
    }
    recording.add(event);

    // Unwrap any result references before returning to the caller.
    dynamic result = value;
    while (result is ResultReference) {
      result = result.value;
    }
    return result;
  }
}

/// A function reference that, when invoked, will record the invocation.
class _MethodProxy extends Object implements Function {
  /// The object on which the method was originally invoked.
  final RecordingProxyMixin object;

  /// The name of the method that was originally invoked.
  final Symbol methodName;

  _MethodProxy(this.object, this.methodName);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #call) {
      // The method is being invoked. Capture the arguments, and invoke the
      // method on the object. We have to synthesize an invocation, since our
      // current `invocation` object represents the invocation of `call()`.
      return object.noSuchMethod(new _MethodInvocationProxy(
        methodName,
        invocation.positionalArguments,
        invocation.namedArguments,
      ));
    }
    return super.noSuchMethod(invocation);
  }
}

class _MethodInvocationProxy extends Invocation {
  _MethodInvocationProxy(
    this.memberName,
    this.positionalArguments,
    this.namedArguments,
  );

  @override
  final Symbol memberName;

  @override
  final List<dynamic> positionalArguments;

  @override
  final Map<Symbol, dynamic> namedArguments;

  @override
  final bool isMethod = true;

  @override
  final bool isGetter = false;

  @override
  final bool isSetter = false;
}
