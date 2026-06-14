import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/features/settings/presentation/settings_screen.dart';
import 'package:raro_shared/raro_shared.dart';

class _FakeSettingsStore implements SettingsStore {
  RecordingSettings stored = const RecordingSettings();

  @override
  Future<RecordingSettings> load() async => stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    stored = settings;
  }
}

class _FakeSubscriptionStore implements SubscriptionStore {
  _FakeSubscriptionStore(this._stored);
  final SubscriptionState _stored;

  @override
  Future<SubscriptionState> load() async => _stored;

  @override
  Future<void> save(SubscriptionState state) async {}
}

void main() {
  late _FakeSettingsStore store;

  setUp(() {
    store = _FakeSettingsStore();
  });

  Widget app({SubscriptionState? subscription}) {
    return ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        if (subscription != null)
          subscriptionStoreProvider.overrideWithValue(
            _FakeSubscriptionStore(subscription),
          ),
      ],
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: SettingsScreen(onBack: () {}, onSeePlans: () {}),
      ),
    );
  }

  Future<void> pumpReady(
    WidgetTester tester, {
    SubscriptionState? subscription,
  }) async {
    await tester.pumpWidget(app(subscription: subscription));
    await tester.pump();
    await tester.pump();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  testWidgets('mostra título Configurações e seções fiéis ao protótipo', (
    tester,
  ) async {
    await pumpReady(tester);

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Qualidade de Gravação'), findsOneWidget);
    expect(find.text('SEMPRE ATIVADA'), findsOneWidget);

    await scrollTo(tester, find.text('Controle de Gravação'));
    expect(find.text('Controle de Gravação'), findsOneWidget);

    await scrollTo(tester, find.text('Idioma'));
    expect(find.text('Idioma'), findsOneWidget);

    await scrollTo(tester, find.text('Sobre'));
    expect(find.text('Sobre'), findsOneWidget);
  });

  testWidgets('estabilização é status fixo (não há toggle editável)', (
    tester,
  ) async {
    await pumpReady(tester);

    expect(find.text('Estabilização nativa'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('tap em 720p persiste a resolução via controller', (
    tester,
  ) async {
    await pumpReady(tester);

    await tester.tap(find.text('720p HD'));
    await tester.pump();

    expect(store.stored.resolution, Resolution.hd720);
  });

  testWidgets('card Volume desabilitado não altera o modo de controle', (
    tester,
  ) async {
    await pumpReady(tester);

    await scrollTo(tester, find.text('Volume'));
    await tester.tap(find.text('Volume'));
    await tester.pump();

    expect(store.stored.controlMode, isNot(ControlMode.volume));
  });

  testWidgets('Ver Planos dispara o callback onSeePlans', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: buildRaroDarkTheme(),
          home: SettingsScreen(onBack: () {}, onSeePlans: () => tapped = true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Ver Planos'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Ver Planos'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('mostra trial countdown quando há trial ativo', (tester) async {
    await pumpReady(
      tester,
      subscription: SubscriptionState(
        isSubscribed: true,
        trialStartedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    );

    await scrollTo(tester, find.textContaining('dias restantes'));
    expect(find.textContaining('25 dias restantes'), findsOneWidget);
  });

  testWidgets('NÃO mostra trial countdown quando não-assinado', (tester) async {
    await pumpReady(tester, subscription: const SubscriptionState.initial());

    expect(find.textContaining('dias restantes'), findsNothing);
  });
}
