import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:raro_mobile/features/gallery/presentation/widgets/video_thumbnail.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

List<VideoEntity> _fakeVideos(DateTime now) => [
  VideoEntity(
    id: '1',
    name: 'Hoje normal',
    duration: const Duration(minutes: 1, seconds: 5),
    recordedAt: now.subtract(const Duration(hours: 1)),
    isReplay: false,
    thumbnailHue: 10,
  ),
  VideoEntity(
    id: '2',
    name: 'Replay hoje',
    duration: const Duration(seconds: 30),
    recordedAt: now.subtract(const Duration(hours: 2)),
    isReplay: true,
    thumbnailHue: 200,
  ),
  VideoEntity(
    id: '3',
    name: 'Antigo',
    duration: const Duration(minutes: 4),
    recordedAt: now.subtract(const Duration(days: 40)),
    isReplay: false,
    thumbnailHue: 300,
  ),
];

void main() {
  String? openedPreviewId;

  Widget app() {
    openedPreviewId = null;
    final now = DateTime.now();
    return ProviderScope(
      overrides: [
        videoListProvider.overrideWith((ref) async => _fakeVideos(now)),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: GalleryScreen(
          onBack: () {},
          onOpenVideo: (id) => openedPreviewId = id,
        ),
      ),
    );
  }

  Future<void> pumpReady(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mostra título Galeria, contagem e filtros fiéis ao protótipo', (
    tester,
  ) async {
    await pumpReady(tester);

    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('3 vídeos'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Esta semana'), findsOneWidget);
    expect(find.text('Raro Replay'), findsOneWidget);
  });

  testWidgets('renderiza um thumbnail por vídeo (grid 3-col)', (tester) async {
    await pumpReady(tester);

    expect(find.byType(VideoThumbnail), findsNWidgets(3));
  });

  testWidgets('filtro Raro Replay reduz a grade aos replays', (tester) async {
    await pumpReady(tester);

    await tester.tap(find.text('Raro Replay'));
    await tester.pump();

    expect(find.byType(VideoThumbnail), findsOneWidget);
  });

  testWidgets('tap em thumbnail abre o preview do vídeo', (tester) async {
    await pumpReady(tester);

    await tester.tap(find.byType(VideoThumbnail).first);
    await tester.pump();

    expect(openedPreviewId, isNotNull);
  });
}
