import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/core/subscription/purchases_error_mapper.dart';
import 'package:raro_mobile/core/subscription/revenuecat_api_keys.dart';
import 'package:raro_shared/raro_shared.dart';

class RevenueCatBillingGateway implements BillingGateway {
  RevenueCatBillingGateway({required this._logger});

  final Logger _logger;
  final List<BillingCustomerListener> _listeners = [];

  bool _configureAttempted = false;
  bool _configured = false;
  CustomerInfoUpdateListener? _sdkListener;

  @override
  bool get isConfigured => _configured;

  @override
  Future<void> ensureConfigured() async {
    if (_configureAttempted) return;
    _configureAttempted = true;

    final key = revenueCatApiKeyForPlatform();
    if (key == null) {
      _logger.i('RevenueCat skipped: missing API key');
      return;
    }
    if (kReleaseMode && isTestStoreApiKey(key)) {
      _logger.e('RevenueCat refused Test Store API key in release');
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(key));
    _configured = true;
    _sdkListener = (info) {
      final customer = billingCustomerFromInfo(info);
      for (final listener in List<BillingCustomerListener>.of(_listeners)) {
        listener(customer);
      }
    };
    Purchases.addCustomerInfoUpdateListener(_sdkListener!);
  }

  @override
  Future<BillingCustomer> getCustomer() async {
    await ensureConfigured();
    if (!_configured) throw const BillingNotConfigured();
    final info = await Purchases.getCustomerInfo();
    return billingCustomerFromInfo(info);
  }

  @override
  Future<BillingCustomer> purchasePlan(String sku) async {
    await ensureConfigured();
    if (!_configured) throw const BillingNotConfigured();
    try {
      final package = await _packageForSku(sku);
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return billingCustomerFromInfo(result.customerInfo);
    } on PlatformException catch (error, stack) {
      final mapped = mapPurchasesException(error);
      if (mapped is BillingAlreadyPurchased) {
        return getCustomer();
      }
      _logger.w('RevenueCat purchase failed', error: error, stackTrace: stack);
      throw mapped;
    }
  }

  @override
  Future<BillingCustomer> restorePurchases() async {
    await ensureConfigured();
    if (!_configured) throw const BillingNotConfigured();
    try {
      final info = await Purchases.restorePurchases();
      return billingCustomerFromInfo(info);
    } on PlatformException catch (error, stack) {
      _logger.w('RevenueCat restore failed', error: error, stackTrace: stack);
      throw mapPurchasesException(error);
    }
  }

  @override
  void addCustomerUpdateListener(BillingCustomerListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeCustomerUpdateListener(BillingCustomerListener listener) {
    _listeners.remove(listener);
  }

  Future<Package> _packageForSku(String sku) async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    final package = skuIsYearly(sku) ? current?.annual : current?.monthly;
    if (package == null) {
      throw const BillingOfferingsUnavailable();
    }
    return package;
  }
}

BillingCustomer billingCustomerFromInfo(CustomerInfo info) {
  final premium = info.entitlements.active[SubscriptionConfig.entitlement];
  final expiration = premium?.expirationDate;
  return BillingCustomer(
    hasPremium: premium != null,
    expirationDate: expiration == null ? null : DateTime.tryParse(expiration),
  );
}
