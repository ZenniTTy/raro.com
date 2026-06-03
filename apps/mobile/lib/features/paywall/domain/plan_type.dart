import 'package:raro_shared/raro_shared.dart';

enum PlanType {
  monthly(
    sku: SubscriptionSkus.monthly,
    priceBRL: PlanPricing.monthlyBRL,
    period: '/mês',
  ),
  yearly(
    sku: SubscriptionSkus.yearly,
    priceBRL: PlanPricing.yearlyBRL,
    period: '/ano',
  );

  const PlanType({
    required this.sku,
    required this.priceBRL,
    required this.period,
  });

  final String sku;
  final double priceBRL;
  final String period;

  String get priceLabel => 'R\$ ${_formatBRL(priceBRL)}';

  static String _formatBRL(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');
}
