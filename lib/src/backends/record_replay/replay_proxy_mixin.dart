// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'common.dart';
import 'encoding.dart';
import 'errors.dart';
import 'proxy.dart';
import 'resurrectors.dart';

typedef bool _InvocationMatcher(Map<String, dynamic> entry);

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
///       final String identifier;
///       final List<Map<String, dynamic>> manifest;
///
///       ReplayFoo(this.manifest, this.identifier) {
///         methods.addAll(<Symbol, Resurrector>{
///           #sampleMethod: resurrectComplexobject,
///         });
///
///         properties.addAll(<Symbol, Resurrector>{
///           #sampleProperty: resurrectFoo,
///           const Symbol('sampleProperty='): resurrectPassthrough,
///         });
///       }
///     }
abstract class ReplayProxyMixin implements ProxyObject {
  /// Maps method names to [Resurrector] functions.
  ///
  /// Invocations of methods listed in this map will be replayed by looking for
  /// matching invocations in the [manifest] and resurrecting the invocation
  /// return value using the values in this map.
  @protected
  final Map<Symbol, Resurrector> methods = <Symbol, Resurrector>{};

  /// Maps property getter and setter names to [Resurrector] functions.
  ///
  /// Access and mutation of properties listed in this map will be replayed
  /// by looking for matching property accesses in the [manifest] and
  /// resurrecting the invocation return value using the values in this map.
  ///
  /// The keys for property getters are the simple property names, whereas the
  /// keys for property setters are the property names followed by an equals
  /// sign (e.g. `propertyName=`).
  @protected
  final Map<Symbol, Resurrector> properties = <Symbol, Resurrector>{};

  /// The unique identifier of this replay object.
  ///
  /// When replay objects are returned as a result of a call, they are returned
  /// only as an opaque identifier. When those objects are then used as the
  /// invocation target, the same identifier is used in the serialized
  /// recording.
  String get identifier;

  /// The manifest of recorded invocation events.
  ///
  /// This manifest exists as `MANIFEST.txt` in a recording directory.
  List<Map<String, dynamic>> get manifest;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    Symbol name = invocation.memberName;
    Resurrector resurrector =
        invocation.isAccessor ? properties[name] : methods[name];

    if (resurrector == null) {
      // No resurrector generally means that there truly is no such method on
      // this object. The exception is when the invocation represents a getter
      // on a method, in which case we return a method proxy that, when
      // invoked, will replay the desired invocation.
      return invocation.isGetter && methods[name] != null
          ? new MethodProxy(this, name)
          : super.noSuchMethod(invocation);
    }

    Map<String, dynamic> entry = _nextEvent(invocation);
    if (entry == null) {
      throw new NoMatchingInvocationError(invocation);
    }
    entry[kManifestOrdinalKey] = _nextOrdinal++;

    assert(resurrector != null);
    return resurrector(entry[kManifestResultKey]);
  }

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
    return new Map<String, dynamic>.from(map);
  }
}
