// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  if (Platform.environment['CI'] == 'true') {
    final sessionId = Platform.environment['DRIVER_SESSION_ID']!;
    final driverUri = Uri.parse(Platform.environment['DRIVER_SESSION_URI']!);
    final endpoint = driverUri.replace(
      path: '/session/$sessionId/goog/cdp/execute',
    );
    final client = HttpClient();
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'cmd': 'Browser.setPermission',
          'params': {
            'permission': {'name': 'notifications'},
            'setting': 'denied',
          },
        }),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode != HttpStatus.ok ||
          (result['value'] as Map<String, dynamic>?)?['error'] != null) {
        throw StateError(
          'Cannot configure browser notification permission: $body',
        );
      }
    } finally {
      client.close(force: true);
    }
  }
  await integrationDriver();
}
