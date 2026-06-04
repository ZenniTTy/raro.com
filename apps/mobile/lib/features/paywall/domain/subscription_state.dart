import 'package:raro_shared/raro_shared.dart';

class SubscriptionState {
  const SubscriptionState({required this.isSubscribed, this.trialStartedAt});

  const SubscriptionState.initial()
    : isSubscribed = false,
      trialStartedAt = null;

  final bool isSubscribed;
  final DateTime? trialStartedAt;

  int trialDaysRemaining(DateTime now) {
    final started = trialStartedAt;
    if (started == null) return 0;
    final elapsedDays = now.difference(started).inDays;
    final remaining = SubscriptionConfig.freeTrialDays - elapsedDays;
    return remaining.clamp(0, SubscriptionConfig.freeTrialDays);
  }

  bool isTrialActive(DateTime now) => trialDaysRemaining(now) > 0;

  SubscriptionState copyWith({bool? isSubscribed, DateTime? trialStartedAt}) {
    return SubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
    );
  }
}
