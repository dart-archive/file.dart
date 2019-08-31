// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:file/file.dart';
import 'package:file/src/backends/memory/node.dart';

import 'package:meta/meta.dart';

import 'common.dart';
import 'events.dart';
import 'mutable_recording.dart';
import 'proxy.dart';
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
///     class RecordingFoo extends RecordingProxyMixin implements Foo {
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
mixin RecordingProxyMixin on Object implements ProxyObject, ReplayAware {
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

  // This check is used in noSuchMethod to detect if this code is running in a
  // Dart 1 runtime, or Dart 2.
  // TODO(srawlins): Remove this after the minimum SDK constraint is such that
  // there is no "Dart 1" runtime mode. 2.0.0 or something.
  bool get _runningDart1Runtime => <dynamic>[] is List<String>;

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
          ? MethodProxy(this, name)
          : super.noSuchMethod(invocation);
    }

    InvocationEvent<dynamic> createEvent({dynamic result, dynamic error}) {
      if (invocation.isGetter) {
        return LivePropertyGetEvent<dynamic>(this, name, result, error, time);
      } else if (invocation.isSetter) {
        return LivePropertySetEvent<dynamic>(this, name, args[0], error, time);
      } else {
        return LiveMethodEvent<dynamic>(
            this, name, args, namedArgs, result, error, time);
      }
    }

    // Invoke the configured delegate method, recording an error if one occurs.
    dynamic value;
    try {
      value = Function.apply(method, args, namedArgs);
    } catch (error) {
      recording.add(createEvent(error: error));
      rethrow;
    }

    // Wrap Future and Stream results so that we record their values as they
    // become available.
    // We have to instantiate the correct type of StreamReference or
    // FutureReference, so that types are not lost when we unwrap the references
    // afterward.
    if (_runningDart1Runtime && value is Stream<dynamic>) {
      // This one is here for Dart 1 runtime mode.
      value = StreamReference<dynamic>(value);
    } else if (value is Stream<FileSystemEntity>) {
      value = StreamReference<FileSystemEntity>(value);
    } else if (value is Stream<String>) {
      value = StreamReference<String>(value);
    } else if (value is Stream) {
      throw UnimplementedError(
          'Cannot record method with return type ${value.runtimeType}');
    } else if (_runningDart1Runtime && value is Future<dynamic>) {
      // This one is here for Dart 1 runtime mode.
      value = FutureReference<dynamic>(value);
    } else if (value is Future<bool>) {
      value = FutureReference<bool>(value);
    } else if (value is Future<Directory>) {
      value = FutureReference<Directory>(value);
    } else if (value is Future<File>) {
      value = FutureReference<File>(value);
    } else if (value is Future<FileNode>) {
      value = FutureReference<FileNode>(value);
    } else if (value is Future<FileStat>) {
      value = FutureReference<FileStat>(value);
    } else if (value is Future<Link>) {
      value = FutureReference<Link>(value);
    } else if (value is Future<FileSystemEntity>) {
      value = FutureReference<FileSystemEntity>(value);
    } else if (value is Future<FileSystemEntityType>) {
      value = FutureReference<FileSystemEntityType>(value);
    } else if (value is Future<String>) {
      value = FutureReference<String>(value);
    } else if (value is Future<RandomAccessFile>) {
      value = FutureReference<RandomAccessFile>(value);
    } else if (value is Future<void>) {
      value = FutureReference<void>(value);
    }

    // Record the invocation event associated with this invocation.
    recording.add(createEvent(result: value));

    // Unwrap any result references before returning to the caller.
    dynamic result = value;
    while (result is ResultReference) {
      result = result.value;
    }
    return result;
  }
}
