import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/presentation/widgets/plan_card.dart';
import 'package:raro_shared/raro_shared.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    required this.onClose,
    required this.onCheckout,
  });

  final VoidCallback onClose;
  final ValueChanged<PlanType> onCheckout;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PlanType _selected = PlanType.monthly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    const trialDays = SubscriptionConfig.freeTrialDays;
    final equivalent =
        'R\$ ${PlanPricing.yearlyMonthlyEquivalentBRL.toStringAsFixed(2).replaceAll('.', ',')} / mês';

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: widget.onClose),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escolha seu plano',
                      style: TextStyle(
                        fontFamily: RaroFonts.display,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Desbloqueie o potencial total do Raro Camera. '
                      '$trialDays dias grátis, cancele quando quiser.',
                      style: TextStyle(
                        fontFamily: RaroFonts.body,
                        fontSize: 12.5,
                        height: 1.5,
                        color: colors.inkDim,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PlanCard(
                            key: const Key('plan_card_monthly'),
                            plan: PlanType.monthly,
                            selected: _selected == PlanType.monthly,
                            onTap: () =>
                                setState(() => _selected = PlanType.monthly),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PlanCard(
                            key: const Key('plan_card_yearly'),
                            plan: PlanType.yearly,
                            selected: _selected == PlanType.yearly,
                            badge: 'MELHOR OFERTA',
                            equivalentLabel: equivalent,
                            onTap: () =>
                                setState(() => _selected = PlanType.yearly),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FeatureList(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  OnboardingCta(
                    label: 'Assinar agora',
                    primary: true,
                    onPressed: () => widget.onCheckout(_selected),
                  ),
                  const SizedBox(height: 8),
                  OnboardingCta(
                    label: 'Restaurar compras',
                    onPressed: () => _comingSoon(context),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: widget.onClose,
                    child: Text(
                      'Voltar',
                      style: TextStyle(fontSize: 13, color: colors.inkDim),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'RARO',
            style: TextStyle(
              fontFamily: RaroFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderBright),
              ),
              child: Icon(Icons.close, size: 16, color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _features = [
    'Gravação em 4K 60fps',
    'Buffer estendido',
    'Sem anúncios',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in _features)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    gradient: RaroGradients.redRadial,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 11, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(f, style: TextStyle(fontSize: 12.5, color: colors.ink)),
              ],
            ),
          ),
      ],
    );
  }
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Em breve'), duration: Duration(seconds: 1)),
    );
}
