import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/paywall/presentation/paywall_screen.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_mobile/features/voice/presentation/voice_listening_indicator.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

void main() {
  Widget host(Locale locale, Widget child) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: child,
      ),
    );
  }

  group('paywall renderiza traduzido por locale', () {
    Widget paywall(Locale locale) =>
        host(locale, PaywallScreen(onClose: () {}, onCheckout: (_) {}));

    testWidgets('pt: título, badge e trial interpolado', (tester) async {
      await tester.pumpWidget(paywall(const Locale('pt', 'BR')));
      expect(find.text('Escolha seu plano'), findsOneWidget);
      expect(find.text('MELHOR OFERTA'), findsOneWidget);
      expect(find.textContaining('30 dias grátis'), findsWidgets);
    });

    testWidgets('en: título, badge e trial interpolado', (tester) async {
      await tester.pumpWidget(paywall(const Locale('en')));
      expect(find.text('Choose your plan'), findsOneWidget);
      expect(find.text('BEST OFFER'), findsOneWidget);
      expect(find.textContaining('30 days free'), findsWidgets);
      expect(find.text('Escolha seu plano'), findsNothing);
    });

    testWidgets('es: título e badge', (tester) async {
      await tester.pumpWidget(paywall(const Locale('es')));
      expect(find.text('Elige tu plan'), findsOneWidget);
      expect(find.text('MEJOR OFERTA'), findsOneWidget);
    });
  });

  group('camera voice hint renderiza traduzido com wake word intacta', () {
    Widget indicator(Locale locale) => host(
      locale,
      const Scaffold(body: VoiceListeningIndicator(state: VoiceListening())),
    );

    testWidgets('pt mantém RARO dentro da frase', (tester) async {
      await tester.pumpWidget(indicator(const Locale('pt', 'BR')));
      expect(find.text('DIGA “RARO” PARA GRAVAR'), findsOneWidget);
    });

    testWidgets('en traduz a moldura mas NUNCA a wake word', (tester) async {
      await tester.pumpWidget(indicator(const Locale('en')));
      expect(find.text('SAY “RARO” TO RECORD'), findsOneWidget);
    });

    testWidgets('es traduz a moldura mas NUNCA a wake word', (tester) async {
      await tester.pumpWidget(indicator(const Locale('es')));
      expect(find.text('DI “RARO” PARA GRABAR'), findsOneWidget);
    });
  });
}
