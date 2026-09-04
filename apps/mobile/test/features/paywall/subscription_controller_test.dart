import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';

import '../../helpers/fake_billing_gateway.dart';

class _FakeSubscriptionStore implements SubscriptionStore {
  SubscriptionState _stored = const SubscriptionState.initial();
  int saveCount = 0;

  @override
  Future<SubscriptionState> load() async => _stored;

  @override
  Future<void> save(SubscriptionState state) async {
    _stored = state;
    saveCount++;
  }
}

void main() {
  ProviderContainer makeContainer({
    required SubscriptionStore store,
    BillingGateway? billing,
  }) {
    final container = ProviderContainer(
      overrides: [
        subscriptionStoreProvider.overrideWithValue(store),
        billingGatewayProvider.overrideWithValue(
          billing ?? FakeBillingGateway(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SubscriptionController', () {
    test(
      'build carrega estado persistido quando billing não tem premium',
      () async {
        final container = makeContainer(store: _FakeSubscriptionStore());

        final state = await container.read(
          subscriptionControllerProvider.future,
        );

        expect(state.isSubscribed, isFalse);
        expect(state.trialStartedAt, isNull);
      },
    );

    test('build reflete premium já ativo no billing', () async {
      final container = makeContainer(
        store: _FakeSubscriptionStore(),
        billing: FakeBillingGateway(premium: true),
      );

      final state = await container.read(subscriptionControllerProvider.future);

      expect(state.isSubscribed, isTrue);
    });

    test('subscribe compra o plano e persiste premium', () async {
      final store = _FakeSubscriptionStore();
      final billing = FakeBillingGateway();
      final container = makeContainer(store: store, billing: billing);
      await container.read(subscriptionControllerProvider.future);
      final now = DateTime(2026, 6, 2, 12);

      final result = await container
          .read(subscriptionControllerProvider.notifier)
          .subscribe(plan: PlanType.monthly, now: now);

      final state = container.read(subscriptionControllerProvider).requireValue;
      expect(result, PurchaseFlowResult.success);
      expect(state.isSubscribed, isTrue);
      expect(state.trialStartedAt, now);
      expect(store.saveCount, 1);
      expect(billing.premium, isTrue);
    });

    test('restore sem premium devolve empty', () async {
      final container = makeContainer(store: _FakeSubscriptionStore());
      await container.read(subscriptionControllerProvider.future);

      final result = await container
          .read(subscriptionControllerProvider.notifier)
          .restorePurchases();

      expect(result, RestoreFlowResult.empty);
    });

    test('restore com premium devolve restored', () async {
      final container = makeContainer(
        store: _FakeSubscriptionStore(),
        billing: FakeBillingGateway(premium: true),
      );
      await container.read(subscriptionControllerProvider.future);

      final result = await container
          .read(subscriptionControllerProvider.notifier)
          .restorePurchases();

      expect(result, RestoreFlowResult.restored);
    });

    test('subscribe sem billing configurado devolve unavailable', () async {
      final container = makeContainer(
        store: _FakeSubscriptionStore(),
        billing: UnconfiguredBillingGateway(),
      );
      await container.read(subscriptionControllerProvider.future);
      final now = DateTime(2026, 6, 2, 12);

      final result = await container
          .read(subscriptionControllerProvider.notifier)
          .subscribe(plan: PlanType.monthly, now: now);

      expect(result, PurchaseFlowResult.unavailable);
    });
  });
}
