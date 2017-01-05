/// A file system implementation that provides a view onto another file
/// system, taking a path in the underlying file system, and making that the
/// apparent root of the new file system. This is similar in concept to a
/// `chroot` operation on Linux operating systems. Such a modified file system
/// cannot name (and therefore normally cannot access) files outside the
/// designated directory tree.
export 'src/backends/chroot.dart';
