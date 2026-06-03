import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/checkout/domain/payment_method.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_shared/raro_shared.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.plan,
    required this.onBack,
    required this.onConfirmed,
  });

  final PlanType plan;
  final VoidCallback onBack;
  final VoidCallback onConfirmed;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod? _method;

  Future<void> _confirm() async {
    if (_method == null) return;
    await ref
        .read(subscriptionControllerProvider.notifier)
        .subscribe(now: DateTime.now());
    if (!mounted) return;
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final period = widget.plan == PlanType.monthly ? 'mensal' : 'anual';

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
                    const _SectionLabel(text: 'Método de pagamento'),
                    const SizedBox(height: 10),
                    for (final m in PaymentMethod.values) ...[
                      _PayTile(
                        method: m,
                        selected: _method == m,
                        onTap: () => setState(() => _method = m),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    const _SecurityNote(),
                  ],
                ),
              ),
            ),
            _BottomBar(method: _method, onConfirm: _confirm),
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
          const Text(
            'Finalizar assinatura',
            style: TextStyle(
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
          const _SectionLabel(text: 'RESUMO DO PEDIDO'),
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
                    const Text(
                      'RARO Premium',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Assinatura $period',
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
          const _SummaryRow(
            label: 'Período de teste ($trialDays dias)',
            value: 'R\$ 0,00',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Após o teste',
            value: '${plan.priceLabel}${plan.period}',
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

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? RaroAccents.selectedSurface : colors.bgElev,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : colors.borderBright,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.bgDeep,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: method == PaymentMethod.apple
                  ? Icon(Icons.apple, size: 22, color: colors.ink)
                  : const SizedBox(
                      width: 18,
                      height: 20,
                      child: CustomPaint(painter: _GooglePlayPainter()),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.subtitle,
                    style: TextStyle(fontSize: 11, color: colors.inkDim),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? RaroGradients.redRadial : null,
                border: Border.all(
                  color: selected ? Colors.white : colors.borderBright,
                ),
              ),
              child: selected
                  ? const Center(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
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
            'Pagamento processado pela App Store ou Google Play. '
            'O RARO não armazena dados do seu cartão.',
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
  const _BottomBar({required this.method, required this.onConfirm});

  final PaymentMethod? method;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final enabled = method != null;
    final hint = method?.confirmHint ?? 'SELECIONE UM MÉTODO ACIMA';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !enabled,
              child: OnboardingCta(
                label: 'Confirmar assinatura',
                primary: true,
                onPressed: onConfirm,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
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

class _GooglePlayPainter extends CustomPainter {
  const _GooglePlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = Offset(w * 0.62, h / 2);
    const topLeft = Offset.zero;
    final bottomLeft = Offset(0, h);
    final tip = Offset(w, h / 2);

    void tri(List<Offset> pts, List<Color> colors) {
      final path = Path()..addPolygon(pts, true);
      final rect = path.getBounds();
      final paint = Paint()
        ..shader = LinearGradient(colors: colors).createShader(rect);
      canvas.drawPath(path, paint);
    }

    tri(
      [topLeft, mid, Offset(w * 0.5, 0)],
      const [RaroAccents.green, RaroAccents.teal],
    );
    tri(
      [bottomLeft, mid, Offset(w * 0.5, h)],
      const [RaroAccents.blue, RaroAccents.purple],
    );
    tri(
      [Offset(w * 0.5, 0), mid, tip],
      const [RaroAccents.yellow, RaroAccents.orange],
    );
    tri(
      [Offset(w * 0.5, h), mid, tip],
      const [RaroAccents.red, RaroAccents.red],
    );
  }

  @override
  bool shouldRepaint(_GooglePlayPainter oldDelegate) => false;
}
