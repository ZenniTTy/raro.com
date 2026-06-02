import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SubscriptionStore {
  Future<SubscriptionState> load();
  Future<void> save(SubscriptionState state);
}

class SharedPreferencesSubscriptionStore implements SubscriptionStore {
  const SharedPreferencesSubscriptionStore();

  @override
  Future<SubscriptionState> load() async {
    final prefs = SharedPreferencesAsync();
    final active = await prefs.getBool(StorageKeys.subscriptionActive) ?? false;
    final trialMillis = await prefs.getInt(StorageKeys.trialStartedAt);
    return SubscriptionState(
      isSubscribed: active,
      trialStartedAt: trialMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(trialMillis),
    );
  }

  @override
  Future<void> save(SubscriptionState state) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool(StorageKeys.subscriptionActive, state.isSubscribed);
    final started = state.trialStartedAt;
    if (started == null) {
      await prefs.remove(StorageKeys.trialStartedAt);
    } else {
      await prefs.setInt(
        StorageKeys.trialStartedAt,
        started.millisecondsSinceEpoch,
      );
    }
  }
}
