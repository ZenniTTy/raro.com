import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';

class VoiceListeningIndicator extends StatelessWidget {
  const VoiceListeningIndicator({super.key, required this.state});

  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: switch (state) {
        VoiceListening() => const _VoiceHint(
          dotColor: RaroAccents.teal,
          label: 'DIGA “RARO” PARA GRAVAR',
          textAlpha: 0.35,
        ),
        VoicePaused() => const _VoiceHint(
          dotColor: RaroAccents.dotIdle,
          label: 'VOZ PAUSADA',
          textAlpha: 0.3,
        ),
        VoiceUnavailable() => const _VoiceHint(
          dotColor: RaroAccents.dotIdle,
          label: 'ATIVAR VOZ NAS CONFIGURAÇÕES',
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
