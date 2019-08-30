// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import 'codecs.dart';
import 'common.dart';
import 'errors.dart';
import 'proxy.dart';

typedef _InvocationMatcher = bool Function(Map<String, dynamic> entry);

/// Used to record the order in which invocations were replayed.
///
/// Tests can later check expectations about the order in which invocations
/// were replayed vis-a-vis the order in which they were recorded.
int _nextOrdinal = 0;

/// Mixin that enables replaying of property accesses, property mutations, and
/// method invocations from a prior recording.
///
/// This class uses `noSuchMethod` to replay a well-defined set of invocations
/// (including property gets and sets) on an object. Subclasses wire this up by
/// doing the following:
///
///   - Populate the list of method invocations to replay in the [methods] map.
///   - Populate the list of property invocations to replay in the [properties]
///     map. The symbol name for getters should be the property name, and the
///     symbol name for setters should be the property name immediately
///     followed by an equals sign (e.g. `propertyName=`).
///   - Do not implement a concrete getter, setter, or method that you wish to
///     replay, as doing so will circumvent the machinery that this mixin uses
///     (`noSuchMethod`) to replay invocations.
///
/// **Example use**:
///
///     abstract class Foo {
///       ComplexObject sampleMethod();
///
///       Foo sampleParent;
///     }
///
///     class ReplayFoo extends Object with ReplayProxyMixin implements Foo {
///       final List<Map<String, dynamic>> manifest;
///       final String identifier;
///
///       ReplayFoo(this.manifest, this.identifier) {
///         methods.addAll(<Symbol, Converter<dynamic, dynamic>>{
///           #sampleMethod: complexObjectReviver,
///         });
///
///         properties.addAll(<Symbol, Converter<dynamic, dynamic>>{
///           #sampleParent: fooReviver,
///           const Symbol('sampleParent='): passthroughReviver,
///         });
///       }
///     }
mixin ReplayProxyMixin on Object implements ProxyObject, ReplayAware {
  /// Maps method names to [Converter]s that will revive result values.
  ///
  /// Invocations of methods listed in this map will be replayed by looking for
  /// matching invocations in the [manifest] and reviving the invocation return
  /// value using the [Converter] found in this map.
  @protected
  final Map<Symbol, Converter<dynamic, dynamic>> methods =
      <Symbol, Converter<dynamic, dynamic>>{};

  /// Maps property getter and setter names to [Converter]s that will revive
  /// result values.
  ///
  /// Access and mutation of properties listed in this map will be replayed
  /// by looking for matching property accesses in the [manifest] and reviving
  /// the invocation return value using the [Converter] found in this map.
  ///
  /// The keys for property getters are the simple property names, whereas the
  /// keys for property setters are the property names followed by an equals
  /// sign (e.g. `propertyName=`).
  @protected
  final Map<Symbol, Converter<dynamic, dynamic>> properties =
      <Symbol, Converter<dynamic, dynamic>>{};

  /// The manifest of recorded invocation events.
  ///
  /// When invocations are received on this object, we will attempt find a
  /// matching invocation in this manifest to perform the replay. If no such
  /// invocation is found (or if it has already been replayed), the caller will
  /// receive a [NoMatchingInvocationError].
  ///
  /// This manifest exists as `MANIFEST.txt` in a recording directory.
  @protected
  List<Map<String, dynamic>> get manifest;

  /// Protected method for subclasses to be notified when an invocation has
  /// been successfully replayed, and the result is about to be returned to
  /// the caller.
  ///
  /// Returns the value that is to be returned to the caller. The default
  /// implementation returns [result] (replayed from the recording); subclasses
  /// may override this method to alter the result that's returned to the
  /// caller.
  @protected
  dynamic onResult(Invocation invocation, dynamic result) => result;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    Symbol name = invocation.memberName;
    Converter<dynamic, dynamic> reviver =
        invocation.isAccessor ? properties[name] : methods[name];

    if (reviver == null) {
      // No reviver generally means that there truly is no such method on
      // this object. The exception is when the invocation represents a getter
      // on a method, in which case we return a method proxy that, when
      // invoked, will replay the desired invocation.
      return invocation.isGetter && methods[name] != null
          ? MethodProxy(this, name)
          : super.noSuchMethod(invocation);
    }

    Map<String, dynamic> entry = _nextEvent(invocation);
    if (entry == null) {
      throw NoMatchingInvocationError(invocation);
    }
    entry[kManifestOrdinalKey] = _nextOrdinal++;

    dynamic error = entry[kManifestErrorKey];
    if (error != null) {
      throw const ToError().convert(error);
    }
    dynamic result = reviver.convert(entry[kManifestResultKey]);
    result = onResult(invocation, result);
    return result;
  }

  /// Finds the next available invocation event in the [manifest] that matches
  /// the specified [invocation].
  Map<String, dynamic> _nextEvent(Invocation invocation) {
    _InvocationMatcher matches = _getMatcher(invocation);
    return manifest.firstWhere((Map<String, dynamic> entry) {
      return entry[kManifestOrdinalKey] == null && matches(entry);
    }, orElse: () => null);
  }

  _InvocationMatcher _getMatcher(Invocation invocation) {
    String name = getSymbolName(invocation.memberName);
    List<dynamic> args = encode(invocation.positionalArguments);
    Map<String, dynamic> namedArgs = encode(invocation.namedArguments);

    if (invocation.isGetter) {
      return (Map<String, dynamic> entry) =>
          entry[kManifestTypeKey] == kGetType &&
          entry[kManifestPropertyKey] == name &&
          entry[kManifestObjectKey] == identifier;
    } else if (invocation.isSetter) {
      return (Map<String, dynamic> entry) =>
          entry[kManifestTypeKey] == kSetType &&
          entry[kManifestPropertyKey] == name &&
          deeplyEqual(entry[kManifestValueKey], args[0]) &&
          entry[kManifestObjectKey] == identifier;
    } else {
      return (Map<String, dynamic> entry) {
        return entry[kManifestTypeKey] == kInvokeType &&
            entry[kManifestMethodKey] == name &&
            deeplyEqual(entry[kManifestPositionalArgumentsKey], args) &&
            deeplyEqual(_asNamedArgsType(entry[kManifestNamedArgumentsKey]),
                namedArgs) &&
            entry[kManifestObjectKey] == identifier;
      };
    }
  }

  static Map<String, dynamic> _asNamedArgsType(Map<dynamic, dynamic> map) {
    return Map<String, dynamic>.from(map);
  }
}
