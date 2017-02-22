// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Translates [path] from Posix style to the current platform's native
/// style.
String posixToNative(String path) {
  p.Context posix = new p.Context(style: p.Style.posix);
  return p.joinAll(posix.split(path));
}

/// Returns a [DateTime] with an exact second-precision by removing the
/// milliseconds and microseconds from the specified [time].
///
/// If [time] is not specified, it will default to the current time.
DateTime floor([DateTime time]) {
  time ??= new DateTime.now();
  return time.subtract(new Duration(
    milliseconds: time.millisecond,
    microseconds: time.microsecond,
  ));
}

/// Returns a [DateTime] with an exact second precision by adding just enough
/// milliseconds and microseconds to the specified [time] to reach the next
/// second.
///
/// If [time] is not specified, it will default to the current time.
DateTime ceil([DateTime time]) {
  time ??= new DateTime.now();
  int microseconds = (1000 * time.millisecond) + time.microsecond;
  return time.add(new Duration(microseconds: 1000000 - microseconds));
}

/// Successfully matches against a [DateTime] that is the same moment or before
/// the specified [time].
Matcher isSameOrBefore(DateTime time) => new _IsSameOrBefore(time);

/// Successfully matches against a [DateTime] that is the same moment or after
/// the specified [time].
Matcher isSameOrAfter(DateTime time) => new _IsSameOrAfter(time);

abstract class _CompareDateTime extends Matcher {
  final DateTime _time;
  final Matcher _matcher;

  const _CompareDateTime(this._time, this._matcher);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is DateTime &&
        _matcher.matches(item.compareTo(_time), <dynamic, dynamic>{});
  }

  @protected
  String get descriptionOperator;

  @override
  Description describe(Description description) =>
      description.add('a DateTime $descriptionOperator $_time');

  @protected
  String get mismatchAdjective;

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is DateTime) {
      Duration diff = item.difference(_time).abs();
      return description.add('is $mismatchAdjective $_time by $diff');
    } else {
      return description.add('is not a DateTime');
    }
  }
}

class _IsSameOrBefore extends _CompareDateTime {
  const _IsSameOrBefore(DateTime time) : super(time, isNonPositive);

  @override
  String get descriptionOperator => '<=';

  @override
  String get mismatchAdjective => 'after';
}

class _IsSameOrAfter extends _CompareDateTime {
  const _IsSameOrAfter(DateTime time) : super(time, isNonNegative);

  @override
  String get descriptionOperator => '>=';

  @override
  String get mismatchAdjective => 'before';
}
