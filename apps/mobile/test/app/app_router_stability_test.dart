import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/app.dart';
import 'package:raro_mobile/core/analytics/firebase_analytics_provider.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

class _FakeSettingsStore implements SettingsStore {
  RecordingSettings _stored = const RecordingSettings();

  @override
  Future<RecordingSettings> load() async => _stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    _stored = settings;
  }
}

void main() {
  testWidgets('router mantém a MESMA instância quando settings mudam '
      '(mudar buffer/idioma NÃO pode resetar a navegação para a splash)', (
    tester,
  ) async {
    final analytics = _MockAnalytics();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(analytics),
          settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
        ],
        child: const RaroApp(),
      ),
    );
    await tester.pump();

    final routerBefore = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;

    final container = ProviderScope.containerOf(
      tester.element(find.byType(RaroApp)),
    );
    await container.read(settingsControllerProvider.future);
    await container
        .read(settingsControllerProvider.notifier)
        .setBufferDuration(BufferDuration.seconds15);
    await tester.pump();

    final routerAfterBuffer = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;
    expect(
      identical(routerBefore, routerAfterBuffer),
      isTrue,
      reason:
          'mudar bufferDuration recriou o GoRouter — '
          'a pilha de navegação reseta para a splash (parece app reiniciando)',
    );

    await container
        .read(settingsControllerProvider.notifier)
        .setLanguage(AppLanguage.es);
    await tester.pump();

    final routerAfterLanguage = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;
    expect(
      identical(routerBefore, routerAfterLanguage),
      isTrue,
      reason:
          'trocar idioma recriou o GoRouter — '
          'o app "reinicia" em vez de só repintar traduzido',
    );
  });
}
