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
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

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
    final l10n = AppLocalizations.of(context);

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
                      l10n.onboarding2Title,
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
                          TextSpan(text: l10n.onboarding2Intro),
                          TextSpan(text: 'Raro Replay', style: mono),
                          TextSpan(text: l10n.onboarding2SavesLast),
                          TextSpan(text: l10n.onboarding2Seconds, style: white),
                          TextSpan(text: l10n.onboarding2Middle),
                          TextSpan(text: 'REC', style: mono),
                          TextSpan(text: l10n.onboarding2OrSay),
                          TextSpan(
                            text: l10n.onboarding2WakePhrase(
                              VoiceConfig.wakeWord,
                            ),
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
                label: l10n.onboardingNext,
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
