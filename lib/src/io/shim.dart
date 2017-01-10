// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// For internal use only!
///
/// This exposes the handful of static methods required by the local backend.
/// For browser contexts, these methods will all throw `UnsupportedError`.
/// For VM contexts, they all delegate to the underlying methods in `dart:io`.
export 'shim_internal.dart' if (dart.library.io) 'shim_dart_io.dart';
