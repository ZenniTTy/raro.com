import 'package:raro_shared/raro_shared.dart';

class BillingCustomer {
  const BillingCustomer({required this.hasPremium, this.expirationDate});

  final bool hasPremium;
  final DateTime? expirationDate;
}

typedef BillingCustomerListener = void Function(BillingCustomer customer);

abstract interface class BillingGateway {
  bool get isConfigured;

  Future<void> ensureConfigured();

  Future<BillingCustomer> getCustomer();

  Future<BillingCustomer> purchasePlan(String sku);

  Future<BillingCustomer> restorePurchases();

  void addCustomerUpdateListener(BillingCustomerListener listener);

  void removeCustomerUpdateListener(BillingCustomerListener listener);
}

sealed class BillingException implements Exception {
  const BillingException();
}

class BillingCancelled extends BillingException {
  const BillingCancelled();
}

class BillingNotConfigured extends BillingException {
  const BillingNotConfigured();
}

class BillingOfferingsUnavailable extends BillingException {
  const BillingOfferingsUnavailable();
}

class BillingAlreadyPurchased extends BillingException {
  const BillingAlreadyPurchased();
}

class BillingFailed extends BillingException {
  const BillingFailed(this.code);

  final String code;
}

class BillingRestoreEmpty extends BillingException {
  const BillingRestoreEmpty();
}

enum PurchaseFlowResult { success, cancelled, failed, unavailable }

enum RestoreFlowResult { restored, empty, failed, unavailable }

bool skuIsYearly(String sku) => sku == SubscriptionSkus.yearly;
