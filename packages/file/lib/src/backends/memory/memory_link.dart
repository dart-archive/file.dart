// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

import 'memory_file_system_entity.dart';
import 'node.dart';
import 'utils.dart' as utils;

/// Internal implementation of [Link].
class MemoryLink extends MemoryFileSystemEntity implements Link {
  /// Instantiates a new [MemoryLink].
  const MemoryLink(NodeBasedFileSystem fileSystem, String path)
      : super(fileSystem, path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.LINK;

  @override
  bool existsSync() => backingOrNull?.type == expectedType;

  @override
  Future<Link> rename(String newPath) async => renameSync(newPath);

  @override
  Link renameSync(String newPath) => internalRenameSync(
        newPath,
        checkType: (Node node) {
          if (node.type != expectedType) {
            throw node.type == FileSystemEntityType.DIRECTORY
                ? common.isADirectory(newPath)
                : common.invalidArgument(newPath);
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
    internalCreateSync(
        createChild: (DirectoryNode parent, bool isFinalSegment) {
      if (isFinalSegment) {
        preexisting = false;
        return new LinkNode(parent, target);
      } else if (recursive) {
        return new DirectoryNode(parent);
      }
      return null;
    });
    if (preexisting) {
      // Per the spec, this is an error.
      throw common.fileExists(path);
    }
  }

  @override
  Future<Link> update(String target) async {
    updateSync(target);
    return this;
  }

  @override
  void updateSync(String target) {
    Node node = backing;
    utils.checkType(expectedType, node.type, () => path);
    (node as LinkNode).target = target;
  }

  @override
  void deleteSync({bool recursive: false}) => internalDeleteSync(
        recursive: recursive,
        checkType: (Node node) =>
            utils.checkType(expectedType, node.type, () => path),
      );

  @override
  Future<String> target() async => targetSync();

  @override
  String targetSync() {
    Node node = backing;
    if (node.type != expectedType) {
      // Note: this may change; https://github.com/dart-lang/sdk/issues/28204
      throw common.noSuchFileOrDirectory(path);
    }
    return (node as LinkNode).target;
  }

  @override
  Link get absolute => super.absolute;

  @override
  @protected
  Link clone(String path) => new MemoryLink(fileSystem, path);

  @override
  String toString() => "MemoryLink: '$path'";
}
