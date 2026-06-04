abstract final class SubscriptionSkus {
  static const String monthly = 'raro_premium_monthly_BRL_9_90';
  static const String yearly = 'raro_premium_yearly_BRL_89_90';
}

abstract final class SubscriptionConfig {
  static const String entitlement = 'premium';
  static const int freeTrialDays = 30;
}

abstract final class PlanPricing {
  static const double monthlyBRL = 9.90;
  static const double yearlyBRL = 89.90;
  static const double yearlyMonthlyEquivalentBRL = 7.49;
}
