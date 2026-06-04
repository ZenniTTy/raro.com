import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';

void main() {
  final now = DateTime(2026, 6, 2, 12);

  group('SubscriptionState', () {
    test('estado inicial: não-assinado, sem trial', () {
      const state = SubscriptionState.initial();
      expect(state.isSubscribed, isFalse);
      expect(state.trialStartedAt, isNull);
      expect(state.isTrialActive(now), isFalse);
      expect(state.trialDaysRemaining(now), 0);
    });

    test('trial recém-iniciado tem 30 dias restantes', () {
      final state = SubscriptionState(isSubscribed: true, trialStartedAt: now);
      expect(state.trialDaysRemaining(now), 30);
      expect(state.isTrialActive(now), isTrue);
    });

    test('trial com 10 dias decorridos tem 20 dias restantes', () {
      final started = now.subtract(const Duration(days: 10));
      final state = SubscriptionState(
        isSubscribed: true,
        trialStartedAt: started,
      );
      expect(state.trialDaysRemaining(now), 20);
    });

    test('trial expirado (>30 dias) tem 0 dias restantes', () {
      final started = now.subtract(const Duration(days: 31));
      final state = SubscriptionState(
        isSubscribed: true,
        trialStartedAt: started,
      );
      expect(state.trialDaysRemaining(now), 0);
      expect(state.isTrialActive(now), isFalse);
    });

    test('exatamente no dia 30 ainda conta como trial ativo (1 dia)', () {
      final started = now.subtract(const Duration(days: 29));
      final state = SubscriptionState(
        isSubscribed: true,
        trialStartedAt: started,
      );
      expect(state.trialDaysRemaining(now), 1);
      expect(state.isTrialActive(now), isTrue);
    });

    test('assinado sem trialStartedAt não está em trial', () {
      const state = SubscriptionState(isSubscribed: true);
      expect(state.isTrialActive(now), isFalse);
      expect(state.trialDaysRemaining(now), 0);
    });
  });
}
