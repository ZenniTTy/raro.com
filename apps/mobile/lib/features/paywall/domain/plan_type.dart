import 'package:raro_shared/raro_shared.dart';

enum PlanType {
  monthly(sku: SubscriptionSkus.monthly, priceBRL: PlanPricing.monthlyBRL),
  yearly(sku: SubscriptionSkus.yearly, priceBRL: PlanPricing.yearlyBRL);

  const PlanType({required this.sku, required this.priceBRL});

  final String sku;
  final double priceBRL;

  String get priceLabel => 'R\$ ${_formatBRL(priceBRL)}';

  static String _formatBRL(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');
}
