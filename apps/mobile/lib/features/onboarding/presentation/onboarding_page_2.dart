import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/buffer_visualization.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_pagination.dart';

class OnboardingPage2 extends ConsumerWidget {
  const OnboardingPage2({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<RaroColors>()!;

    final mono = TextStyle(fontFamily: RaroFonts.mono, color: colors.ink);
    final white = TextStyle(color: colors.ink);

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              OnboardingHeader(onSkip: onSkip),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BufferVisualization(),
                    const SizedBox(height: 32),
                    Text(
                      'Nunca perca o momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: RaroFonts.display,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.56,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: RaroFonts.body,
                          fontSize: 13.5,
                          height: 1.5,
                          color: colors.inkDim,
                        ),
                        children: [
                          const TextSpan(text: 'O '),
                          TextSpan(text: 'Raro Replay', style: mono),
                          const TextSpan(
                            text: ' salva automaticamente os últimos ',
                          ),
                          TextSpan(text: '15 ou 30 segundos', style: white),
                          const TextSpan(
                            text:
                                '. Aconteceu algo importante? '
                                'Basta apertar o botão ',
                          ),
                          TextSpan(text: 'REC', style: mono),
                          const TextSpan(text: ' ou dizer: '),
                          TextSpan(
                            text: '"Raro, começar a gravar."',
                            style: white,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const OnboardingPagination(activeIndex: 1),
              const SizedBox(height: 28),
              OnboardingCta(
                label: 'Avançar',
                primary: true,
                onPressed: () {
                  ref
                      .read(onboardingProgressProvider.notifier)
                      .advanceTo(OnboardingStep.permissions);
                  onNext();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
