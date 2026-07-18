import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/replay_arm_ring.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  ReplayArmRingPainter? armPainter(WidgetTester tester) {
    final paints = tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(ReplayArmRing),
        matching: find.byType(CustomPaint),
      ),
    );
    for (final p in paints) {
      final fg = p.foregroundPainter;
      if (fg is ReplayArmRingPainter) return fg;
    }
    return null;
  }

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      host(
        const ReplayArmRing(
          armed: true,
          windowSeconds: 15,
          recording: false,
          child: SizedBox(key: Key('rec'), width: 72, height: 72),
        ),
      ),
    );
    expect(find.byKey(const Key('rec')), findsOneWidget);
  });

  testWidgets('when armed shows the fill ring painter', (tester) async {
    await tester.pumpWidget(
      host(
        const ReplayArmRing(
          armed: true,
          windowSeconds: 15,
          recording: false,
          child: SizedBox(width: 72, height: 72),
        ),
      ),
    );
    await tester.pump();
    expect(armPainter(tester), isNotNull);
  });

  testWidgets('progress grows over the window then holds full', (tester) async {
    await tester.pumpWidget(
      host(
        const ReplayArmRing(
          armed: true,
          windowSeconds: 2,
          recording: false,
          child: SizedBox(width: 72, height: 72),
        ),
      ),
    );
    await tester.pump();
    final progressStart = armPainter(tester)!.progress;
    expect(progressStart, lessThan(0.2));

    await tester.pump(const Duration(seconds: 1));
    final progressMid = armPainter(tester)!.progress;
    expect(progressMid, greaterThan(progressStart));

    await tester.pump(const Duration(seconds: 2));
    final progressEnd = armPainter(tester)!.progress;
    expect(progressEnd, closeTo(1.0, 0.01));
  });

  testWidgets('when not armed shows no ring painter', (tester) async {
    await tester.pumpWidget(
      host(
        const ReplayArmRing(
          armed: false,
          windowSeconds: 15,
          recording: false,
          child: SizedBox(width: 72, height: 72),
        ),
      ),
    );
    await tester.pump();
    expect(armPainter(tester), isNull);
  });

  testWidgets(
    'while recording hides the ring (recording state owns the button)',
    (tester) async {
      await tester.pumpWidget(
        host(
          const ReplayArmRing(
            armed: true,
            windowSeconds: 15,
            recording: true,
            child: SizedBox(width: 72, height: 72),
          ),
        ),
      );
      await tester.pump();
      expect(armPainter(tester), isNull);
    },
  );
}
