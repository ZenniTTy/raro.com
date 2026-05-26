import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:xml/xml.dart';

void main() {
  group('Family 10 — AndroidManifest parity', () {
    final manifest = XmlDocument.parse(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
    );

    test(
      'declared permissions are superset of PermissionsContract.android',
      () {
        final declared = manifest
            .findAllElements('uses-permission')
            .map((e) => e.getAttribute('android:name'))
            .whereType<String>()
            .toSet();
        for (final required in PermissionsContract.android) {
          expect(
            declared,
            contains(required),
            reason: 'missing permission: $required (declared: $declared)',
          );
        }
      },
    );
  });
}
