import 'package:flutter/material.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

class LensChipRow extends StatelessWidget {
  const LensChipRow({
    super.key,
    required this.availableLenses,
    required this.selected,
    required this.onSelected,
  });

  final List<LensType> availableLenses;
  final LensType selected;
  final ValueChanged<LensType> onSelected;

  String _labelFor(LensType l) => l == LensType.ultraWide ? '0.5×' : '1×';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final lens in availableLenses) ...[
          _LensChip(
            label: _labelFor(lens),
            selected: lens == selected,
            onTap: () => onSelected(lens),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LensChip extends StatelessWidget {
  const _LensChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
