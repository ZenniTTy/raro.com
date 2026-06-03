import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_shared/raro_shared.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
    this.equivalentLabel,
  });

  final PlanType plan;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final String? equivalentLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected ? RaroGradients.planCardBorder : null,
          border: selected ? null : Border.all(color: colors.borderBright),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgElev,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Premium',
                    style: TextStyle(
                      fontFamily: RaroFonts.display,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (badge != null) _Badge(text: badge!),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: const TextStyle(
                      fontFamily: RaroFonts.display,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      plan.period,
                      style: TextStyle(
                        fontFamily: RaroFonts.mono,
                        fontSize: 10,
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
                      fontFamily: RaroFonts.mono,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _TrialBox(selected: selected),
              if (selected) ...[
                const SizedBox(height: 12),
                const _SelectedPill(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: RaroAccents.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: RaroFonts.mono,
          fontSize: 8,
          letterSpacing: 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: selected
            ? RaroAccents.yellow.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? RaroAccents.yellow.withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$days DIAS GRÁTIS',
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
              color: selected ? RaroAccents.yellow : colors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Cancele quando quiser',
            style: TextStyle(fontSize: 9, color: colors.inkDim),
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, size: 12, color: RaroAccents.yellow),
          SizedBox(width: 6),
          Text(
            'SELECIONADO',
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 10,
              letterSpacing: 1,
              color: RaroAccents.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
