import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/splash/presentation/splash_screen.dart';

void main() {
  Widget harness({VoidCallback? onComplete}) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: SplashScreen(onComplete: onComplete),
      ),
    );
  }

  group('SplashScreen', () {
    testWidgets('mostra logo + dot loader + tagline', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.byKey(const Key('splash_logo')), findsOneWidget);
      expect(find.byKey(const Key('splash_loader')), findsOneWidget);
      expect(find.text('CAPTURE · UNSCRIPTED'), findsOneWidget);

      // limpa o timer pendente de auto-nav
      await tester.pump(const Duration(milliseconds: 1800));
    });

    testWidgets('tagline usa JetBrains Mono', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      final tagline = tester.widget<Text>(find.text('CAPTURE · UNSCRIPTED'));
      expect(tagline.style?.fontFamily, RaroFonts.mono);

      await tester.pump(const Duration(milliseconds: 1800));
    });

    testWidgets('chama onComplete após 1.8s', (tester) async {
      var completed = false;
      await tester.pumpWidget(harness(onComplete: () => completed = true));
      await tester.pump();

      expect(completed, isFalse);
      await tester.pump(const Duration(milliseconds: 1799));
      expect(completed, isFalse);
      await tester.pump(const Duration(milliseconds: 2));
      expect(completed, isTrue);
    });

    testWidgets('não chama onComplete se desmontado antes de 1.8s', (
      tester,
    ) async {
      var completed = false;
      await tester.pumpWidget(harness(onComplete: () => completed = true));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SizedBox.shrink())),
      );
      await tester.pump(const Duration(milliseconds: 2000));

      expect(completed, isFalse);
    });
  });
}
