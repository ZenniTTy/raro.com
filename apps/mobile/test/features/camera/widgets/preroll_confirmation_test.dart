import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/preroll_confirmation.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Stack(children: [child])),
  );

  testWidgets('shows the "últimos Ns incluídos" copy with the window seconds', (
    tester,
  ) async {
    await tester.pumpWidget(host(const PrerollConfirmation(seconds: 30)));
    await tester.pump();
    expect(find.text('últimos 30s incluídos'), findsOneWidget);
  });

  testWidgets('reflects a different window', (tester) async {
    await tester.pumpWidget(host(const PrerollConfirmation(seconds: 15)));
    await tester.pump();
    expect(find.text('últimos 15s incluídos'), findsOneWidget);
  });

  testWidgets('fades out and removes itself after the lifetime', (
    tester,
  ) async {
    await tester.pumpWidget(host(const PrerollConfirmation(seconds: 15)));
    await tester.pump();
    expect(find.byType(PrerollConfirmation), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
    final opacity = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(PrerollConfirmation),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(opacity.opacity.value, lessThan(0.05));
  });
}
