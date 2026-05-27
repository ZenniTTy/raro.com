import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';

void main() {
  testWidgets('renders rule-of-thirds and grain overlays', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CameraPreviewWidget())),
      ),
    );

    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final hasRuleOfThirds = paints.any((p) => p.painter is RuleOfThirdsPainter);
    final hasGrain = paints.any((p) => p.painter is ViewportGrainPainter);
    expect(
      hasRuleOfThirds,
      isTrue,
      reason: 'RuleOfThirdsPainter must be in widget tree',
    );
    expect(
      hasGrain,
      isTrue,
      reason: 'ViewportGrainPainter must be in widget tree',
    );
  });
}
