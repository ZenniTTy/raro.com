import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/subscription/revenuecat_api_keys.dart';

void main() {
  group('isTestStoreApiKey', () {
    test('detecta prefixo test_', () {
      expect(isTestStoreApiKey('test_abc'), isTrue);
      expect(isTestStoreApiKey('goog_abc'), isFalse);
      expect(isTestStoreApiKey('appl_abc'), isFalse);
    });
  });

  group('revenueCatApiKeyForPlatform', () {
    test('sem dart-define retorna null', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(revenueCatApiKeyForPlatform(), isNull);
    });
  });
}
