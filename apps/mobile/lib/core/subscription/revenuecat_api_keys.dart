import 'package:flutter/foundation.dart';

const String _iosKey = String.fromEnvironment('REVENUECAT_API_KEY_IOS');
const String _androidKey = String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');

String? revenueCatApiKeyForPlatform() {
  final key = switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _iosKey,
    TargetPlatform.android => _androidKey,
    _ => '',
  };
  if (key.isEmpty) return null;
  return key;
}

bool isTestStoreApiKey(String key) => key.startsWith('test_');
