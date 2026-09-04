import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';

BillingException mapPurchasesException(PlatformException exception) {
  final code = PurchasesErrorHelper.getErrorCode(exception);
  return switch (code) {
    PurchasesErrorCode.purchaseCancelledError => const BillingCancelled(),
    PurchasesErrorCode.productAlreadyPurchasedError =>
      const BillingAlreadyPurchased(),
    PurchasesErrorCode.productNotAvailableForPurchaseError =>
      const BillingOfferingsUnavailable(),
    PurchasesErrorCode.configurationError ||
    PurchasesErrorCode.invalidCredentialsError => const BillingNotConfigured(),
    PurchasesErrorCode.networkError ||
    PurchasesErrorCode.offlineConnectionError ||
    PurchasesErrorCode.storeProblemError ||
    PurchasesErrorCode.purchaseNotAllowedError ||
    PurchasesErrorCode.paymentPendingError ||
    PurchasesErrorCode.testStoreSimulatedPurchaseError ||
    _ => BillingFailed(code.name),
  };
}
