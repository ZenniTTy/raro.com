import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_shared/raro_shared.dart';

class LanguageGrid extends StatelessWidget {
  const LanguageGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;

  static const _options = <(AppLanguage, String, String)>[
    (AppLanguage.ptBr, '🇧🇷', 'PT'),
    (AppLanguage.es, '🇪🇸', 'ES'),
    (AppLanguage.en, '🇺🇸', 'EN'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (value, flag, label) in _options) ...[
          Expanded(
            child: _LanguageButton(
              flag: flag,
              label: label,
              active: selected == value,
              onTap: () => onSelected(value),
            ),
          ),
          if (value != _options.last.$1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? RaroAccents.selectedSurface : colors.bgCard,
          border: Border.all(
            color: active ? Colors.white : colors.borderBright,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: RaroFonts.mono,
                fontSize: 11,
                letterSpacing: 1.5,
                color: active ? Colors.white : colors.inkDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
