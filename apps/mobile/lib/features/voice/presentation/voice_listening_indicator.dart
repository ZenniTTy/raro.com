import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

class VoiceListeningIndicator extends StatelessWidget {
  const VoiceListeningIndicator({super.key, required this.state});

  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      child: switch (state) {
        VoiceListening() => _VoiceHint(
          dotColor: RaroAccents.teal,
          label: l10n.voiceSayToRecord(VoiceConfig.wakeWord.toUpperCase()),
          textAlpha: 0.35,
        ),
        VoicePaused() => _VoiceHint(
          dotColor: RaroAccents.dotIdle,
          label: l10n.voicePaused,
          textAlpha: 0.3,
        ),
        VoiceUnavailable() => _VoiceHint(
          dotColor: RaroAccents.dotIdle,
          label: l10n.voiceEnableInSettings,
          textAlpha: 0.45,
        ),
        VoiceIdle() => const SizedBox.shrink(),
      },
    );
  }
}

class _VoiceHint extends StatelessWidget {
  const _VoiceHint({
    required this.dotColor,
    required this.label,
    required this.textAlpha,
  });

  final Color dotColor;
  final String label;
  final double textAlpha;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: RaroFonts.mono,
            fontSize: 10,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: textAlpha),
          ),
        ),
      ],
    );
  }
}
