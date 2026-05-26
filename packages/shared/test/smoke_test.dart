import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Family 1 — Identity', () {
    test('display name is "Raro Camera"', () {
      expect(AppIdentity.displayName, 'Raro Camera');
    });

    test('bundle id is com.rarocamera', () {
      expect(AppIdentity.bundleId, 'com.rarocamera');
    });

    test('application id matches bundle id', () {
      expect(AppIdentity.applicationId, AppIdentity.bundleId);
    });
  });

  group('Family 2 — Invariants', () {
    test('wake word is "Raro" (never "OkCamera")', () {
      expect(VoiceConfig.wakeWord, 'Raro');
    });

    test('free trial is 30 days', () {
      expect(SubscriptionConfig.freeTrialDays, 30);
    });

    test('monthly SKU matches Blueprint 2.4', () {
      expect(SubscriptionSkus.monthly, 'raro_premium_monthly_BRL_9_90');
    });

    test('yearly SKU matches Blueprint 2.4', () {
      expect(SubscriptionSkus.yearly, 'raro_premium_yearly_BRL_89_90');
    });

    test('entitlement is "premium"', () {
      expect(SubscriptionConfig.entitlement, 'premium');
    });
  });
}
