import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_mobile/features/voice/presentation/voice_listening_indicator.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('listening mostra o hint DIGA RARO', (tester) async {
    await tester.pumpWidget(
      host(const VoiceListeningIndicator(state: VoiceListening())),
    );
    expect(find.textContaining('RARO'), findsOneWidget);
  });

  testWidgets('paused mostra estado pausado e permanece visível', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const VoiceListeningIndicator(state: VoicePaused())),
    );
    expect(find.byType(VoiceListeningIndicator), findsOneWidget);
    expect(find.textContaining('PAUSADA'), findsOneWidget);
  });

  testWidgets('unavailable convida a ativar nas Configurações', (tester) async {
    await tester.pumpWidget(
      host(const VoiceListeningIndicator(state: VoiceUnavailable())),
    );
    expect(find.textContaining('CONFIGURAÇÕES'), findsOneWidget);
  });

  testWidgets('idle não renderiza hint visível', (tester) async {
    await tester.pumpWidget(
      host(const VoiceListeningIndicator(state: VoiceIdle())),
    );
    expect(find.textContaining('RARO'), findsNothing);
  });
}
