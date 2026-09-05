import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _pairs = <({String docs, String asset})>[
  (
    docs: 'docs/legal/politica-de-privacidade-pt-BR.md',
    asset: 'apps/mobile/assets/legal/privacy_pt.md',
  ),
  (
    docs: 'docs/legal/privacy-policy-en.md',
    asset: 'apps/mobile/assets/legal/privacy_en.md',
  ),
  (
    docs: 'docs/legal/politica-de-privacidad-es.md',
    asset: 'apps/mobile/assets/legal/privacy_es.md',
  ),
  (
    docs: 'docs/legal/termos-de-uso-pt-BR.md',
    asset: 'apps/mobile/assets/legal/terms_pt.md',
  ),
  (
    docs: 'docs/legal/terms-of-use-en.md',
    asset: 'apps/mobile/assets/legal/terms_en.md',
  ),
  (
    docs: 'docs/legal/terminos-de-uso-es.md',
    asset: 'apps/mobile/assets/legal/terms_es.md',
  ),
];

void main() {
  late String repoRoot;

  setUpAll(() {
    var cursor = Directory.current;
    while (!File('${cursor.path}/docs/Blueprint.md').existsSync()) {
      final parent = cursor.parent;
      if (parent.path == cursor.path) {
        fail('repo root not found from ${Directory.current.path}');
      }
      cursor = parent;
    }
    repoRoot = cursor.path;
  });

  test('apps/mobile/assets/legal matches docs/legal byte-for-byte', () {
    for (final pair in _pairs) {
      final docsFile = File('$repoRoot/${pair.docs}');
      final assetFile = File('$repoRoot/${pair.asset}');
      expect(
        docsFile.existsSync(),
        isTrue,
        reason: 'missing source ${pair.docs}',
      );
      expect(
        assetFile.existsSync(),
        isTrue,
        reason: 'missing asset ${pair.asset}',
      );
      expect(
        docsFile.readAsBytesSync(),
        assetFile.readAsBytesSync(),
        reason: '${pair.docs} drifted from ${pair.asset}',
      );
    }
  });
}
