// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/record_replay.dart';
import 'package:file/src/backends/record_replay/common.dart'
    show getSymbolName; // ignore: implementation_imports
import 'package:test/test.dart';

const Map<Type, String> _kTypeDescriptions = <Type, String>{
  MethodEvent: 'a method invocation',
  PropertyGetEvent: 'a property retrieval',
  PropertySetEvent: 'a property mutation',
};

const Map<Type, Matcher> _kTypeMatchers = <Type, Matcher>{
  MethodEvent: TypeMatcher<MethodEvent<dynamic>>(),
  PropertyGetEvent: TypeMatcher<PropertyGetEvent<dynamic>>(),
  PropertySetEvent: TypeMatcher<PropertySetEvent<dynamic>>(),
};

/// Returns a matcher that will match against a [MethodEvent].
///
/// If [name] is specified, only method invocations of a matching method name
/// will successfully match. [name] may be a String, a predicate function,
/// or a [Matcher].
///
/// The returned [MethodInvocation] matcher can be used to further limit the
/// scope of the match (e.g. by invocation result, target object, etc).
MethodInvocation invokesMethod([dynamic name]) => MethodInvocation._(name);

/// Returns a matcher that will match against a [PropertyGetEvent].
///
/// If [name] is specified, only property retrievals of a matching property name
/// will successfully match. [name] may be a String, a predicate function,
/// or a [Matcher].
///
/// The returned [PropertyGet] matcher can be used to further limit the
/// scope of the match (e.g. by property value, target object, etc).
PropertyGet getsProperty([dynamic name]) => PropertyGet._(name);

/// Returns a matcher that will match against a [PropertySetEvent].
///
/// If [name] is specified, only property mutations of a matching property name
/// will successfully match. [name] may be a String, a predicate function,
/// or a [Matcher].
///
/// The returned [PropertySet] matcher can be used to further limit the
/// scope of the match (e.g. by property value, target object, etc).
PropertySet setsProperty([dynamic name]) => PropertySet._(name);

/// A matcher that successfully matches against a future or function
/// that throws a [NoMatchingInvocationError].
Matcher throwsNoMatchingInvocationError =
    throwsA(const TypeMatcher<NoMatchingInvocationError>());

/// Base class for matchers that match against generic [InvocationEvent]
/// instances.
abstract class RecordedInvocation<T extends RecordedInvocation<T>>
    extends Matcher {
  RecordedInvocation._(Type type) : _typeMatcher = _Type(type);

  final _Type _typeMatcher;
  final List<Matcher> _fieldMatchers = <Matcher>[];

  /// Limits the scope of the match to invocations that occurred on the
  /// specified target [object].
  ///
  /// [object] may be an instance or a [Matcher]. If it is an instance, it will
  /// be automatically wrapped in an equality matcher.
  ///
  /// Returns this matcher for chaining.
  T on(dynamic object) {
    _fieldMatchers.add(_Target(object));
    return this;
  }

  /// Limits the scope of the match to invocations that produced the specified
  /// [result].
  ///
  /// For method invocations, this matches against the return value of the
  /// method. For property retrievals, this matches against the value of the
  /// property. Property mutations will always produce a `null` result, so
  /// [PropertySet] will automatically call `withResult(null)` when it is
  /// instantiated.
  ///
  /// [result] may be an instance or a [Matcher]. If it is an instance, it will
  /// be automatically wrapped in an equality matcher.
  ///
  /// Returns this matcher for chaining.
  T withResult(dynamic result) {
    _fieldMatchers.add(_Result(result));
    return this;
  }

  /// Limits the scope of the match to invocations that were recorded with the
  /// specified [timestamp].
  ///
  /// [timestamp] may be an `int` or a [Matcher]. If it is an `int`, it will
  /// be automatically wrapped in an equality matcher.
  ///
  /// Returns this matcher for chaining.
  T withTimestamp(dynamic timestamp) {
    _fieldMatchers.add(_Timestamp(timestamp));
    return this;
  }

  /// @nodoc
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (!_typeMatcher.matches(item, matchState)) {
      addStateInfo(matchState, <String, Matcher>{'matcher': _typeMatcher});
      return false;
    }
    for (Matcher matcher in _fieldMatchers) {
      if (!matcher.matches(item, matchState)) {
        addStateInfo(matchState, <String, Matcher>{'matcher': matcher});
        return false;
      }
    }
    return true;
  }

  /// @nodoc
  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    Matcher matcher = matchState['matcher'];
    matcher.describeMismatch(item, description, matchState['state'], verbose);
    return description;
  }

  /// @nodoc
  @override
  Description describe(Description description) {
    String divider = '\n  - ';
    return _typeMatcher
        .describe(description)
        .add(':')
        .addAll(divider, divider, '', _fieldMatchers);
  }
}

/// Matchers that matches against [MethodEvent] instances.
///
/// Instances of this matcher are obtained by calling [invokesMethod]. Once
/// instantiated, callers may use this matcher to further qualify the scope
/// of their match.
class MethodInvocation extends RecordedInvocation<MethodInvocation> {
  MethodInvocation._(dynamic methodName) : super._(MethodEvent) {
    if (methodName != null) {
      _fieldMatchers.add(_MethodName(methodName));
    }
  }

  /// Limits the scope of the match to method invocations that passed the
  /// specified positional [arguments].
  ///
  /// [arguments] may be a list instance or a [Matcher]. If it is a list, it
  /// will be automatically wrapped in an equality matcher.
  ///
  /// Returns this matcher for chaining.
  MethodInvocation withPositionalArguments(dynamic arguments) {
    _fieldMatchers.add(_PositionalArguments(arguments));
    return this;
  }

  /// Limits the scope of the match to method invocations that passed the
  /// specified named argument.
  ///
  /// The argument [value] may be an instance or a [Matcher]. If it is an
  /// instance, it will be automatically wrapped in an equality matcher.
  ///
  /// Returns this matcher for chaining.
  MethodInvocation withNamedArgument(String name, dynamic value) {
    _fieldMatchers.add(_NamedArgument(name, value));
    return this;
  }

  /// Limits the scope of the match to method invocations that specified no
  /// named arguments.
  ///
  /// Returns this matcher for chaining.
  MethodInvocation withNoNamedArguments() {
    _fieldMatchers.add(const _NoNamedArguments());
    return this;
  }
}

/// Matchers that matches against [PropertyGetEvent] instances.
///
/// Instances of this matcher are obtained by calling [getsProperty]. Once
/// instantiated, callers may use this matcher to further qualify the scope
/// of their match.
class PropertyGet extends RecordedInvocation<PropertyGet> {
  PropertyGet._(dynamic propertyName) : super._(PropertyGetEvent) {
    if (propertyName != null) {
      _fieldMatchers.add(_GetPropertyName(propertyName));
    }
  }
}

/// Matchers that matches against [PropertySetEvent] instances.
///
/// Instances of this matcher are obtained by calling [setsProperty]. Once
/// instantiated, callers may use this matcher to further qualify the scope
/// of their match.
class PropertySet extends RecordedInvocation<PropertySet> {
  PropertySet._(dynamic propertyName) : super._(PropertySetEvent) {
    withResult(null);
    if (propertyName != null) {
      _fieldMatchers.add(_SetPropertyName(propertyName));
    }
  }

  /// Limits the scope of the match to property mutations that set the property
  /// to the specified [value].
  ///
  /// [value] may be an instance or a [Matcher]. If it is an instance, it will
  /// be automatically wrapped in an equality matcher.
  ///
  /// Returns this matcher for chaining.
  PropertySet toValue(dynamic value) {
    _fieldMatchers.add(_SetValue(value));
    return this;
  }
}

class _Target extends Matcher {
  _Target(dynamic target) : _matcher = wrapMatcher(target);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.object, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    description.add('was invoked on: ${item.object}');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(item.object, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description desc) {
    desc.add('on object: ');
    return _matcher.describe(desc);
  }
}

class _Result extends Matcher {
  _Result(dynamic result) : _matcher = wrapMatcher(result);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.result, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    description.add('returned: ${item.result}');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(item.result, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description desc) {
    desc.add('with result: ');
    return _matcher.describe(desc);
  }
}

class _Timestamp extends Matcher {
  _Timestamp(dynamic timestamp) : _matcher = wrapMatcher(timestamp);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.timestamp, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    description.add('has timestamp: ${item.timestamp}');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(item.timestamp, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description desc) {
    desc.add('with timestamp: ');
    return _matcher.describe(desc);
  }
}

class _Type extends Matcher {
  const _Type(this.type);

  final Type type;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _kTypeMatchers[type].matches(item, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    Type type;
    for (Type matchType in _kTypeMatchers.keys) {
      Matcher matcher = _kTypeMatchers[matchType];
      if (matcher.matches(item, <dynamic, dynamic>{})) {
        type = matchType;
        break;
      }
    }
    if (type != null) {
      description.add('is ').add(_kTypeDescriptions[type]);
    } else {
      description.add('is a ${item.runtimeType}');
    }
    return description;
  }

  @override
  Description describe(Description desc) => desc.add(_kTypeDescriptions[type]);
}

class _MethodName extends Matcher {
  _MethodName(dynamic name) : _matcher = wrapMatcher(name);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(getSymbolName(item.method), matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    String methodName = getSymbolName(item.method);
    description.add('invoked method: \'$methodName\'');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(methodName, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description desc) {
    desc.add('method: ');
    return _matcher.describe(desc);
  }
}

class _PositionalArguments extends Matcher {
  _PositionalArguments(dynamic value) : _matcher = wrapMatcher(value);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.positionalArguments, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return _matcher.describeMismatch(
        item.positionalArguments, description, matchState, verbose);
  }

  @override
  Description describe(Description desc) {
    desc.add('with positional arguments: ');
    return _matcher.describe(desc);
  }
}

class _NamedArgument extends Matcher {
  _NamedArgument(this.name, this.value)
      : _matcher = containsPair(Symbol(name), value);

  final String name;
  final dynamic value;
  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.namedArguments, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return _matcher.describeMismatch(
        item.namedArguments, description, matchState, verbose);
  }

  @override
  Description describe(Description description) =>
      description.add('with named argument "$name" = $value');
}

class _NoNamedArguments extends Matcher {
  const _NoNamedArguments();

  Matcher get _matcher => isEmpty;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.namedArguments, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return _matcher.describeMismatch(
        item.namedArguments, description, matchState, verbose);
  }

  @override
  Description describe(Description description) =>
      description.add('with no named arguments');
}

class _GetPropertyName extends Matcher {
  _GetPropertyName(dynamic _name) : _matcher = wrapMatcher(_name);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(getSymbolName(item.property), matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    String propertyName = getSymbolName(item.property);
    description.add('got property: \'$propertyName\'');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(propertyName, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description description) {
    description.add('gets property: ');
    return _matcher.describe(description);
  }
}

class _SetPropertyName extends Matcher {
  _SetPropertyName(dynamic _name) : _matcher = wrapMatcher(_name);

  final Matcher _matcher;

  /// Strips the trailing `=` off the symbol name to get the property name.
  String _getPropertyName(dynamic item) {
    String symbolName = getSymbolName(item.property);
    return symbolName.substring(0, symbolName.length - 1);
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return _matcher.matches(_getPropertyName(item), matchState);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    String propertyName = _getPropertyName(item);
    description.add('set property: \'$propertyName\'');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(propertyName, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description description) {
    description.add('of property: ');
    return _matcher.describe(description);
  }
}

class _SetValue extends Matcher {
  _SetValue(dynamic value) : _matcher = wrapMatcher(value);

  final Matcher _matcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      _matcher.matches(item.value, matchState);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    description.add('set value: ${item.value}');
    Description matcherDesc = StringDescription();
    _matcher.describeMismatch(item.value, matcherDesc, matchState, verbose);
    if (matcherDesc.length > 0) {
      description.add('\n   Which: ').add(matcherDesc.toString());
    }
    return description;
  }

  @override
  Description describe(Description description) {
    description.add('to value: ');
    return _matcher.describe(description);
  }
}
