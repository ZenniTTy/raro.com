import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';

class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(FocusPoint(x: 0, y: 0));
  });

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

  testWidgets('does not route tap through Flutter GestureDetector to focusAt '
      '(tap-to-focus is detected natively via UITapGestureRecognizer)', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedFormats: [
          FormatCapability(
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
            requiresPhysicalLens: false,
          ),
        ],
      ),
    );
    when(repo.stopSession).thenAnswer((_) async {});
    when(() => repo.focusAt(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: CameraPreviewWidget(showOverlays: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(GestureDetector),
      findsNothing,
      reason:
          'no Flutter GestureDetector over the UiKitView — Eager'
          'GestureRecognizer hands the tap to the native view, so a parent '
          'GestureDetector would never fire onTapDown',
    );

    final widgetBox = tester.getRect(find.byType(CameraPreviewWidget));
    await tester.tapAt(widgetBox.center);
    await tester.pumpAndSettle();

    verifyNever(() => repo.focusAt(any()));
  });

  testWidgets(
    'does not render any FocusRingOverlay widget (native renders ring)',
    (tester) async {
      final repo = _MockRepo();
      when(repo.discoverCapabilities).thenAnswer(
        (_) async => CameraCapabilities(
          availableLenses: [LensType.wide],
          supportedFormats: [
            FormatCapability(
              resolution: Resolution.fhd1080,
              fps: Fps.fps30,
              requiresPhysicalLens: false,
            ),
          ],
        ),
      );
      when(repo.stopSession).thenAnswer((_) async {});
      when(() => repo.focusAt(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cameraRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: CameraPreviewWidget(showOverlays: true),
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(200, 400));
      await tester.pump(const Duration(milliseconds: 100));

      final anyFocusRing = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('FocusRing'),
      );
      expect(anyFocusRing.evaluate(), isEmpty);
    },
  );
}
