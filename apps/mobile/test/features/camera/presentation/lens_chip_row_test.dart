import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/presentation/lens_chip_row.dart';

void main() {
  testWidgets('hides ultraWide chip when unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LensChipRow(
            availableLenses: const [LensType.wide],
            selected: LensType.wide,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('0.5×'), findsNothing);
    expect(find.text('1×'), findsOneWidget);
  });

  testWidgets('shows both chips when both lenses available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LensChipRow(
            availableLenses: const [LensType.ultraWide, LensType.wide],
            selected: LensType.wide,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('0.5×'), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
  });

  testWidgets('emits onSelected with tapped lens', (tester) async {
    LensType? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LensChipRow(
            availableLenses: const [LensType.ultraWide, LensType.wide],
            selected: LensType.wide,
            onSelected: (l) => tapped = l,
          ),
        ),
      ),
    );
    await tester.tap(find.text('0.5×'));
    expect(tapped, LensType.ultraWide);
  });
}
