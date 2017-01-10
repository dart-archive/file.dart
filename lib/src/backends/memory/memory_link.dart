// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.memory;

class _MemoryLink extends _MemoryFileSystemEntity implements Link {
  _MemoryLink(MemoryFileSystem fileSystem, String path)
      : super(fileSystem, path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.LINK;

  @override
  bool existsSync() => _backingOrNull?.type == expectedType;

  @override
  Future<Link> rename(String newPath) async => renameSync(newPath);

  @override
  Link renameSync(String newPath) => _renameSync(
        newPath,
        checkType: (_Node node) {
          if (node.type != expectedType) {
            throw new FileSystemException(
                node.type == FileSystemEntityType.DIRECTORY
                    ? 'Is a directory'
                    : 'Invalid argument');
          }
        },
      );

  @override
  Future<Link> create(String target, {bool recursive: false}) async {
    createSync(target, recursive: recursive);
    return this;
  }

  @override
  void createSync(String target, {bool recursive: false}) {
    bool preexisting = true;
    _createSync(createChild: (_DirectoryNode parent, bool isFinalSegment) {
      if (isFinalSegment) {
        preexisting = false;
        return new _LinkNode(parent, target);
      } else if (recursive) {
        return new _DirectoryNode(parent);
      }
      return null;
    });
    if (preexisting) {
      // Per the spec, this is an error.
      throw new io.FileSystemException('File exists', path);
    }
  }

  @override
  Future<Link> update(String target) async {
    updateSync(target);
    return this;
  }

  @override
  void updateSync(String target) {
    _Node node = _backing;
    _checkType(expectedType, node.type, () => path);
    (node as _LinkNode).target = target;
  }

  @override
  void deleteSync({bool recursive: false}) => _deleteSync(
        recursive: recursive,
        checkType: (_Node node) =>
            _checkType(expectedType, node.type, () => path),
      );

  @override
  Future<String> target() async => targetSync();

  @override
  String targetSync() {
    _Node node = _backing;
    if (node.type != expectedType) {
      // Note: this may change; https://github.com/dart-lang/sdk/issues/28204
      throw new FileSystemException('No such file or directory', path);
    }
    return (node as _LinkNode).target;
  }

  @override
  Link get absolute => super.absolute;

  @override
  Link _clone(String path) => new _MemoryLink(fileSystem, path);
}
