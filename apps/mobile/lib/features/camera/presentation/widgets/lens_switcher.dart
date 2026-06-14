import 'package:flutter/material.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

class LensSwitcher extends StatelessWidget {
  const LensSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
    this.ultraWideEnabled = true,
  });

  final LensType selected;
  final ValueChanged<LensType> onSelected;
  final bool ultraWideEnabled;

  static const List<LensType> _lenses = [LensType.ultraWide, LensType.wide];

  String _labelFor(LensType lens) => lens == LensType.ultraWide ? '0.5×' : '1×';

  bool _isDisabled(LensType lens) =>
      lens == LensType.ultraWide && !ultraWideEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lens in _lenses) ...[
              _LensChip(
                label: _labelFor(lens),
                active: lens == selected && !_isDisabled(lens),
                disabled: _isDisabled(lens),
                onTap: _isDisabled(lens) ? null : () => onSelected(lens),
              ),
              if (lens != _lenses.last) const SizedBox(width: 6),
            ],
          ],
        ),
        if (!ultraWideEnabled) ...[
          const SizedBox(height: 4),
          Text(
            'indisponível em 4K60',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _LensChip extends StatelessWidget {
  const _LensChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final bool active;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = disabled
        ? Colors.white.withValues(alpha: 0.3)
        : (active ? Colors.black : Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: active ? Colors.white : Colors.black.withValues(alpha: 0.6),
          shape: StadiumBorder(
            side: BorderSide(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: disabled ? 0.1 : 0.2),
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
