import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/legal/domain/legal_document.dart';
import 'package:raro_mobile/features/legal/presentation/legal_document_screen.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart';

void main() {
  Widget host(LegalDocument document, {VoidCallback? onBack}) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildRaroDarkTheme(),
      home: LegalDocumentScreen(document: document, onBack: onBack ?? () {}),
    );
  }

  Future<void> pumpReady(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('privacidade mostra título e trecho conhecido', (tester) async {
    await pumpReady(tester, host(LegalDocument.privacy));

    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.textContaining(LegalUrls.privacy), findsWidgets);
    expect(find.textContaining('Vitor Autorino Lopes'), findsOneWidget);
    expect(find.textContaining('rarocan1@gmail.com'), findsOneWidget);
    expect(find.textContaining('Não usamos cookies'), findsOneWidget);
  });

  testWidgets('termos mostra título e trecho conhecido', (tester) async {
    await pumpReady(tester, host(LegalDocument.terms));

    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.textContaining(LegalUrls.terms), findsWidgets);
    expect(find.textContaining('Vitor Autorino Lopes'), findsOneWidget);
    expect(find.textContaining('Restaurar compras'), findsOneWidget);
  });

  testWidgets('voltar dispara onBack', (tester) async {
    var backs = 0;
    await pumpReady(tester, host(LegalDocument.privacy, onBack: () => backs++));
    await tester.tap(find.byKey(const Key('legal_back_button')));
    await tester.pump();
    expect(backs, 1);
  });
}
