part of file.src.backends.memory;

/// Checks if `node.type` returns [io.FileSystemEntityType.FILE].
bool _isFile(_Node node) => node?.type == io.FileSystemEntityType.FILE;

/// Checks if `node.type` returns [io.FileSystemEntityType.DIRECTORY].
bool _isDirectory(_Node node) =>
    node?.type == io.FileSystemEntityType.DIRECTORY;

/// Checks if `node.type` returns [io.FileSystemEntityType.LINK].
bool _isLink(_Node node) => node?.type == io.FileSystemEntityType.LINK;

/// Tells whether the specified path represents an absolute path.
bool _isAbsolute(String path) => path.startsWith(_separator);

/// Generates a path to use in error messages.
typedef dynamic _PathGenerator();

/// Throws a [io.FileSystemException] if [node] is null.
void _checkExists(_Node node, _PathGenerator path) {
  if (node == null) {
    throw new io.FileSystemException('No such file or directory', path());
  }
}

/// Throws a [io.FileSystemException] if [node] is not a directory.
void _checkIsDir(_Node node, _PathGenerator path) {
  if (!_isDirectory(node)) {
    throw new io.FileSystemException('Not a directory', path());
  }
}

/// Returns a [_PathGenerator] that generates a subpath of the constituent
/// [parts] (from [start]..[end], inclusive).
_PathGenerator _subpath(List<String> parts, int start, int end) {
  return () => parts.sublist(start, end + 1).join(_separator);
}

/// Tells whether the given string is empty.
bool _isEmpty(String str) => str.isEmpty;

/// Returns the node ultimately referred to by [link]. This will resolve
/// the link references (following chains of links as necessary) and return
/// the node at the end of the link chain.
///
/// If a loop in the link chain is found, this will throw a
/// [io.FileSystemException], calling [path] to generate the path.
///
/// If [ledger] is specified, the resolved path to the terminal node will be
/// appended to the ledger (or overwritten in the ledger if a link target
/// specified an absolute path). The path will not be normalized, meaning
/// `..` and `.` path segments may be present.
_Node _resolveLinks(
  _LinkNode link,
  _PathGenerator path, {
  List<String> ledger,
}) {
  // Record a breadcrumb trail to guard against symlink loops.
  Set<_LinkNode> breadcrumbs = new Set<_LinkNode>();

  _Node node = link;
  while (_isLink(node)) {
    link = node;
    if (!breadcrumbs.add(node)) {
      throw new io.FileSystemException('Loop found in link chain', path());
    }
    if (ledger != null) {
      if (_isAbsolute(link.target)) {
        ledger.clear();
      } else if (ledger.isNotEmpty) {
        ledger.removeLast();
      }
      ledger.addAll(link.target.split(_separator));
    }
    node = link.referent;
  }

  return node;
}
