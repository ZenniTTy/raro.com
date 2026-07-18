import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

class SubscriptionPopup extends StatelessWidget {
  const SubscriptionPopup({
    super.key,
    required this.onSubscribe,
    required this.onLater,
  });

  final VoidCallback onSubscribe;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    const trialDays = SubscriptionConfig.freeTrialDays;

    return Stack(
      children: [
        const ModalBarrier(color: Colors.black87, dismissible: false),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: RaroGradients.modalBorder,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  color: colors.bgElev.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              RaroGradients.rainbow.createShader(bounds),
                          child: Text(
                            AppLocalizations.of(context).popupEyebrow,
                            style: const TextStyle(
                              fontFamily: RaroFonts.mono,
                              fontSize: 10,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onLater,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: colors.inkDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).popupTitle,
                      style: const TextStyle(
                        fontFamily: RaroFonts.display,
                        fontSize: 26,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RichBody(
                      colors: colors,
                      segments: [
                        _Seg(AppLocalizations.of(context).popupBody1),
                        _Seg(
                          AppLocalizations.of(context).popupBodyBold,
                          bold: true,
                        ),
                        _Seg(AppLocalizations.of(context).popupBody2),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _RichBody(
                      colors: colors,
                      segments: [
                        _Seg(AppLocalizations.of(context).popupTrial1),
                        _Seg(
                          AppLocalizations.of(
                            context,
                          ).popupTrialBold(trialDays),
                          bold: true,
                        ),
                        _Seg(
                          AppLocalizations.of(context).popupTrial2(trialDays),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OnboardingCta(
                      label: AppLocalizations.of(context).paywallSubscribeNow,
                      onPressed: onSubscribe,
                      primary: true,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onLater,
                        child: Text(
                          AppLocalizations.of(context).popupMaybeLater,
                          style: TextStyle(fontSize: 13, color: colors.inkDim),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Seg {
  const _Seg(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class _RichBody extends StatelessWidget {
  const _RichBody({required this.colors, required this.segments});

  final RaroColors colors;
  final List<_Seg> segments;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final s in segments)
            TextSpan(
              text: s.text,
              style: TextStyle(color: s.bold ? colors.ink : colors.inkDim),
            ),
        ],
      ),
      style: const TextStyle(
        fontFamily: RaroFonts.body,
        fontSize: 13.5,
        height: 1.5,
      ),
    );
  }
}
