import 'package:raro_mobile/features/paywall/domain/paywall_intent.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';

class PaywallArgs {
  const PaywallArgs({
    this.intent = PaywallIntent.browse,
    this.videoId,
    this.fromCamera = false,
  });

  final PaywallIntent intent;
  final String? videoId;
  final bool fromCamera;
}

class CheckoutArgs {
  const CheckoutArgs({required this.plan, this.paywall = const PaywallArgs()});

  final PlanType plan;
  final PaywallArgs paywall;
}
