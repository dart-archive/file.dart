// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.memory;

class _MemoryFileStat implements io.FileStat {
  static const _MemoryFileStat _notFound =
      const _MemoryFileStat._internalNotFound();

  @override
  final DateTime changed;

  @override
  final DateTime modified;

  @override
  final DateTime accessed;

  @override
  final io.FileSystemEntityType type;

  @override
  final int mode;

  @override
  final int size;

  _MemoryFileStat(
    this.changed,
    this.modified,
    this.accessed,
    this.type,
    this.mode,
    this.size,
  );

  const _MemoryFileStat._internalNotFound()
      : changed = null,
        modified = null,
        accessed = null,
        type = io.FileSystemEntityType.NOT_FOUND,
        mode = 0,
        size = -1;

  @override
  String modeString() {
    int permissions = mode & 0xFFF;
    List<String> codes = const <String>[
      '---',
      '--x',
      '-w-',
      '-wx',
      'r--',
      'r-x',
      'rw-',
      'rwx',
    ];
    List<String> result = <String>[];
    result
      ..add(codes[(permissions >> 6) & 0x7])
      ..add(codes[(permissions >> 3) & 0x7])
      ..add(codes[permissions & 0x7]);
    return result.join();
  }
}
