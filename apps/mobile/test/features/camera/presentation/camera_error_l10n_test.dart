import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/presentation/camera_error_l10n.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

void main() {
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  group('cameraErrorMessage', () {
    testWidgets('sessionInterrupted retorna mensagem distinta e acionável', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      expect(
        cameraErrorMessage(context, CameraErrorCode.sessionInterrupted),
        'Câmera interrompida. Tente novamente.',
      );
    });

    testWidgets('sessionFailed retorna a falha genérica de gravação', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      expect(
        cameraErrorMessage(context, CameraErrorCode.sessionFailed),
        'Falha ao gravar',
      );
    });

    testWidgets('null (erro não-mapeado) cai na falha genérica de gravação', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      expect(cameraErrorMessage(context, null), 'Falha ao gravar');
    });

    testWidgets('formatUnsupported reporta resolução indisponível', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      expect(
        cameraErrorMessage(context, CameraErrorCode.formatUnsupported),
        'Resolução indisponível neste aparelho.',
      );
    });
  });
}
