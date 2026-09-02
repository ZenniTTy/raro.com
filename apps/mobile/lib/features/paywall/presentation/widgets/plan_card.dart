import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
    this.equivalentLabel,
    this.highlight = false,
  });

  final PlanType plan;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final String? equivalentLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected ? RaroGradients.planCardBorder : null,
          border: selected
              ? null
              : Border.all(
                  color: highlight
                      ? RaroAccents.yellow.withValues(alpha: 0.9)
                      : colors.borderBright,
                  width: highlight ? 1.5 : 1,
                ),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: RaroAccents.yellow.withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: RaroAccents.orange.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgElev,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('👑', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              const Text(
                'RARO CAM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: RaroFonts.plans,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: RaroAccents.yellow,
                ),
              ),
              Text(
                AppLocalizations.of(context).planPremium,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: RaroFonts.plans,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: RaroAccents.yellow,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).planUnlockPotential,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: RaroFonts.plans,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: colors.inkDim,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: const TextStyle(
                      fontFamily: RaroFonts.plans,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      plan == PlanType.monthly
                          ? AppLocalizations.of(context).planPerMonth
                          : AppLocalizations.of(context).planPerYear,
                      style: TextStyle(
                        fontFamily: RaroFonts.plans,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: colors.inkDim,
                      ),
                    ),
                  ),
                ],
              ),
              if (equivalentLabel != null) ...[
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (b) => RaroGradients.rainbow.createShader(b),
                  child: Text(
                    equivalentLabel!,
                    style: const TextStyle(
                      fontFamily: RaroFonts.plans,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _TrialBox(selected: selected),
              const SizedBox(height: 12),
              const _PlanFeatures(),
              if (selected) ...[
                const SizedBox(height: 12),
                const _SelectedPill(),
              ],
            ],
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 12), child: card),
        if (badge != null)
          Positioned(top: 0, right: 8, child: _Badge(text: badge!)),
      ],
    );
  }
}

class _PlanFeatures extends StatelessWidget {
  const _PlanFeatures();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final l10n = AppLocalizations.of(context);
    final features = <(String, String)>[
      ('\u{1F4F9}', l10n.planFeature4k),
      ('\u{23F1}\u{FE0F}', l10n.planFeatureBuffer),
      ('\u{1F6AB}', l10n.planFeatureNoAds),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (emoji, label) in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: RaroFonts.plans,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: RaroAccents.red,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: RaroAccents.red.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: RaroFonts.plans,
              fontSize: 9,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialBox extends StatelessWidget {
  const _TrialBox({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    const days = SubscriptionConfig.freeTrialDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: RaroAccents.yellow.withValues(alpha: selected ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: RaroAccents.yellow.withValues(alpha: selected ? 0.45 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, size: 12, color: RaroAccents.yellow),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).planFreeDays(days),
                style: const TextStyle(
                  fontFamily: RaroFonts.plans,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: RaroAccents.yellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).planCancelAnytime,
            style: TextStyle(
              fontFamily: RaroFonts.plans,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: colors.inkDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: RaroAccents.yellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, size: 12, color: RaroAccents.yellow),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).planSelected,
            style: const TextStyle(
              fontFamily: RaroFonts.plans,
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: RaroAccents.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
