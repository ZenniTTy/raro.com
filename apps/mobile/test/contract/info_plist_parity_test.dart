import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:xml/xml.dart';

XmlDocument _readPlist() {
  return XmlDocument.parse(File('ios/Runner/Info.plist').readAsStringSync());
}

String? _plistString(XmlDocument doc, String key) {
  final dict = doc.rootElement.findElements('dict').single;
  final children = dict.children.whereType<XmlElement>().toList();
  for (var i = 0; i < children.length; i++) {
    if (children[i].localName == 'key' && children[i].innerText == key) {
      if (i + 1 < children.length) return children[i + 1].innerText;
    }
  }
  return null;
}

void main() {
  group('Family 10 — Info.plist parity', () {
    final doc = _readPlist();

    test('CFBundleDisplayName matches AppIdentity.displayName', () {
      expect(_plistString(doc, 'CFBundleDisplayName'), AppIdentity.displayName);
    });

    test(
      'CFBundleIdentifier matches AppIdentity.bundleId or build variable',
      () {
        final v = _plistString(doc, 'CFBundleIdentifier');
        expect(
          v == AppIdentity.bundleId || v == r'$(PRODUCT_BUNDLE_IDENTIFIER)',
          isTrue,
          reason: 'got: $v',
        );
      },
    );

    test('all canonical iOS permission keys are declared', () {
      for (final key in PermissionsContract.ios.keys) {
        expect(_plistString(doc, key), isNotNull, reason: 'missing key: $key');
      }
    });
  });
}
