// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'src/backends/memory.dart';
import 'src/interface.dart';

/// An implementation of [FileSystem] that exists entirely in memory with an
/// internal representation loosely based on the Filesystem Hierarchy Standard.
/// [MemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
export 'src/backends/memory.dart';
