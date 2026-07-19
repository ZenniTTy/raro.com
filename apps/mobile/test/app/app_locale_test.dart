import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/app.dart';
import 'package:raro_mobile/core/l10n/app_locale.dart';
import 'package:raro_mobile/core/analytics/firebase_analytics_provider.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

class _FakeSettingsStore implements SettingsStore {
  _FakeSettingsStore(this._stored);

  RecordingSettings _stored;

  @override
  Future<RecordingSettings> load() async => _stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    _stored = settings;
  }
}

void main() {
  group('localeForLanguage', () {
    test('null (nunca escolheu) devolve null para o sistema resolver', () {
      expect(localeForLanguage(null), isNull);
    });

    test('ptBr mapeia para Locale pt_BR', () {
      expect(localeForLanguage(AppLanguage.ptBr), const Locale('pt', 'BR'));
    });

    test('en e es mapeiam sem country code', () {
      expect(localeForLanguage(AppLanguage.en), const Locale('en'));
      expect(localeForLanguage(AppLanguage.es), const Locale('es'));
    });
  });

  group('languageForLocale', () {
    test('casa por languageCode ignorando country', () {
      expect(languageForLocale(const Locale('es', 'MX')), AppLanguage.es);
      expect(languageForLocale(const Locale('pt')), AppLanguage.ptBr);
    });

    test('idioma não suportado cai em ptBr', () {
      expect(languageForLocale(const Locale('fr')), AppLanguage.ptBr);
    });
  });

  group('RaroApp locale reativo', () {
    Widget buildApp(RecordingSettings settings) {
      final analytics = _MockAnalytics();
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      return ProviderScope(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(analytics),
          settingsStoreProvider.overrideWithValue(_FakeSettingsStore(settings)),
        ],
        child: const RaroApp(),
      );
    }

    testWidgets('idioma persistido es força MaterialApp.locale es', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(const RecordingSettings(language: AppLanguage.es)),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('es'));
      expect(app.supportedLocales, isNotEmpty);
      expect(app.localizationsDelegates, isNotNull);
    });

    testWidgets('sem escolha persistida locale fica null (segue sistema)', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(const RecordingSettings()));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, isNull);
    });
  });
}
