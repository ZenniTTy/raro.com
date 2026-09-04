import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/core/subscription/revenuecat_billing_gateway.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_controller.g.dart';

@Riverpod(keepAlive: true)
SubscriptionStore subscriptionStore(Ref ref) =>
    const SharedPreferencesSubscriptionStore();

@Riverpod(keepAlive: true)
BillingGateway billingGateway(Ref ref) =>
    RevenueCatBillingGateway(logger: ref.watch(appLoggerProvider));

@Riverpod(keepAlive: true)
class SubscriptionController extends _$SubscriptionController {
  BillingCustomerListener? _customerListener;

  @override
  Future<SubscriptionState> build() async {
    final billing = ref.read(billingGatewayProvider);
    await billing.ensureConfigured();
    _customerListener = (customer) {
      if (!ref.mounted) return;
      state = AsyncData(_stateFrom(customer, DateTime.now()));
    };
    billing.addCustomerUpdateListener(_customerListener!);
    ref.onDispose(() {
      final listener = _customerListener;
      if (listener != null) {
        billing.removeCustomerUpdateListener(listener);
      }
    });

    if (billing.isConfigured) {
      try {
        final customer = await billing.getCustomer();
        return _stateFrom(customer, DateTime.now());
      } on BillingException {
        return ref.read(subscriptionStoreProvider).load();
      }
    }
    return ref.read(subscriptionStoreProvider).load();
  }

  Future<PurchaseFlowResult> subscribe({
    required PlanType plan,
    required DateTime now,
  }) async {
    final billing = ref.read(billingGatewayProvider);
    await billing.ensureConfigured();
    if (!billing.isConfigured) {
      return PurchaseFlowResult.unavailable;
    }
    try {
      final customer = await billing.purchasePlan(plan.sku);
      final updated = _stateFrom(customer, now);
      state = AsyncData(updated);
      await ref.read(subscriptionStoreProvider).save(updated);
      return PurchaseFlowResult.success;
    } on BillingCancelled {
      return PurchaseFlowResult.cancelled;
    } on BillingException {
      return PurchaseFlowResult.failed;
    }
  }

  Future<RestoreFlowResult> restorePurchases() async {
    final billing = ref.read(billingGatewayProvider);
    await billing.ensureConfigured();
    if (!billing.isConfigured) {
      return RestoreFlowResult.unavailable;
    }
    try {
      final customer = await billing.restorePurchases();
      final updated = _stateFrom(customer, DateTime.now());
      state = AsyncData(updated);
      await ref.read(subscriptionStoreProvider).save(updated);
      if (!customer.hasPremium) {
        return RestoreFlowResult.empty;
      }
      return RestoreFlowResult.restored;
    } on BillingException {
      return RestoreFlowResult.failed;
    }
  }

  SubscriptionState _stateFrom(BillingCustomer customer, DateTime now) {
    return SubscriptionState(
      isSubscribed: customer.hasPremium,
      trialStartedAt: customer.hasPremium ? now : null,
    );
  }
}
