import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/mic_halo_icon.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_pagination.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

class OnboardingPage1 extends ConsumerWidget {
  const OnboardingPage1({
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
                    const MicHaloIcon(),
                    const SizedBox(height: 40),
                    Text(
                      l10n.onboarding1Title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: RaroFonts.display,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: RaroFonts.body,
                          fontSize: 14,
                          height: 1.5,
                          color: colors.inkDim,
                        ),
                        children: [
                          TextSpan(text: l10n.onboarding1Say),
                          TextSpan(
                            text: '"${VoiceConfig.wakeWord}"',
                            style: TextStyle(
                              fontFamily: RaroFonts.mono,
                              color: colors.ink,
                            ),
                          ),
                          TextSpan(text: l10n.onboarding1SayTail),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboarding1Tagline('RARO'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: RaroFonts.mono,
                        fontSize: 13,
                        letterSpacing: 0.65,
                        color: colors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const OnboardingPagination(activeIndex: 0),
              const SizedBox(height: 28),
              OnboardingCta(
                label: l10n.onboardingNext,
                onPressed: () {
                  ref
                      .read(onboardingProgressProvider.notifier)
                      .advanceTo(OnboardingStep.replay);
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
