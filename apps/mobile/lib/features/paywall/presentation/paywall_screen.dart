import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/presentation/widgets/plan_card.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    const trialDays = SubscriptionConfig.freeTrialDays;
    final equivalent = l10n.paywallMonthlyEquivalent(
      PlanPricing.yearlyMonthlyEquivalentBRL
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _PaywallBackdrop()),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(onClose: widget.onClose),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.paywallTitle,
                          style: const TextStyle(
                            fontFamily: RaroFonts.display,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.paywallSubtitle('Raro Camera', trialDays),
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
                                onTap: () => setState(
                                  () => _selected = PlanType.monthly,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PlanCard(
                                key: const Key('plan_card_yearly'),
                                plan: PlanType.yearly,
                                selected: _selected == PlanType.yearly,
                                highlight: true,
                                badge: l10n.paywallBestOffer,
                                equivalentLabel: equivalent,
                                onTap: () =>
                                    setState(() => _selected = PlanType.yearly),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _LegalLinks(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    children: [
                      OnboardingCta(
                        label: l10n.paywallSubscribeNow,
                        primary: true,
                        onPressed: () => widget.onCheckout(_selected),
                      ),
                      const SizedBox(height: 8),
                      OnboardingCta(
                        label: l10n.paywallRestorePurchases,
                        onPressed: () => _comingSoon(context),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: widget.onClose,
                        child: Text(
                          l10n.paywallBack,
                          style: TextStyle(fontSize: 13, color: colors.inkDim),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.paywallLegal(
                          _selected == PlanType.yearly
                              ? l10n.paywallPeriodYearly
                              : l10n.paywallPeriodMonthly,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallBackdrop extends StatelessWidget {
  const _PaywallBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: RaroGradients.paywallGlowWarm),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: RaroGradients.paywallGlowCool),
          ),
        ),
        Center(
          child: Transform.rotate(
            angle: -0.15,
            child: Text(
              'RARO',
              style: TextStyle(
                fontFamily: RaroFonts.display,
                fontSize: 180,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
      ],
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

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final style = TextStyle(fontSize: 12, color: colors.inkDim);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _comingSoon(context),
          child: Text(AppLocalizations.of(context).termsOfUse, style: style),
        ),
        Text('  ·  ', style: style),
        GestureDetector(
          onTap: () => _comingSoon(context),
          child: Text(AppLocalizations.of(context).privacyPolicy, style: style),
        ),
      ],
    );
  }
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).comingSoon),
        duration: const Duration(seconds: 1),
      ),
    );
}
