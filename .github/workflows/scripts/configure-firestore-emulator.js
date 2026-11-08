// Copyright 2026, the Chromium project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The secondary-app tests expect this project to deny all access. The CLI's
// startup rules otherwise apply to every project in the local emulator.
const denyRules = `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} { allow read, write: if false; }
  }
}`;

async function configureFirestoreEmulator() {
  const response = await fetch(
    'http://127.0.0.1:8080/emulator/v1/projects/flutterfire-e2e-tests-2:securityRules',
    {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ rules: { files: [{ content: denyRules }] } }),
    },
  );
  if (!response.ok) {
    throw new Error(`Cannot configure secondary-project rules: ${await response.text()}`);
  }
  console.log('Secondary Firestore emulator project denies all access.');
}

configureFirestoreEmulator().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
