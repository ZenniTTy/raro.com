import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_controller.g.dart';

@Riverpod(keepAlive: true)
SubscriptionStore subscriptionStore(Ref ref) =>
    const SharedPreferencesSubscriptionStore();

@Riverpod(keepAlive: true)
class SubscriptionController extends _$SubscriptionController {
  @override
  Future<SubscriptionState> build() {
    return ref.read(subscriptionStoreProvider).load();
  }

  Future<void> subscribe({required DateTime now}) async {
    final updated = SubscriptionState(isSubscribed: true, trialStartedAt: now);
    state = AsyncData(updated);
    await ref.read(subscriptionStoreProvider).save(updated);
  }
}
