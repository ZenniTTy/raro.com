import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_shared/raro_shared.dart';

import 'package:raro_mobile/app.dart';
import 'package:raro_mobile/core/analytics/firebase_analytics_provider.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  group('RaroApp smoke', () {
    testWidgets('boots inside ProviderScope without throwing', (tester) async {
      final analytics = _MockAnalytics();
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [firebaseAnalyticsProvider.overrideWithValue(analytics)],
          child: const RaroApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(RaroApp), findsOneWidget);
    });
  });

  group('Shared package contract (locked invariants)', () {
    test('wake word is "Raro" (never "OkCamera")', () {
      expect(VoiceConfig.wakeWord, 'Raro');
      expect(VoiceConfig.wakeWord.toLowerCase().contains('camera'), isFalse);
      expect(VoiceConfig.wakeWord.toLowerCase().contains('ok'), isFalse);
    });

    test('free trial is 30 days (briefing decision over prototype)', () {
      expect(SubscriptionConfig.freeTrialDays, 30);
    });

    test('bundle id is com.rarocamera', () {
      expect(AppIdentity.bundleId, 'com.rarocamera');
    });

    test('subscription has both monthly and yearly SKUs', () {
      expect(SubscriptionSkus.monthly, isNotEmpty);
      expect(SubscriptionSkus.yearly, isNotEmpty);
      expect(SubscriptionSkus.monthly, isNot(SubscriptionSkus.yearly));
    });
  });
}
