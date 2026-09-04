import 'package:raro_mobile/core/subscription/billing_gateway.dart';

class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({this.premium = false});

  bool premium;
  final List<BillingCustomerListener> _listeners = [];

  BillingCustomer get _customer => BillingCustomer(hasPremium: premium);

  @override
  bool get isConfigured => true;

  @override
  Future<void> ensureConfigured() async {}

  @override
  Future<BillingCustomer> getCustomer() async => _customer;

  @override
  Future<BillingCustomer> purchasePlan(String sku) async {
    premium = true;
    final customer = _customer;
    for (final listener in List<BillingCustomerListener>.of(_listeners)) {
      listener(customer);
    }
    return customer;
  }

  @override
  Future<BillingCustomer> restorePurchases() async => _customer;

  @override
  void addCustomerUpdateListener(BillingCustomerListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeCustomerUpdateListener(BillingCustomerListener listener) {
    _listeners.remove(listener);
  }
}

class EntitledThenUnavailableBillingGateway implements BillingGateway {
  @override
  bool get isConfigured => true;

  @override
  Future<void> ensureConfigured() async {}

  @override
  Future<BillingCustomer> getCustomer() async {
    throw const BillingFailed('unavailable');
  }

  @override
  Future<BillingCustomer> purchasePlan(String sku) async {
    return const BillingCustomer(hasPremium: true);
  }

  @override
  Future<BillingCustomer> restorePurchases() async {
    return const BillingCustomer(hasPremium: true);
  }

  @override
  void addCustomerUpdateListener(BillingCustomerListener listener) {}

  @override
  void removeCustomerUpdateListener(BillingCustomerListener listener) {}
}

class UnconfiguredBillingGateway implements BillingGateway {
  @override
  bool get isConfigured => false;

  @override
  Future<void> ensureConfigured() async {}

  @override
  Future<BillingCustomer> getCustomer() async {
    throw const BillingNotConfigured();
  }

  @override
  Future<BillingCustomer> purchasePlan(String sku) async {
    throw const BillingNotConfigured();
  }

  @override
  Future<BillingCustomer> restorePurchases() async {
    throw const BillingNotConfigured();
  }

  @override
  void addCustomerUpdateListener(BillingCustomerListener listener) {}

  @override
  void removeCustomerUpdateListener(BillingCustomerListener listener) {}
}
