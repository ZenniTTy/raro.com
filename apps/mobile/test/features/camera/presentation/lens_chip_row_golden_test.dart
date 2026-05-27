import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/presentation/lens_chip_row.dart';

void main() {
  goldenTest(
    'lens_chip_row',
    fileName: 'lens_chip_row',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'both available, wide selected',
          child: ColoredBox(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LensChipRow(
                availableLenses: const [LensType.ultraWide, LensType.wide],
                selected: LensType.wide,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'both available, ultraWide selected',
          child: ColoredBox(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LensChipRow(
                availableLenses: const [LensType.ultraWide, LensType.wide],
                selected: LensType.ultraWide,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'only wide available',
          child: ColoredBox(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LensChipRow(
                availableLenses: const [LensType.wide],
                selected: LensType.wide,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
