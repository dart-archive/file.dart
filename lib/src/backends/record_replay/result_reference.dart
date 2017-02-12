// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'codecs.dart';
import 'events.dart';
import 'recording_proxy_mixin.dart';

/// Wraps a raw invocation return value for the purpose of recording.
///
/// This class is intended for use with [RecordingProxyMixin]. Mixin subclasses
/// may configure a method or getter to return a [ResultReference] rather than
/// a raw result, and:
///
///   - [RecordingProxyMixin] will automatically return the reference's [value]
///     to callers (as if the mixin subclass had returned the raw value
///     directly).
///   - The recording's [InvocationEvent] will automatically record the
///     reference's [recordedValue].
///   - The recording's serialized value (written out during
///     [LiveRecording.flush]) will automatically serialize the reference's
///     [serializedValue].
abstract class ResultReference<T> {
  /// Creates a new `ResultReference`.
  const ResultReference();

  /// The raw value to return to callers of the method or getter.
  T get value;

  /// The value to record in the recording's [InvocationEvent].
  dynamic get recordedValue;

  /// A JSON-serializable representation of this result, suitable for
  /// encoding in a recording manifest.
  ///
  /// The value of this property will be one of the JSON-native types: `num`,
  /// `String`, `bool`, `Null`, `List`, or `Map`.
  ///
  /// This allows for method-specific encoding routines. Take, for example, the
  /// case of a method that returns `List<int>`. This type is natively
  /// serializable by `JSONEncoder`, so if the raw value were directly returned
  /// from an invocation, the recording would happily serialize the result as
  /// a list of integers. However, the method may want to serialize the return
  /// value differently, such as by writing it to file (if it knows the list is
  /// actually a byte array that was read from a file). In this case, the
  /// method can return a `ResultReference` to the list, and it will have a
  /// hook into the serialization process.
  dynamic get serializedValue => encode(recordedValue);

  /// A [Future] that completes when [value] has completed.
  ///
  /// If [value] is a [Future], this future will complete when [value] has
  /// completed. If [value] is a [Stream], this future will complete when the
  /// stream sends a "done" event. If value is neither a future nor a stream,
  /// this future will complete immediately.
  Future<Null> get complete => new Future<Null>.value();
}

/// Wraps a future result.
class FutureReference<T> extends ResultReference<Future<T>> {
  final Future<T> _future;
  T _value;

  /// Creates a new `FutureReference` that wraps the specified [future].
  FutureReference(Future<T> future) : _future = future;

  /// The future value to return to callers of the method or getter.
  @override
  Future<T> get value {
    return _future.then(
      (T value) {
        _value = value;
        return value;
      },
      onError: (dynamic error) {
        // TODO(tvolkert): Record errors
        throw error;
      },
    );
  }

  /// The value returned by the completion of the future.
  ///
  /// If the future threw an error, this value will be `null`.
  @override
  T get recordedValue => _value;

  // TODO(tvolkert): remove `as Future<Null>` once Dart 1.22 is in stable
  @override
  Future<Null> get complete => value.catchError((_) {}) as Future<Null>;
}

/// Wraps a stream result.
class StreamReference<T> extends ResultReference<Stream<T>> {
  final Stream<T> _stream;
  final StreamController<T> _controller;
  final Completer<Null> _completer = new Completer<Null>();
  final List<T> _data = <T>[];
  StreamSubscription<T> _subscription;

  /// Creates a new `StreamReference` that wraps the specified [stream].
  StreamReference(Stream<T> stream)
      : _stream = stream,
        _controller = stream.isBroadcast
            ? new StreamController<T>.broadcast()
            : new StreamController<T>() {
    _controller.onListen = () {
      assert(_subscription == null);
      _subscription = _listenToStream();
    };
    _controller.onCancel = () async {
      assert(_subscription != null);
      await _subscription.cancel();
      _subscription = null;
    };
    _controller.onPause = () {
      assert(_subscription != null && !_subscription.isPaused);
      _subscription.pause();
    };
    _controller.onResume = () {
      assert(_subscription != null && _subscription.isPaused);
      _subscription.resume();
    };
  }

  StreamSubscription<T> _listenToStream() {
    return _stream.listen(
      (T element) {
        _data.add(element);
        onData(element);
        _controller.add(element);
      },
      onError: (dynamic error, StackTrace stackTrace) {
        // TODO(tvolkert): Record errors
        _controller.addError(error, stackTrace);
      },
      onDone: () {
        _completer.complete();
        _controller.close();
      },
    );
  }

  /// Called when an event is received from the underlying delegate stream.
  ///
  /// Subclasses may override this method to be notified when events are
  /// fired from the underlying stream.
  @protected
  void onData(T event) {}

  @override
  Stream<T> get value => _controller.stream;

  @override
  List<T> get recordedValue => _data;

  @override
  Future<Null> get complete => _completer.future.catchError((_) {});
}
