import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/app/router.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/permissions/application/permission_status_provider.dart';
import 'package:raro_mobile/features/permissions/data/permission_gateway.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';

class _MockPermissionGateway extends Mock implements PermissionGateway {}

class _FakeSettingsStore implements SettingsStore {
  RecordingSettings stored = const RecordingSettings();

  @override
  Future<RecordingSettings> load() async => stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    stored = settings;
  }
}

void main() {
  late _MockPermissionGateway gateway;

  setUp(() {
    gateway = _MockPermissionGateway();
    when(gateway.cameraStatus).thenAnswer((_) async => false);
    when(gateway.microphoneStatus).thenAnswer((_) async => false);
  });

  Widget app() {
    return ProviderScope(
      overrides: [
        permissionGatewayProvider.overrideWithValue(gateway),
        settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
      ],
      child: MaterialApp.router(
        theme: buildRaroDarkTheme(),
        routerConfig: buildAppRouter(),
      ),
    );
  }

  group('appRouter', () {
    testWidgets('inicia no splash (/splash)', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.byKey(const Key('splash_logo')), findsOneWidget);
    });

    testWidgets('splash auto-navega para onboarding 1 após 1.8s', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      expect(find.text('Grave sem tocar'), findsOneWidget);
    });

    testWidgets('onboarding 1 → Avançar → onboarding 2', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Nunca perca o momento'), findsOneWidget);
    });

    testWidgets('onboarding 2 → Avançar → permissions (P04)', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Permissões essenciais'), findsOneWidget);
    });

    testWidgets('onboarding 1 → Pular → permissions (P04)', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      expect(find.text('Permissões essenciais'), findsOneWidget);
    });

    Future<void> goToCamera(WidgetTester tester) async {
      when(gateway.requestCamera).thenAnswer((_) async => true);
      when(gateway.requestMicrophone).thenAnswer((_) async => true);
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      // Camera tem animações infinitas (buffer pill pulse) → pumpAndSettle
      // nunca converge; pump bounded deixa a transição de rota completar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('permissions → Continuar (granted) → camera (P05)', (
      tester,
    ) async {
      await goToCamera(tester);
      expect(find.text('DIGA “RARO” PARA GRAVAR'), findsOneWidget);
    });

    testWidgets('camera → settings (P06) abre a tela real', (tester) async {
      await goToCamera(tester);
      await tester.tap(find.byKey(const Key('camera_settings_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Qualidade de Gravação'), findsOneWidget);
    });

    testWidgets('camera → gallery (P07) abre a tela real', (tester) async {
      await goToCamera(tester);
      await tester.tap(find.byKey(const Key('camera_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Galeria'), findsOneWidget);
    });
  });
}
