import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/core/subscription/purchases_error_mapper.dart';

PlatformException _exception(PurchasesErrorCode code) {
  return PlatformException(code: '${code.index}', message: code.name);
}

void main() {
  group('mapPurchasesException', () {
    test('purchaseCancelledError → BillingCancelled', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.purchaseCancelledError),
        ),
        isA<BillingCancelled>(),
      );
    });

    test('productAlreadyPurchasedError → BillingAlreadyPurchased', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.productAlreadyPurchasedError),
        ),
        isA<BillingAlreadyPurchased>(),
      );
    });

    test('productNotAvailableForPurchaseError → offerings unavailable', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.productNotAvailableForPurchaseError),
        ),
        isA<BillingOfferingsUnavailable>(),
      );
    });

    test('configurationError → BillingNotConfigured', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.configurationError),
        ),
        isA<BillingNotConfigured>(),
      );
    });

    test('invalidCredentialsError → BillingNotConfigured', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.invalidCredentialsError),
        ),
        isA<BillingNotConfigured>(),
      );
    });

    test('networkError → BillingFailed', () {
      expect(
        mapPurchasesException(_exception(PurchasesErrorCode.networkError)),
        isA<BillingFailed>(),
      );
    });

    test('offlineConnectionError → BillingFailed', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.offlineConnectionError),
        ),
        isA<BillingFailed>(),
      );
    });

    test('storeProblemError → BillingFailed', () {
      expect(
        mapPurchasesException(_exception(PurchasesErrorCode.storeProblemError)),
        isA<BillingFailed>(),
      );
    });

    test('purchaseNotAllowedError → BillingFailed', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.purchaseNotAllowedError),
        ),
        isA<BillingFailed>(),
      );
    });

    test('paymentPendingError → BillingFailed', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.paymentPendingError),
        ),
        isA<BillingFailed>(),
      );
    });

    test('testStoreSimulatedPurchaseError → BillingFailed', () {
      expect(
        mapPurchasesException(
          _exception(PurchasesErrorCode.testStoreSimulatedPurchaseError),
        ),
        isA<BillingFailed>(),
      );
    });
  });
}
