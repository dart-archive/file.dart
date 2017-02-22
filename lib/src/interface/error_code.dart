// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.interface;

/// Operating system error codes.
abstract class ErrorCodes {
  ErrorCodes._();

  /// TODO
  static ErrorCodes get linux => const _LinuxErrorCodes();

  /// TODO
  static ErrorCodes get macos => const _MacosErrorCodes();

  /// Operation not permitted
  int get EPERM; // ignore: non_constant_identifier_names

  /// No such file or directory
  int get ENOENT; // ignore: non_constant_identifier_names

  /// No such process
  int get ESRCH; // ignore: non_constant_identifier_names

  /// Interrupted system call
  int get EINTR; // ignore: non_constant_identifier_names

  /// I/O error
  int get EIO; // ignore: non_constant_identifier_names

  /// No such device or address
  int get ENXIO; // ignore: non_constant_identifier_names

  /// Argument list too long
  int get E2BIG; // ignore: non_constant_identifier_names

  /// Exec format error
  int get ENOEXEC; // ignore: non_constant_identifier_names

  /// Bad file number
  int get EBADF; // ignore: non_constant_identifier_names

  /// No child processes
  int get ECHILD; // ignore: non_constant_identifier_names

  /// Try again
  int get EAGAIN; // ignore: non_constant_identifier_names

  /// Out of memory
  int get ENOMEM; // ignore: non_constant_identifier_names

  /// Permission denied
  int get EACCES; // ignore: non_constant_identifier_names

  /// Bad address
  int get EFAULT; // ignore: non_constant_identifier_names

  /// Block device required
  int get ENOTBLK; // ignore: non_constant_identifier_names

  /// Device or resource busy
  int get EBUSY; // ignore: non_constant_identifier_names

  /// File exists
  int get EEXIST; // ignore: non_constant_identifier_names

  /// Cross-device link
  int get EXDEV; // ignore: non_constant_identifier_names

  /// No such device
  int get ENODEV; // ignore: non_constant_identifier_names

  /// Not a directory
  int get ENOTDIR; // ignore: non_constant_identifier_names

  /// Is a directory
  int get EISDIR; // ignore: non_constant_identifier_names

  /// Invalid argument
  int get EINVAL; // ignore: non_constant_identifier_names

  /// File table overflow
  int get ENFILE; // ignore: non_constant_identifier_names

  /// Too many open files
  int get EMFILE; // ignore: non_constant_identifier_names

  /// Not a typewriter
  int get ENOTTY; // ignore: non_constant_identifier_names

  /// Text file busy
  int get ETXTBSY; // ignore: non_constant_identifier_names

  /// File too large
  int get EFBIG; // ignore: non_constant_identifier_names

  /// No space left on device
  int get ENOSPC; // ignore: non_constant_identifier_names

  /// Illegal seek
  int get ESPIPE; // ignore: non_constant_identifier_names

  /// Read-only file system
  int get EROFS; // ignore: non_constant_identifier_names

  /// Too many links
  int get EMLINK; // ignore: non_constant_identifier_names

  /// Broken pipe
  int get EPIPE; // ignore: non_constant_identifier_names

  /// Math argument out of domain of func
  int get EDOM; // ignore: non_constant_identifier_names

  /// Math result not representable
  int get ERANGE; // ignore: non_constant_identifier_names

  /// File name too long
  int get ENAMETOOLONG; // ignore: non_constant_identifier_names

  /// No record locks available
  int get ENOLCK; // ignore: non_constant_identifier_names

  /// Function not implemented
  int get ENOSYS; // ignore: non_constant_identifier_names

  /// Directory not empty
  int get ENOTEMPTY; // ignore: non_constant_identifier_names

  /// Too many symbolic links encountered
  int get ELOOP; // ignore: non_constant_identifier_names

  /// Operation would block
  int get EWOULDBLOCK; // ignore: non_constant_identifier_names

  /// No message of desired type
  int get ENOMSG; // ignore: non_constant_identifier_names

  /// Identifier removed
  int get EIDRM; // ignore: non_constant_identifier_names

  /// Device not a stream
  int get ENOSTR; // ignore: non_constant_identifier_names

  /// No data available
  int get ENODATA; // ignore: non_constant_identifier_names

  /// Timer expired
  int get ETIME; // ignore: non_constant_identifier_names

  /// Out of streams resources
  int get ENOSR; // ignore: non_constant_identifier_names

  /// Object is remote
  int get EREMOTE; // ignore: non_constant_identifier_names

  /// Link has been severed
  int get ENOLINK; // ignore: non_constant_identifier_names

  /// Protocol error
  int get EPROTO; // ignore: non_constant_identifier_names

  /// Multihop attempted
  int get EMULTIHOP; // ignore: non_constant_identifier_names

  /// Not a data message
  int get EBADMSG; // ignore: non_constant_identifier_names

  /// Value too large for defined data type
  int get EOVERFLOW; // ignore: non_constant_identifier_names

  /// Illegal byte sequence
  int get EILSEQ; // ignore: non_constant_identifier_names

  /// Too many users
  int get EUSERS; // ignore: non_constant_identifier_names

  /// Socket operation on non-socket
  int get ENOTSOCK; // ignore: non_constant_identifier_names

  /// Destination address required
  int get EDESTADDRREQ; // ignore: non_constant_identifier_names

  /// Message too long
  int get EMSGSIZE; // ignore: non_constant_identifier_names

  /// Protocol wrong type for socket
  int get EPROTOTYPE; // ignore: non_constant_identifier_names

  /// Protocol not available
  int get ENOPROTOOPT; // ignore: non_constant_identifier_names

  /// Protocol not supported
  int get EPROTONOSUPPORT; // ignore: non_constant_identifier_names

  /// Socket type not supported
  int get ESOCKTNOSUPPORT; // ignore: non_constant_identifier_names

  /// Protocol family not supported
  int get EPFNOSUPPORT; // ignore: non_constant_identifier_names

  /// Address family not supported by protocol
  int get EAFNOSUPPORT; // ignore: non_constant_identifier_names

  /// Address already in use
  int get EADDRINUSE; // ignore: non_constant_identifier_names

  /// Cannot assign requested address
  int get EADDRNOTAVAIL; // ignore: non_constant_identifier_names

  /// Network is down
  int get ENETDOWN; // ignore: non_constant_identifier_names

  /// Network is unreachable
  int get ENETUNREACH; // ignore: non_constant_identifier_names

  /// Network dropped connection because of reset
  int get ENETRESET; // ignore: non_constant_identifier_names

  /// Software caused connection abort
  int get ECONNABORTED; // ignore: non_constant_identifier_names

  /// Connection reset by peer
  int get ECONNRESET; // ignore: non_constant_identifier_names

  /// No buffer space available
  int get ENOBUFS; // ignore: non_constant_identifier_names

  /// Transport endpoint is already connected
  int get EISCONN; // ignore: non_constant_identifier_names

  /// Transport endpoint is not connected
  int get ENOTCONN; // ignore: non_constant_identifier_names

  /// Cannot send after transport endpoint shutdown
  int get ESHUTDOWN; // ignore: non_constant_identifier_names

  /// Too many references: cannot splice
  int get ETOOMANYREFS; // ignore: non_constant_identifier_names

  /// Connection timed out
  int get ETIMEDOUT; // ignore: non_constant_identifier_names

  /// Connection refused
  int get ECONNREFUSED; // ignore: non_constant_identifier_names

  /// Host is down
  int get EHOSTDOWN; // ignore: non_constant_identifier_names

  /// No route to host
  int get EHOSTUNREACH; // ignore: non_constant_identifier_names

  /// Operation already in progress
  int get EALREADY; // ignore: non_constant_identifier_names

  /// Operation now in progress
  int get EINPROGRESS; // ignore: non_constant_identifier_names

  /// Stale NFS file handle
  int get ESTALE; // ignore: non_constant_identifier_names

  /// Quota exceeded
  int get EDQUOT; // ignore: non_constant_identifier_names

  /// Operation Canceled
  int get ECANCELED; // ignore: non_constant_identifier_names
}

class _LinuxErrorCodes implements ErrorCodes {
  const _LinuxErrorCodes();

  @override
  final int EPERM = 1; // ignore: non_constant_identifier_names

  @override
  final int ENOENT = 2; // ignore: non_constant_identifier_names

  @override
  final int ESRCH = 3; // ignore: non_constant_identifier_names

  @override
  final int EINTR = 4; // ignore: non_constant_identifier_names

  @override
  final int EIO = 5; // ignore: non_constant_identifier_names

  @override
  final int ENXIO = 6; // ignore: non_constant_identifier_names

  @override
  final int E2BIG = 7; // ignore: non_constant_identifier_names

  @override
  final int ENOEXEC = 8; // ignore: non_constant_identifier_names

  @override
  final int EBADF = 9; // ignore: non_constant_identifier_names

  @override
  final int ECHILD = 10; // ignore: non_constant_identifier_names

  @override
  final int EAGAIN = 11; // ignore: non_constant_identifier_names

  @override
  final int ENOMEM = 12; // ignore: non_constant_identifier_names

  @override
  final int EACCES = 13; // ignore: non_constant_identifier_names

  @override
  final int EFAULT = 14; // ignore: non_constant_identifier_names

  @override
  final int ENOTBLK = 15; // ignore: non_constant_identifier_names

  @override
  final int EBUSY = 16; // ignore: non_constant_identifier_names

  @override
  final int EEXIST = 17; // ignore: non_constant_identifier_names

  @override
  final int EXDEV = 18; // ignore: non_constant_identifier_names

  @override
  final int ENODEV = 19; // ignore: non_constant_identifier_names

  @override
  final int ENOTDIR = 20; // ignore: non_constant_identifier_names

  @override
  final int EISDIR = 21; // ignore: non_constant_identifier_names

  @override
  final int EINVAL = 22; // ignore: non_constant_identifier_names

  @override
  final int ENFILE = 23; // ignore: non_constant_identifier_names

  @override
  final int EMFILE = 24; // ignore: non_constant_identifier_names

  @override
  final int ENOTTY = 25; // ignore: non_constant_identifier_names

  @override
  final int ETXTBSY = 26; // ignore: non_constant_identifier_names

  @override
  final int EFBIG = 27; // ignore: non_constant_identifier_names

  @override
  final int ENOSPC = 28; // ignore: non_constant_identifier_names

  @override
  final int ESPIPE = 29; // ignore: non_constant_identifier_names

  @override
  final int EROFS = 30; // ignore: non_constant_identifier_names

  @override
  final int EMLINK = 31; // ignore: non_constant_identifier_names

  @override
  final int EPIPE = 32; // ignore: non_constant_identifier_names

  @override
  final int EDOM = 33; // ignore: non_constant_identifier_names

  @override
  final int ERANGE = 34; // ignore: non_constant_identifier_names

  @override
  final int ENAMETOOLONG = 36; // ignore: non_constant_identifier_names

  @override
  final int ENOLCK = 37; // ignore: non_constant_identifier_names

  @override
  final int ENOSYS = 38; // ignore: non_constant_identifier_names

  @override
  final int ENOTEMPTY = 39; // ignore: non_constant_identifier_names

  @override
  final int ELOOP = 40; // ignore: non_constant_identifier_names

  @override
  final int EWOULDBLOCK = 11/*EAGAIN*/; // ignore: non_constant_identifier_names

  @override
  final int ENOMSG = 42; // ignore: non_constant_identifier_names

  @override
  final int EIDRM = 43; // ignore: non_constant_identifier_names

  @override
  final int ENOSTR = 60; // ignore: non_constant_identifier_names

  @override
  final int ENODATA = 61; // ignore: non_constant_identifier_names

  @override
  final int ETIME = 62; // ignore: non_constant_identifier_names

  @override
  final int ENOSR = 63; // ignore: non_constant_identifier_names

  @override
  final int EREMOTE = 66; // ignore: non_constant_identifier_names

  @override
  final int ENOLINK = 67; // ignore: non_constant_identifier_names

  @override
  final int EPROTO = 71; // ignore: non_constant_identifier_names

  @override
  final int EMULTIHOP = 72; // ignore: non_constant_identifier_names

  @override
  final int EBADMSG = 74; // ignore: non_constant_identifier_names

  @override
  final int EOVERFLOW = 75; // ignore: non_constant_identifier_names

  @override
  final int EILSEQ = 84; // ignore: non_constant_identifier_names

  @override
  final int EUSERS = 87; // ignore: non_constant_identifier_names

  @override
  final int ENOTSOCK = 88; // ignore: non_constant_identifier_names

  @override
  final int EDESTADDRREQ = 89; // ignore: non_constant_identifier_names

  @override
  final int EMSGSIZE = 90; // ignore: non_constant_identifier_names

  @override
  final int EPROTOTYPE = 91; // ignore: non_constant_identifier_names

  @override
  final int ENOPROTOOPT = 92; // ignore: non_constant_identifier_names

  @override
  final int EPROTONOSUPPORT = 93; // ignore: non_constant_identifier_names

  @override
  final int ESOCKTNOSUPPORT = 94; // ignore: non_constant_identifier_names

  @override
  final int EPFNOSUPPORT = 96; // ignore: non_constant_identifier_names

  @override
  final int EAFNOSUPPORT = 97; // ignore: non_constant_identifier_names

  @override
  final int EADDRINUSE = 98; // ignore: non_constant_identifier_names

  @override
  final int EADDRNOTAVAIL = 99; // ignore: non_constant_identifier_names

  @override
  final int ENETDOWN = 100; // ignore: non_constant_identifier_names

  @override
  final int ENETUNREACH = 101; // ignore: non_constant_identifier_names

  @override
  final int ENETRESET = 102; // ignore: non_constant_identifier_names

  @override
  final int ECONNABORTED = 103; // ignore: non_constant_identifier_names

  @override
  final int ECONNRESET = 104; // ignore: non_constant_identifier_names

  @override
  final int ENOBUFS = 105; // ignore: non_constant_identifier_names

  @override
  final int EISCONN = 106; // ignore: non_constant_identifier_names

  @override
  final int ENOTCONN = 107; // ignore: non_constant_identifier_names

  @override
  final int ESHUTDOWN = 108; // ignore: non_constant_identifier_names

  @override
  final int ETOOMANYREFS = 109; // ignore: non_constant_identifier_names

  @override
  final int ETIMEDOUT = 110; // ignore: non_constant_identifier_names

  @override
  final int ECONNREFUSED = 111; // ignore: non_constant_identifier_names

  @override
  final int EHOSTDOWN = 112; // ignore: non_constant_identifier_names

  @override
  final int EHOSTUNREACH = 113; // ignore: non_constant_identifier_names

  @override
  final int EALREADY = 114; // ignore: non_constant_identifier_names

  @override
  final int EINPROGRESS = 115; // ignore: non_constant_identifier_names

  @override
  final int ESTALE = 116; // ignore: non_constant_identifier_names

  @override
  final int EDQUOT = 122; // ignore: non_constant_identifier_names

  @override
  final int ECANCELED = 125; // ignore: non_constant_identifier_names
}

class _MacosErrorCodes implements ErrorCodes {
  const _MacosErrorCodes();

  @override
  final int EPERM = 1; // ignore: non_constant_identifier_names

  @override
  final int ENOENT = 2; // ignore: non_constant_identifier_names

  @override
  final int ESRCH = 3; // ignore: non_constant_identifier_names

  @override
  final int EINTR = 4; // ignore: non_constant_identifier_names

  @override
  final int EIO = 5; // ignore: non_constant_identifier_names

  @override
  final int ENXIO = 6; // ignore: non_constant_identifier_names

  @override
  final int E2BIG = 7; // ignore: non_constant_identifier_names

  @override
  final int ENOEXEC = 8; // ignore: non_constant_identifier_names

  @override
  final int EBADF = 9; // ignore: non_constant_identifier_names

  @override
  final int ECHILD = 10; // ignore: non_constant_identifier_names

  @override
  final int ENOMEM = 12; // ignore: non_constant_identifier_names

  @override
  final int EACCES = 13; // ignore: non_constant_identifier_names

  @override
  final int EFAULT = 14; // ignore: non_constant_identifier_names

  @override
  final int ENOTBLK = 15; // ignore: non_constant_identifier_names

  @override
  final int EBUSY = 16; // ignore: non_constant_identifier_names

  @override
  final int EEXIST = 17; // ignore: non_constant_identifier_names

  @override
  final int EXDEV = 18; // ignore: non_constant_identifier_names

  @override
  final int ENODEV = 19; // ignore: non_constant_identifier_names

  @override
  final int ENOTDIR = 20; // ignore: non_constant_identifier_names

  @override
  final int EISDIR = 21; // ignore: non_constant_identifier_names

  @override
  final int EINVAL = 22; // ignore: non_constant_identifier_names

  @override
  final int ENFILE = 23; // ignore: non_constant_identifier_names

  @override
  final int EMFILE = 24; // ignore: non_constant_identifier_names

  @override
  final int ENOTTY = 25; // ignore: non_constant_identifier_names

  @override
  final int ETXTBSY = 26; // ignore: non_constant_identifier_names

  @override
  final int EFBIG = 27; // ignore: non_constant_identifier_names

  @override
  final int ENOSPC = 28; // ignore: non_constant_identifier_names

  @override
  final int ESPIPE = 29; // ignore: non_constant_identifier_names

  @override
  final int EROFS = 30; // ignore: non_constant_identifier_names

  @override
  final int EMLINK = 31; // ignore: non_constant_identifier_names

  @override
  final int EPIPE = 32; // ignore: non_constant_identifier_names

  @override
  final int EDOM = 33; // ignore: non_constant_identifier_names

  @override
  final int ERANGE = 34; // ignore: non_constant_identifier_names

  @override
  final int EAGAIN = 35; // ignore: non_constant_identifier_names

  @override
  final int EWOULDBLOCK = 35 /*EAGAIN*/; // ignore: non_constant_identifier_names

  @override
  final int EINPROGRESS = 36; // ignore: non_constant_identifier_names

  @override
  final int EALREADY = 37; // ignore: non_constant_identifier_names

  @override
  final int ENOTSOCK = 38; // ignore: non_constant_identifier_names

  @override
  final int EDESTADDRREQ = 39; // ignore: non_constant_identifier_names

  @override
  final int EMSGSIZE = 40; // ignore: non_constant_identifier_names

  @override
  final int EPROTOTYPE = 41; // ignore: non_constant_identifier_names

  @override
  final int ENOPROTOOPT = 42; // ignore: non_constant_identifier_names

  @override
  final int EPROTONOSUPPORT = 43; // ignore: non_constant_identifier_names

  @override
  final int ESOCKTNOSUPPORT = 44; // ignore: non_constant_identifier_names

  @override
  final int EPFNOSUPPORT = 46; // ignore: non_constant_identifier_names

  @override
  final int EAFNOSUPPORT = 47; // ignore: non_constant_identifier_names

  @override
  final int EADDRINUSE = 48; // ignore: non_constant_identifier_names

  @override
  final int EADDRNOTAVAIL = 49; // ignore: non_constant_identifier_names

  @override
  final int ENETDOWN = 50; // ignore: non_constant_identifier_names

  @override
  final int ENETUNREACH = 51; // ignore: non_constant_identifier_names

  @override
  final int ENETRESET = 52; // ignore: non_constant_identifier_names

  @override
  final int ECONNABORTED = 53; // ignore: non_constant_identifier_names

  @override
  final int ECONNRESET = 54; // ignore: non_constant_identifier_names

  @override
  final int ENOBUFS = 55; // ignore: non_constant_identifier_names

  @override
  final int EISCONN = 56; // ignore: non_constant_identifier_names

  @override
  final int ENOTCONN = 57; // ignore: non_constant_identifier_names

  @override
  final int ESHUTDOWN = 58; // ignore: non_constant_identifier_names

  @override
  final int ETOOMANYREFS = 59; // ignore: non_constant_identifier_names

  @override
  final int ETIMEDOUT = 60; // ignore: non_constant_identifier_names

  @override
  final int ECONNREFUSED = 61; // ignore: non_constant_identifier_names

  @override
  final int ELOOP = 62; // ignore: non_constant_identifier_names

  @override
  final int ENAMETOOLONG = 63; // ignore: non_constant_identifier_names

  @override
  final int EHOSTDOWN = 64; // ignore: non_constant_identifier_names

  @override
  final int EHOSTUNREACH = 65; // ignore: non_constant_identifier_names

  @override
  final int ENOTEMPTY = 66; // ignore: non_constant_identifier_names

  @override
  final int EUSERS = 68; // ignore: non_constant_identifier_names

  @override
  final int EDQUOT = 69; // ignore: non_constant_identifier_names

  @override
  final int ESTALE = 70; // ignore: non_constant_identifier_names

  @override
  final int EREMOTE = 71; // ignore: non_constant_identifier_names

  @override
  final int ENOLCK = 77; // ignore: non_constant_identifier_names

  @override
  final int ENOSYS = 78; // ignore: non_constant_identifier_names

  @override
  final int EOVERFLOW = 84; // ignore: non_constant_identifier_names

  @override
  final int ECANCELED = 89; // ignore: non_constant_identifier_names

  @override
  final int EIDRM = 90; // ignore: non_constant_identifier_names

  @override
  final int ENOMSG = 91; // ignore: non_constant_identifier_names

  @override
  final int EILSEQ = 92; // ignore: non_constant_identifier_names

  @override
  final int EBADMSG = 94; // ignore: non_constant_identifier_names

  @override
  final int EMULTIHOP = 95; // ignore: non_constant_identifier_names

  @override
  final int ENODATA = 96; // ignore: non_constant_identifier_names

  @override
  final int ENOLINK = 97; // ignore: non_constant_identifier_names

  @override
  final int ENOSR = 98; // ignore: non_constant_identifier_names

  @override
  final int ENOSTR = 99; // ignore: non_constant_identifier_names

  @override
  final int EPROTO = 100; // ignore: non_constant_identifier_names

  @override
  final int ETIME = 101; // ignore: non_constant_identifier_names
}
