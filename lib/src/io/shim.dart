/// For internal use only!
///
/// This exposes the handful of static methods required by the local backend.
/// For browser contexts, these methods will all throw `UnsupportedError`.
/// For VM contexts, they all delegate to the underlying methods in `dart:io`.
export 'shim_internal.dart' if (dart.library.io) 'shim_dart_io.dart';
