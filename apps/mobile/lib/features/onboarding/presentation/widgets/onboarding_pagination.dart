import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class OnboardingPagination extends StatelessWidget {
  const OnboardingPagination({
    super.key,
    required this.activeIndex,
    this.count = 2,
  });

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Dot(active: i == activeIndex),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: active ? RaroGradients.rainbow : null,
        color: active ? null : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
