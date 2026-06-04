import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';

class SettingsChip extends StatelessWidget {
  const SettingsChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? RaroAccents.selectedSurface : colors.bgCard,
          border: Border.all(
            color: active ? Colors.white : colors.borderBright,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: active ? Colors.white : colors.inkDim,
                ),
              ),
            ),
            if (hint != null) ...[
              const SizedBox(width: 6),
              Text(
                hint!,
                style: TextStyle(
                  fontSize: 10,
                  color: (active ? Colors.white : colors.inkDim).withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
