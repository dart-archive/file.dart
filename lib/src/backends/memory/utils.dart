// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// Validator function that is expected to throw a [FileSystemException] if
/// the node does not represent the type that is expected in any given context.
typedef void _TypeChecker(_Node node);

/// Throws a [io.FileSystemException] if [node] is null.
void _checkExists(_Node node, _PathGenerator path) {
  if (node == null) {
    throw common.noSuchFileOrDirectory(path());
  }
}

/// Throws a [io.FileSystemException] if [node] is not a directory.
void _checkIsDir(_Node node, _PathGenerator path) {
  if (!_isDirectory(node)) {
    throw common.notADirectory(path());
  }
}

/// Throws a [io.FileSystemException] if [expectedType] doesn't match
/// [actualType].
void _checkType(
  FileSystemEntityType expectedType,
  FileSystemEntityType actualType,
  _PathGenerator path,
) {
  if (expectedType != actualType) {
    switch (expectedType) {
      case FileSystemEntityType.DIRECTORY:
        throw common.notADirectory(path());
      case FileSystemEntityType.FILE:
        assert(actualType == FileSystemEntityType.DIRECTORY);
        throw common.isADirectory(path());
      case FileSystemEntityType.LINK:
        throw common.invalidArgument(path());
      default:
        // Should not happen
        throw new AssertionError();
    }
  }
}

/// Tells if the specified file mode represents a write mode.
bool _isWriteMode(io.FileMode mode) =>
    mode == io.FileMode.WRITE ||
    mode == io.FileMode.APPEND ||
    mode == io.FileMode.WRITE_ONLY ||
    mode == io.FileMode.WRITE_ONLY_APPEND;

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
/// [FileSystemException], calling [path] to generate the path.
///
/// If [ledger] is specified, the resolved path to the terminal node will be
/// appended to the ledger (or overwritten in the ledger if a link target
/// specified an absolute path). The path will not be normalized, meaning
/// `..` and `.` path segments may be present.
///
/// If [tailVisitor] is specified, it will be invoked for the tail element of
/// the last link in the symbolic link chain, and its return value will be the
/// return value of this method (thus allowing callers to create the entity
/// at the end of the chain on demand).
_Node _resolveLinks(
  _LinkNode link,
  _PathGenerator path, {
  List<String> ledger,
  _Node tailVisitor(_DirectoryNode parent, String childName, _Node child),
}) {
  // Record a breadcrumb trail to guard against symlink loops.
  Set<_LinkNode> breadcrumbs = new Set<_LinkNode>();

  _Node node = link;
  while (_isLink(node)) {
    link = node;
    if (!breadcrumbs.add(node)) {
      throw common.tooManyLevelsOfSymbolicLinks(path());
    }
    if (ledger != null) {
      if (_isAbsolute(link.target)) {
        ledger.clear();
      } else if (ledger.isNotEmpty) {
        ledger.removeLast();
      }
      ledger.addAll(link.target.split(_separator));
    }
    node = link.getReferent(
      tailVisitor: (_DirectoryNode parent, String childName, _Node child) {
        if (tailVisitor != null && !_isLink(child)) {
          // Only invoke [tailListener] on the final resolution pass.
          child = tailVisitor(parent, childName, child);
        }
        return child;
      },
    );
  }

  return node;
}
