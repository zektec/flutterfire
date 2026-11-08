// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util' as js_util;

import 'package:_flutterfire_internals/_flutterfire_internals.dart'
    as internals;
import 'package:firebase_core/firebase_core.dart';

Map<String, String?> _errorCodeToMessage = {
  'unauthorized': 'User is not authorized to perform the desired action.',
  'object-not-found': 'No object exists at the desired reference.',
  'invalid-argument': null, // let error pass-through
  'canceled': null,
};

/// Will return a [FirebaseException] from a thrown web error.
/// Any other errors will be propagated as normal.
R guard<R>(R Function() cb) {
  R invoke() {
    try {
      final value = cb();
      if (value is Future) {
        return value.catchError(
          (Object error, StackTrace stack) => Error.throwWithStackTrace(
            _storageException(error),
            stack,
          ),
          test: _isStorageError,
        ) as R;
      }
      if (value is Stream) {
        return value.handleError(
          (Object error, StackTrace stack) => Error.throwWithStackTrace(
            _storageException(error),
            stack,
          ),
          test: _isStorageError,
        ) as R;
      }
      return value;
    } catch (error, stack) {
      if (!_isStorageError(error)) rethrow;
      Error.throwWithStackTrace(_storageException(error), stack);
    }
  }

  return internals.guardWebExceptions(
    invoke,
    plugin: 'firebase_storage',
    codeParser: (code) => code.split('/').last,
    messageParser: (code, message) {
      return _errorCodeToMessage[code] ?? message;
    },
  );
}

bool _isStorageError(Object? error) {
  if (error == null || !js_util.hasProperty(error, 'code')) return false;
  final code = js_util.getProperty<Object?>(error, 'code');
  return code is String && code.startsWith('storage/');
}

FirebaseException _storageException(Object error) {
  final code = js_util.getProperty<String>(error, 'code').split('/').last;
  final message = js_util.getProperty<String>(error, 'message');
  return FirebaseException(
    plugin: 'firebase_storage',
    code: code,
    message: _errorCodeToMessage[code] ?? message,
  );
}
