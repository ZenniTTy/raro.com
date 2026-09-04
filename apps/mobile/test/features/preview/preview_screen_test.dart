import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/domain/paywall_intent.dart';
import 'package:raro_mobile/features/preview/presentation/preview_screen.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_billing_gateway.dart';

List<VideoEntity> _fakeVideos() => [
  VideoEntity(
    id: 'abc',
    name: 'Clipe',
    duration: const Duration(minutes: 2, seconds: 30),
    recordedAt: DateTime(2026, 5, 15, 9, 41),
    isReplay: false,
    thumbnailHue: 20,
  ),
];

PendingClip _pendingClip({String path = '/tmp/pend1.mp4'}) {
  return PendingClip(
    path: path,
    metadata: RecordingMetadata(
      id: 'pend1',
      name: 'Vídeo 09:41',
      duration: const Duration(seconds: 5),
      recordedAt: DateTime(2026, 5, 15, 9, 41),
      isReplay: false,
      thumbnailHue: 20,
    ),
  );
}

void main() {
  bool backTapped = false;

  Widget app(String id) {
    backTapped = false;
    return ProviderScope(
      overrides: [videoListProvider.overrideWith((ref) async => _fakeVideos())],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: PreviewScreen(videoId: id, onBack: () => backTapped = true),
      ),
    );
  }

  Future<void> pumpReady(WidgetTester tester, String id) async {
    await tester.pumpWidget(app(id));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mostra título "Vídeo · 15/05 09:41" no header', (tester) async {
    await pumpReady(tester, 'abc');
    expect(find.text('Vídeo · 15/05 09:41'), findsOneWidget);
  });

  testWidgets('mostra card de metadata (tamanho, duração, codec)', (
    tester,
  ) async {
    await pumpReady(tester, 'abc');
    expect(find.text('INFO'), findsOneWidget);
    expect(find.text('256 MB'), findsOneWidget);
    expect(find.text('H.265'), findsOneWidget);
    expect(find.text('TAMANHO'), findsOneWidget);
    expect(find.text('DURAÇÃO'), findsOneWidget);
    expect(find.text('CODEC'), findsOneWidget);
  });

  testWidgets('mostra botão play central no viewport', (tester) async {
    await pumpReady(tester, 'abc');
    expect(find.byKey(const Key('preview_play_button')), findsOneWidget);
  });

  testWidgets('mostra ação Compartilhar', (tester) async {
    await pumpReady(tester, 'abc');
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  testWidgets('tap no back dispara onBack', (tester) async {
    await pumpReady(tester, 'abc');
    await tester.tap(find.byKey(const Key('preview_back_button')));
    await tester.pump();
    expect(backTapped, isTrue);
  });

  testWidgets('id inexistente não derruba a tela (estado vazio gracioso)', (
    tester,
  ) async {
    await pumpReady(tester, 'inexistente');
    expect(tester.takeException(), isNull);
  });

  testWidgets('P08 arquivado não mostra Salvar', (tester) async {
    await pumpReady(tester, 'abc');
    expect(find.byKey(const Key('preview_save_button')), findsNothing);
    expect(find.text('Salvar'), findsNothing);
  });

  testWidgets('clipe pendente mostra CTA Salvar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoListProvider.overrideWith((ref) async => const <VideoEntity>[]),
          pendingRecordingProvider.overrideWithValue(_pendingClip()),
          billingGatewayProvider.overrideWithValue(FakeBillingGateway()),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PreviewScreen(videoId: 'pend1', onBack: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('preview_save_button')), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('Salvar sem premium pede paywall de guardar', (tester) async {
    PaywallIntent? intent;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoListProvider.overrideWith((ref) async => const <VideoEntity>[]),
          pendingRecordingProvider.overrideWithValue(_pendingClip()),
          billingGatewayProvider.overrideWithValue(FakeBillingGateway()),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PreviewScreen(
            videoId: 'pend1',
            onBack: () {},
            onNeedPremium: (value) => intent = value,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('preview_save_button')));
    await tester.pump();
    await tester.pump();
    expect(intent, PaywallIntent.save);
  });

  testWidgets('Salvar com billing indisponível não abre paywall', (
    tester,
  ) async {
    PaywallIntent? intent;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoListProvider.overrideWith((ref) async => const <VideoEntity>[]),
          pendingRecordingProvider.overrideWithValue(_pendingClip()),
          billingGatewayProvider.overrideWithValue(
            UnconfiguredBillingGateway(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PreviewScreen(
            videoId: 'pend1',
            onBack: () {},
            onNeedPremium: (value) => intent = value,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('preview_save_button')));
    await tester.pump();
    await tester.pump();
    expect(intent, isNull);
    expect(
      find.text('Não foi possível verificar sua assinatura. Tente de novo.'),
      findsOneWidget,
    );
  });

  testWidgets('Share com billing indisponível não abre paywall', (
    tester,
  ) async {
    PaywallIntent? intent;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoListProvider.overrideWith((ref) async => _fakeVideos()),
          billingGatewayProvider.overrideWithValue(
            UnconfiguredBillingGateway(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PreviewScreen(
            videoId: 'abc',
            onBack: () {},
            onNeedPremium: (value) => intent = value,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('preview_share_button')));
    await tester.pump();
    await tester.pump();
    expect(intent, isNull);
    expect(
      find.text('Não foi possível verificar sua assinatura. Tente de novo.'),
      findsOneWidget,
    );
  });
}
