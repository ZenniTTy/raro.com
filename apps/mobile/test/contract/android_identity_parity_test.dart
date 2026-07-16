import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:xml/xml.dart';

String _readGradle() => File('android/app/build.gradle.kts').readAsStringSync();

String? _gradleValue(String source, String property) {
  final match = RegExp('$property\\s*=\\s*"([^"]+)"').firstMatch(source);
  return match?.group(1);
}

void main() {
  group('Family 10 — Android identity parity', () {
    final gradle = _readGradle();
    final manifest = XmlDocument.parse(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
    );

    test('gradle applicationId matches AppIdentity.applicationId', () {
      expect(_gradleValue(gradle, 'applicationId'), AppIdentity.applicationId);
    });

    test('android:label matches AppIdentity.displayName', () {
      final label = manifest
          .findAllElements('application')
          .single
          .getAttribute('android:label');
      expect(label, AppIdentity.displayName);
    });

    test('gradle namespace may diverge from applicationId', () {
      expect(
        _gradleValue(gradle, 'namespace'),
        isNot(AppIdentity.applicationId),
      );
    });

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
