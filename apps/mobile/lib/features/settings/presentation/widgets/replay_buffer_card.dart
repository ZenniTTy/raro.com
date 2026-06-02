import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/settings_chip.dart';
import 'package:raro_shared/raro_shared.dart';

class ReplayBufferCard extends StatelessWidget {
  const ReplayBufferCard({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BufferDuration selected;
  final ValueChanged<BufferDuration> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: RaroGradients.rainbow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElev,
          borderRadius: BorderRadius.circular(16.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  RaroGradients.rainbow.createShader(bounds),
              child: const Text(
                'Raro Replay · Buffer rotativo',
                style: TextStyle(
                  fontFamily: RaroFonts.mono,
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Grava 15 ou 30 segundos antes do comando de voz "RARO" ou do '
              'botão na tela inicial.',
              style: TextStyle(fontSize: 12, height: 1.5, color: colors.inkDim),
            ),
            const SizedBox(height: 12),
            Text(
              'Duração do buffer',
              style: TextStyle(fontSize: 11, color: colors.inkDim),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SettingsChip(
                    label: '15s',
                    active: selected == BufferDuration.seconds15,
                    onTap: () => onSelected(BufferDuration.seconds15),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SettingsChip(
                    label: '30s',
                    active: selected == BufferDuration.seconds30,
                    onTap: () => onSelected(BufferDuration.seconds30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
