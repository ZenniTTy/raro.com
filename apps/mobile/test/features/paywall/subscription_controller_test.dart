import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';

class _FakeSubscriptionStore implements SubscriptionStore {
  _FakeSubscriptionStore([this._stored = const SubscriptionState.initial()]);

  SubscriptionState _stored;
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
  ProviderContainer makeContainer(SubscriptionStore store) {
    final container = ProviderContainer(
      overrides: [subscriptionStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SubscriptionController', () {
    test('build carrega estado persistido (default: não-assinado)', () async {
      final container = makeContainer(_FakeSubscriptionStore());

      final state = await container.read(subscriptionControllerProvider.future);

      expect(state.isSubscribed, isFalse);
      expect(state.trialStartedAt, isNull);
    });

    test('build carrega assinatura+trial já persistidos', () async {
      final started = DateTime(2026, 5, 20);
      final store = _FakeSubscriptionStore(
        SubscriptionState(isSubscribed: true, trialStartedAt: started),
      );
      final container = makeContainer(store);

      final state = await container.read(subscriptionControllerProvider.future);

      expect(state.isSubscribed, isTrue);
      expect(state.trialStartedAt, started);
    });

    test('subscribe marca assinado, inicia trial em now e persiste', () async {
      final store = _FakeSubscriptionStore();
      final container = makeContainer(store);
      await container.read(subscriptionControllerProvider.future);
      final now = DateTime(2026, 6, 2, 12);

      await container
          .read(subscriptionControllerProvider.notifier)
          .subscribe(now: now);

      final state = container.read(subscriptionControllerProvider).requireValue;
      expect(state.isSubscribed, isTrue);
      expect(state.trialStartedAt, now);
      expect(store.saveCount, 1);
      expect((await store.load()).isSubscribed, isTrue);
      expect((await store.load()).trialStartedAt, now);
    });
  });
}
