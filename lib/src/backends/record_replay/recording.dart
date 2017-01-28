// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.record_replay;

/// A recording of a series of invocations (methods, getters, setters) on a
/// [RecordingFileSystem] and its associated objects.
///
/// A recording exists in memory only until `flush` is called.
class Recording {
  /// The directory in which recording files will be stored.
  ///
  /// These contents of these files, while human readable, do not constitute an
  /// API or contract. Their makeup and structure is subject to change from
  /// one version of `package:file` to the next.
  final Directory dir;

  final List<_Event<dynamic>> _events = <_Event<dynamic>>[];

  Recording._(this.dir);

  /// Writes this recording to disk.
  ///
  /// This class does not call `flush` on itself, so it is up to callers to
  /// call this method when they wish to write the recording to disk.
  ///
  /// Returns a future that completes once the recording has been fully written
  /// to disk.
  // TODO(tvolkert): Add ability to wait for all Future and Stream results
  Future<Null> flush() async {
    String json = _asJson();
    String filename = dir.fileSystem.path.join(dir.path, _kManifestName);
    await dir.fileSystem.file(filename).writeAsString(json, flush: true);
  }

  /// Gets the in-memory representation of the recording manifest. Intended for
  /// testing purposes only.
  @visibleForTesting
  List<Map<String, dynamic>> getManifest() =>
      new JsonDecoder().convert(_asJson());

  /// Adds the specified [event] to this recording.
  void _add(_Event<dynamic> event) {
    _events.add(event);
  }

  /// Encodes the events into a JSON-formatted string.
  String _asJson() =>
      new JsonEncoder.withIndent('  ', _encode).convert(_events);
}
