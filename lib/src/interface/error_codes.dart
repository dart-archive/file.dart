// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.interface;

/// Operating system error codes.
class ErrorCodes {
  ErrorCodes._();

  /// Argument list too long
  // ignore: non_constant_identifier_names
  static int get E2BIG => _platform((_Codes codes) => codes.e2big);

  /// Permission denied
  // ignore: non_constant_identifier_names
  static int get EACCES => _platform((_Codes codes) => codes.eacces);

  /// Try again
  // ignore: non_constant_identifier_names
  static int get EAGAIN => _platform((_Codes codes) => codes.eagain);

  /// Bad file number
  // ignore: non_constant_identifier_names
  static int get EBADF => _platform((_Codes codes) => codes.ebadf);

  /// Device or resource busy
  // ignore: non_constant_identifier_names
  static int get EBUSY => _platform((_Codes codes) => codes.ebusy);

  /// No child processes
  // ignore: non_constant_identifier_names
  static int get ECHILD => _platform((_Codes codes) => codes.echild);

  /// Resource deadlock would occur
  // ignore: non_constant_identifier_names
  static int get EDEADLK => _platform((_Codes codes) => codes.edeadlk);

  /// Math argument out of domain of func
  // ignore: non_constant_identifier_names
  static int get EDOM => _platform((_Codes codes) => codes.edom);

  /// File exists
  // ignore: non_constant_identifier_names
  static int get EEXIST => _platform((_Codes codes) => codes.eexist);

  /// Bad address
  // ignore: non_constant_identifier_names
  static int get EFAULT => _platform((_Codes codes) => codes.efault);

  /// File too large
  // ignore: non_constant_identifier_names
  static int get EFBIG => _platform((_Codes codes) => codes.efbig);

  /// Illegal byte sequence
  // ignore: non_constant_identifier_names
  static int get EILSEQ => _platform((_Codes codes) => codes.eilseq);

  /// Interrupted system call
  // ignore: non_constant_identifier_names
  static int get EINTR => _platform((_Codes codes) => codes.eintr);

  /// Invalid argument
  // ignore: non_constant_identifier_names
  static int get EINVAL => _platform((_Codes codes) => codes.einval);

  /// I/O error
  // ignore: non_constant_identifier_names
  static int get EIO => _platform((_Codes codes) => codes.eio);

  /// Is a directory
  // ignore: non_constant_identifier_names
  static int get EISDIR => _platform((_Codes codes) => codes.eisdir);

  /// Too many levels of symbolic links
  // ignore: non_constant_identifier_names
  static int get ELOOP => _platform((_Codes codes) => codes.eloop);

  /// Too many open files
  // ignore: non_constant_identifier_names
  static int get EMFILE => _platform((_Codes codes) => codes.emfile);

  /// Too many links
  // ignore: non_constant_identifier_names
  static int get EMLINK => _platform((_Codes codes) => codes.emlink);

  /// File name too long
  // ignore: non_constant_identifier_names
  static int get ENAMETOOLONG => _platform((_Codes codes) => codes.enametoolong);

  /// File table overflow
  // ignore: non_constant_identifier_names
  static int get ENFILE => _platform((_Codes codes) => codes.enfile);

  /// No such device
  // ignore: non_constant_identifier_names
  static int get ENODEV => _platform((_Codes codes) => codes.enodev);

  /// No such file or directory
  // ignore: non_constant_identifier_names
  static int get ENOENT => _platform((_Codes codes) => codes.enoent);

  /// Exec format error
  // ignore: non_constant_identifier_names
  static int get ENOEXEC => _platform((_Codes codes) => codes.enoexec);

  /// No record locks available
  // ignore: non_constant_identifier_names
  static int get ENOLCK => _platform((_Codes codes) => codes.enolck);

  /// Out of memory
  // ignore: non_constant_identifier_names
  static int get ENOMEM => _platform((_Codes codes) => codes.enomem);

  /// No space left on device
  // ignore: non_constant_identifier_names
  static int get ENOSPC => _platform((_Codes codes) => codes.enospc);

  /// Function not implemented
  // ignore: non_constant_identifier_names
  static int get ENOSYS => _platform((_Codes codes) => codes.enosys);

  /// Not a directory
  // ignore: non_constant_identifier_names
  static int get ENOTDIR => _platform((_Codes codes) => codes.enotdir);

  /// Directory not empty
  // ignore: non_constant_identifier_names
  static int get ENOTEMPTY => _platform((_Codes codes) => codes.enotempty);

  /// Not a typewriter
  // ignore: non_constant_identifier_names
  static int get ENOTTY => _platform((_Codes codes) => codes.enotty);

  /// No such device or address
  // ignore: non_constant_identifier_names
  static int get ENXIO => _platform((_Codes codes) => codes.enxio);

  /// Operation not permitted
  // ignore: non_constant_identifier_names
  static int get EPERM => _platform((_Codes codes) => codes.eperm);

  /// Broken pipe
  // ignore: non_constant_identifier_names
  static int get EPIPE => _platform((_Codes codes) => codes.epipe);

  /// Math result not representable
  // ignore: non_constant_identifier_names
  static int get ERANGE => _platform((_Codes codes) => codes.erange);

  /// Read-only file system
  // ignore: non_constant_identifier_names
  static int get EROFS => _platform((_Codes codes) => codes.erofs);

  /// Illegal seek
  // ignore: non_constant_identifier_names
  static int get ESPIPE => _platform((_Codes codes) => codes.espipe);

  /// No such process
  // ignore: non_constant_identifier_names
  static int get ESRCH => _platform((_Codes codes) => codes.esrch);

  /// Cross-device link
  // ignore: non_constant_identifier_names
  static int get EXDEV => _platform((_Codes codes) => codes.exdev);

  static int _platform(int getCode(_Codes codes)) {
    _Codes codes = _platforms['macos']; // TODO(tvolkert): switch on platform
    return getCode(codes);
  }
}

const Map<String, _Codes> _platforms = const <String, _Codes>{
  'linux': const _LinuxCodes(),
  'macos': const _MacOSCodes(),
  'windows': const _WindowsCodes(),
};

abstract class _Codes {
  int get e2big;
  int get eacces;
  int get eagain;
  int get ebadf;
  int get ebusy;
  int get echild;
  int get edeadlk;
  int get edom;
  int get eexist;
  int get efault;
  int get efbig;
  int get eilseq;
  int get eintr;
  int get einval;
  int get eio;
  int get eisdir;
  int get eloop;
  int get emfile;
  int get emlink;
  int get enametoolong;
  int get enfile;
  int get enodev;
  int get enoent;
  int get enoexec;
  int get enolck;
  int get enomem;
  int get enospc;
  int get enosys;
  int get enotdir;
  int get enotempty;
  int get enotty;
  int get enxio;
  int get eperm;
  int get epipe;
  int get erange;
  int get erofs;
  int get espipe;
  int get esrch;
  int get exdev;
}

class _LinuxCodes implements _Codes {
  const _LinuxCodes();

  @override
  final int e2big = 7;

  @override
  final int eacces = 13;

  @override
  final int eagain = 11;

  @override
  final int ebadf = 9;

  @override
  final int ebusy = 16;

  @override
  final int echild = 10;

  @override
  final int edeadlk = 35;

  @override
  final int edom = 33;

  @override
  final int eexist = 17;

  @override
  final int efault = 14;

  @override
  final int efbig = 27;

  @override
  final int eilseq = 84;

  @override
  final int eintr = 4;

  @override
  final int einval = 22;

  @override
  final int eio = 5;

  @override
  final int eisdir = 21;

  @override
  final int eloop = 40;

  @override
  final int emfile = 24;

  @override
  final int emlink = 31;

  @override
  final int enametoolong = 36;

  @override
  final int enfile = 23;

  @override
  final int enodev = 19;

  @override
  final int enoent = 2;

  @override
  final int enoexec = 8;

  @override
  final int enolck = 37;

  @override
  final int enomem = 12;

  @override
  final int enospc = 28;

  @override
  final int enosys = 38;

  @override
  final int enotdir = 20;

  @override
  final int enotempty = 39;

  @override
  final int enotty = 25;

  @override
  final int enxio = 6;

  @override
  final int eperm = 1;

  @override
  final int epipe = 32;

  @override
  final int erange = 34;

  @override
  final int erofs = 30;

  @override
  final int espipe = 29;

  @override
  final int esrch = 3;

  @override
  final int exdev = 18;
}

class _MacOSCodes implements _Codes {
  const _MacOSCodes();

  @override
  final int e2big = 7;

  @override
  final int eacces = 13;

  @override
  final int eagain = 35;

  @override
  final int ebadf = 9;

  @override
  final int ebusy = 16;

  @override
  final int echild = 10;

  @override
  final int edeadlk = 11;

  @override
  final int edom = 33;

  @override
  final int eexist = 17;

  @override
  final int efault = 14;

  @override
  final int efbig = 27;

  @override
  final int eilseq = 92;

  @override
  final int eintr = 4;

  @override
  final int einval = 22;

  @override
  final int eio = 5;

  @override
  final int eisdir = 21;

  @override
  final int eloop = 62;

  @override
  final int emfile = 24;

  @override
  final int emlink = 31;

  @override
  final int enametoolong = 63;

  @override
  final int enfile = 23;

  @override
  final int enodev = 19;

  @override
  final int enoent = 2;

  @override
  final int enoexec = 8;

  @override
  final int enolck = 77;

  @override
  final int enomem = 12;

  @override
  final int enospc = 28;

  @override
  final int enosys = 78;

  @override
  final int enotdir = 20;

  @override
  final int enotempty = 66;

  @override
  final int enotty = 25;

  @override
  final int enxio = 6;

  @override
  final int eperm = 1;

  @override
  final int epipe = 32;

  @override
  final int erange = 34;

  @override
  final int erofs = 30;

  @override
  final int espipe = 29;

  @override
  final int esrch = 3;

  @override
  final int exdev = 18;
}

class _WindowsCodes implements _Codes {
  const _WindowsCodes();

  @override
  final int e2big = 7;

  @override
  final int eacces = 13;

  @override
  final int eagain = 11;

  @override
  final int ebadf = 9;

  @override
  final int ebusy = 16;

  @override
  final int echild = 10;

  @override
  final int edeadlk = 36;

  @override
  final int edom = 33;

  @override
  final int eexist = 17;

  @override
  final int efault = 14;

  @override
  final int efbig = 27;

  @override
  final int eilseq = 42;

  @override
  final int eintr = 4;

  @override
  final int einval = 22;

  @override
  final int eio = 5;

  @override
  final int eisdir = 21;

  @override
  final int eloop = -1;

  @override
  final int emfile = 24;

  @override
  final int emlink = 31;

  @override
  final int enametoolong = 38;

  @override
  final int enfile = 23;

  @override
  final int enodev = 19;

  @override
  final int enoent = 2;

  @override
  final int enoexec = 8;

  @override
  final int enolck = 39;

  @override
  final int enomem = 12;

  @override
  final int enospc = 28;

  @override
  final int enosys = 40;

  @override
  final int enotdir = 20;

  @override
  final int enotempty = 41;

  @override
  final int enotty = 25;

  @override
  final int enxio = 6;

  @override
  final int eperm = 1;

  @override
  final int epipe = 32;

  @override
  final int erange = 34;

  @override
  final int erofs = 30;

  @override
  final int espipe = 29;

  @override
  final int esrch = 3;

  @override
  final int exdev = 18;
}
