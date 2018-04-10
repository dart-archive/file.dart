// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

import 'common.dart';
import 'memory_file.dart';
import 'memory_file_system_entity.dart';
import 'memory_link.dart';
import 'node.dart';
import 'style.dart';
import 'utils.dart' as utils;

/// Internal implementation of [Directory].
class MemoryDirectory extends MemoryFileSystemEntity
    with common.DirectoryAddOnsMixin
    implements Directory {
  static int _tempCounter = 0;

  /// Instantiates a new [MemoryDirectory].
  MemoryDirectory(NodeBasedFileSystem fileSystem, String path)
      : super(fileSystem, path);

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.DIRECTORY;

  @override
  Uri get uri {
    return new Uri.directory(path,
        windows: fileSystem.style == FileSystemStyle.windows);
  }

  @override
  bool existsSync() => backingOrNull?.stat?.type == expectedType;

  @override
  Future<Directory> create({bool recursive: false}) async {
    createSync(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive: false}) {
    Node node = internalCreateSync(
      followTailLink: true,
      visitLinks: true,
      createChild: (DirectoryNode parent, bool isFinalSegment) {
        if (recursive || isFinalSegment) {
          return new DirectoryNode(parent);
        }
        return null;
      },
    );
    if (node.type != expectedType) {
      // There was an existing non-directory node at this object's path
      throw common.notADirectory(path);
    }
  }

  @override
  Future<Directory> createTemp([String prefix]) async => createTempSync(prefix);

  @override
  Directory createTempSync([String prefix]) {
    prefix = (prefix ?? '') + 'rand';
    String fullPath = fileSystem.path.join(path, prefix);
    String dirname = fileSystem.path.dirname(fullPath);
    String basename = fileSystem.path.basename(fullPath);
    DirectoryNode node = fileSystem.findNode(dirname);
    checkExists(node, () => dirname);
    utils.checkIsDir(node, () => dirname);
    String name() => '$basename$_tempCounter';
    while (node.children.containsKey(name())) {
      _tempCounter++;
    }
    DirectoryNode tempDir = new DirectoryNode(node);
    node.children[name()] = tempDir;
    return new MemoryDirectory(
        fileSystem, fileSystem.path.join(dirname, name()));
  }

  @override
  Future<Directory> rename(String newPath) async => renameSync(newPath);

  @override
  Directory renameSync(String newPath) => internalRenameSync<DirectoryNode>(
        newPath,
        validateOverwriteExistingEntity: (DirectoryNode existingNode) {
          if (existingNode.children.isNotEmpty) {
            throw common.directoryNotEmpty(newPath);
          }
        },
      );

  @override
  Directory get parent =>
      (backingOrNull?.isRoot ?? false) ? this : super.parent;

  @override
  Directory get absolute => super.absolute;

  @override
  Stream<FileSystemEntity> list({
    bool recursive: false,
    bool followLinks: true,
  }) =>
      new Stream<FileSystemEntity>.fromIterable(listSync(
        recursive: recursive,
        followLinks: followLinks,
      ));

  @override
  List<FileSystemEntity> listSync({
    bool recursive: false,
    bool followLinks: true,
  }) {
    DirectoryNode node = backing;
    List<FileSystemEntity> listing = <FileSystemEntity>[];
    List<_PendingListTask> tasks = <_PendingListTask>[
      new _PendingListTask(
        node,
        path.endsWith(fileSystem.path.separator)
            ? path.substring(0, path.length - 1)
            : path,
        new Set<LinkNode>(),
      ),
    ];
    while (tasks.isNotEmpty) {
      _PendingListTask task = tasks.removeLast();
      task.dir.children.forEach((String name, Node child) {
        Set<LinkNode> breadcrumbs = new Set<LinkNode>.from(task.breadcrumbs);
        String childPath = fileSystem.path.join(task.path, name);
        while (followLinks && utils.isLink(child) && breadcrumbs.add(child)) {
          Node referent = (child as LinkNode).referentOrNull;
          if (referent != null) {
            child = referent;
          }
        }
        if (utils.isDirectory(child)) {
          listing.add(new MemoryDirectory(fileSystem, childPath));
          if (recursive) {
            tasks.add(new _PendingListTask(child, childPath, breadcrumbs));
          }
        } else if (utils.isLink(child)) {
          listing.add(new MemoryLink(fileSystem, childPath));
        } else if (utils.isFile(child)) {
          listing.add(new MemoryFile(fileSystem, childPath));
        }
      });
    }
    return listing;
  }

  @override
  @protected
  Directory clone(String path) => new MemoryDirectory(fileSystem, path);

  @override
  String toString() => "MemoryDirectory: '$path'";
}

class _PendingListTask {
  final DirectoryNode dir;
  final String path;
  final Set<LinkNode> breadcrumbs;
  _PendingListTask(this.dir, this.path, this.breadcrumbs);
}
