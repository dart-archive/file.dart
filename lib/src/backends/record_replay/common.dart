// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Encoded value of the file system in a recording.
const String kFileSystemEncodedValue = '__fs__';

/// The name of the recording manifest file.
const String kManifestName = 'MANIFEST.txt';

/// Gets an id guaranteed to be unique on this isolate for objects within this
/// library.
int newUid() => _nextUid++;
int _nextUid = 1;

/// Gets the name of the specified [symbol].
// TODO(tvolkert): Symbol.name (https://github.com/dart-lang/sdk/issues/28372)
String getSymbolName(Symbol symbol) {
  // Format of `str` is `Symbol("<name>")`
  String str = symbol.toString();
  int offset = str.indexOf('"') + 1;
  return str.substring(offset, str.indexOf('"', offset));
}
