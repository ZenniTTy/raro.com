import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/application/persist_recording_scope.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.plan,
    required this.onBack,
    required this.onConfirmed,
    this.onPendingSaved,
  });

  final PlanType plan;
  final VoidCallback onBack;
  final VoidCallback onConfirmed;
  final ValueChanged<String>? onPendingSaved;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref
          .read(subscriptionControllerProvider.notifier)
          .subscribe(plan: widget.plan, now: DateTime.now());
      if (!mounted) return;
      switch (result) {
        case PurchaseFlowResult.success:
          if (widget.onPendingSaved != null) {
            final savedId = await persistPendingFor(ref);
            if (!mounted) return;
            if (savedId != null) {
              widget.onPendingSaved!(savedId);
              return;
            }
          }
          widget.onConfirmed();
        case PurchaseFlowResult.cancelled:
          break;
        case PurchaseFlowResult.failed:
        case PurchaseFlowResult.unavailable:
          _showSnack(l10n.paywallPurchaseFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final l10n = AppLocalizations.of(context);
    final period = widget.plan == PlanType.monthly
        ? l10n.paywallPeriodMonthly
        : l10n.paywallPeriodYearly;

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: widget.onBack),
            const _GradLine(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrderSummary(plan: widget.plan, period: period),
                    const SizedBox(height: 24),
                    const _SecurityNote(),
                  ],
                ),
              ),
            ),
            _BottomBar(busy: _busy, onConfirm: _confirm),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderBright),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: colors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).checkoutTitle,
            style: const TextStyle(
              fontFamily: RaroFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.plan, required this.period});

  final PlanType plan;
  final String period;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    const trialDays = SubscriptionConfig.freeTrialDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElev,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            text: AppLocalizations.of(context).checkoutOrderSummary,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgDeep,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Image.asset(
                  'assets/logo/raro_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RARO ${AppLocalizations.of(context).planPremium}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).checkoutSubscription(period),
                      style: TextStyle(fontSize: 11, color: colors.inkDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _GradLine(),
          const SizedBox(height: 12),
          _SummaryRow(
            label: AppLocalizations.of(context).checkoutTrialPeriod(trialDays),
            value: 'R\$ 0,00',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: AppLocalizations.of(context).checkoutAfterTrial,
            value:
                '${plan.priceLabel}'
                '${plan == PlanType.monthly ? AppLocalizations.of(context).planPerMonth : AppLocalizations.of(context).planPerYear}',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: colors.inkDim)),
        Text(
          value,
          style: const TextStyle(
            fontFamily: RaroFonts.mono,
            fontSize: 12.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 14, color: colors.inkFaint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppLocalizations.of(context).checkoutProcessedBy('RARO'),
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: colors.inkFaint,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.busy, required this.onConfirm});

  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          Opacity(
            opacity: busy ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: busy,
              child: OnboardingCta(
                label: AppLocalizations.of(context).checkoutConfirm,
                primary: true,
                onPressed: onConfirm,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).checkoutStoreHint,
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 10,
              letterSpacing: 1.2,
              color: colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => RaroGradients.rainbow.createShader(b),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: RaroFonts.mono,
          fontSize: 10,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GradLine extends StatelessWidget {
  const _GradLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(gradient: RaroGradients.rainbow),
    );
  }
}
