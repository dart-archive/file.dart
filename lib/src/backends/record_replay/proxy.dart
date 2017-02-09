// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An object that uses [noSuchMethod] to dynamically handle invocations
/// (property getters, property setters, and method invocations).
abstract class ProxyObject {}

/// A function reference that, when invoked, will forward the invocation back
/// to a [ProxyObject].
///
/// This is used when a caller accesses a method on a [ProxyObject] via the
/// method's getter. In these cases, the caller will receive a [MethodProxy]
/// that allows delayed invocation of the method.
class MethodProxy extends Object implements Function {
  /// The object on which the method was retrieved.
  ///
  /// This will be the target object when this proxy is invoked.
  final ProxyObject _proxyObject;

  /// The name of the method that was retrieved.
  ///
  /// This method will be invoked when this proxy is invoked.
  final Symbol _methodName;

  /// Creates a new [MethodProxy] that, when invoked, will invoke the method
  /// identified by [methodName] on the specified target proxy [object].
  MethodProxy(ProxyObject object, Symbol methodName)
      : _proxyObject = object,
        _methodName = methodName;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #call) {
      // The method is being invoked. Capture the arguments, and invoke the
      // method on the proxy object. We have to synthesize an invocation, since
      // our current `invocation` object represents the invocation of `call()`.
      return _proxyObject.noSuchMethod(new _MethodInvocationProxy(
        _methodName,
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
