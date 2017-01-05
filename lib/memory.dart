/// An implementation of [FileSystem] that exists entirely in memory with an
/// internal representation loosely based on the Filesystem Hierarchy Standard.
/// [MemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
export 'src/backends/memory.dart';
