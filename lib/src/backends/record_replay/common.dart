// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

/// Encoded value of the file system in a recording.
const String _kFileSystemEncodedValue = '__fs__';

const String _kManifestName = 'MANIFEST.txt';

/// Gets an id guaranteed to be unique on this isolate for objects within this
/// library.
int get _uid => __nextUid++;
int __nextUid = 1;

/// Gets the name of the specified [symbol].
// TODO(tvolkert): Symbol.name (https://github.com/dart-lang/sdk/issues/28372)
String _getSymbolName(Symbol symbol) {
  return new RegExp(r'Symbol\("(.*)"\)').firstMatch(symbol.toString()).group(1);
}
