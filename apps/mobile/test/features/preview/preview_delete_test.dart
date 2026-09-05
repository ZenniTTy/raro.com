import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/preview/domain/preview_clip_details.dart';
import 'package:raro_mobile/features/preview/presentation/preview_screen.dart';
import 'package:raro_mobile/features/preview/presentation/widgets/preview_details_sheet.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class _FailingDeleteVault extends VaultService {
  _FailingDeleteVault({required super.documentsDir});

  @override
  Future<void> delete(String id) {
    throw const FileSystemException('failed');
  }
}

class _TrackingVault extends VaultService {
  _TrackingVault({required super.documentsDir, required this.onDeleted});

  final void Function(String id) onDeleted;
  final List<String> deletedIds = [];

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    onDeleted(id);
  }
}

VideoEntity _clip({bool replay = false}) {
  return VideoEntity(
    id: 'clip1',
    name: 'Clipe de teste',
    duration: const Duration(minutes: 2, seconds: 30),
    recordedAt: DateTime(2026, 5, 15, 9, 41),
    isReplay: replay,
    thumbnailHue: 20,
    resolutionLabel: '4K',
    fpsLabel: '30FPS',
    lensLabel: '0.5×',
  );
}

void main() {
  late Directory tempRoot;
  late bool backTapped;
  late List<VideoEntity> listed;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('preview_delete_');
    backTapped = false;
    listed = [_clip()];
  });

  tearDown(() async {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  Future<void> seedVault({String id = 'clip1', bool replay = false}) async {
    final source = File('${tempRoot.path}/src.mp4')
      ..writeAsBytesSync(List.filled(2048, 7));
    final vault = VaultService(documentsDir: tempRoot);
    await vault.save(
      source,
      metadata: RecordingMetadata(
        id: id,
        name: 'Clipe de teste',
        duration: const Duration(minutes: 2, seconds: 30),
        recordedAt: DateTime(2026, 5, 15, 9, 41),
        isReplay: replay,
        thumbnailHue: 20,
        resolutionLabel: '4K',
        fpsLabel: '30FPS',
        lensLabel: '0.5×',
      ),
    );
    File('${tempRoot.path}/vault/$id.jpg').writeAsBytesSync([1, 2, 3]);
  }

  List<File> vaultFiles(String id) => [
    File('${tempRoot.path}/vault/$id.mp4'),
    File('${tempRoot.path}/vault/$id.json'),
    File('${tempRoot.path}/vault/$id.jpg'),
  ];

  Widget app({required VaultService vault}) {
    return ProviderScope(
      overrides: [
        vaultServiceProvider.overrideWithValue(AsyncData(vault)),
        videoListProvider.overrideWith((ref) async => listed),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: PreviewScreen(videoId: 'clip1', onBack: () => backTapped = true),
      ),
    );
  }

  Future<void> pumpReady(
    WidgetTester tester, {
    required VaultService vault,
  }) async {
    await tester.pumpWidget(app(vault: vault));
    await tester.pump();
    await tester.pump();
  }

  Future<void> confirmOrCancelDelete(
    WidgetTester tester, {
    required bool confirm,
  }) async {
    await tester.tap(find.byKey(const Key('preview_delete_button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.byKey(
        confirm
            ? const Key('preview_delete_confirm')
            : const Key('preview_delete_cancel'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'lixeira e info não são mais em breve',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [videoListProvider.overrideWith((ref) async => listed)],
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildRaroDarkTheme(),
            home: PreviewScreen(
              videoId: 'clip1',
              onBack: () => backTapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('preview_delete_button')), findsOneWidget);
      expect(find.byKey(const Key('preview_info_button')), findsOneWidget);
      expect(find.text('Em breve'), findsNothing);
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  testWidgets('cancelar a confirmação não apaga o clipe nem sai do preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [videoListProvider.overrideWith((ref) async => listed)],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PreviewScreen(
            videoId: 'clip1',
            onBack: () => backTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('preview_delete_button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('preview_delete_dialog')), findsOneWidget);
    expect(
      find.text(
        'O vídeo sai só do RARO. Uma cópia já salva no app de Fotos do celular permanece.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('preview_delete_cancel')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('preview_delete_dialog')), findsNothing);
    expect(backTapped, isFalse);
  });

  testWidgets('confirmar chama o vault, atualiza a lista e volta', (
    tester,
  ) async {
    final vault = _TrackingVault(
      documentsDir: tempRoot,
      onDeleted: (id) {
        listed = listed.where((video) => video.id != id).toList();
      },
    );
    await pumpReady(tester, vault: vault);
    final context = tester.element(find.byType(PreviewScreen));
    final container = ProviderScope.containerOf(context);

    await confirmOrCancelDelete(tester, confirm: true);

    expect(backTapped, isTrue);
    expect(vault.deletedIds, ['clip1']);
    expect(await container.read(videoListProvider.future), isEmpty);
  });

  testWidgets('erro de IO mostra snack e mantém o clipe na tela', (
    tester,
  ) async {
    await tester.runAsync(() => seedVault());
    final vault = _FailingDeleteVault(documentsDir: tempRoot);
    await pumpReady(tester, vault: vault);

    await confirmOrCancelDelete(tester, confirm: true);
    await tester.pump();

    expect(backTapped, isFalse);
    expect(
      find.text('Não foi possível apagar o vídeo. Tente de novo.'),
      findsOneWidget,
    );
    expect(find.byType(PreviewScreen), findsOneWidget);
    for (final file in vaultFiles('clip1')) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }
    expect((await vault.listAll()).single.id, 'clip1');
  });

  testWidgets('info abre o painel com os campos do sidecar', (tester) async {
    listed = [_clip(replay: true)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [videoListProvider.overrideWith((ref) async => listed)],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PreviewScreen(
            videoId: 'clip1',
            onBack: () => backTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('preview_info_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('preview_details_sheet')), findsOneWidget);
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Clipe de teste'), findsOneWidget);
    expect(find.text('02:30'), findsWidgets);
    expect(find.text('15/05/2026 09:41'), findsOneWidget);
    expect(find.text('4K'), findsWidgets);
    expect(find.text('30FPS'), findsWidgets);
    expect(find.text('0.5×'), findsWidgets);
    expect(find.text('Sim'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const Key('preview_details_sheet'))),
    ).pop();
    await tester.pump();
  });

  testWidgets('painel isolado mostra o tamanho real do arquivo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: Scaffold(
          body: PreviewDetailsSheet(
            details: PreviewClipDetails.fromVideo(
              VideoEntity(
                id: 'clip1',
                name: 'Clipe de teste',
                duration: const Duration(minutes: 2, seconds: 30),
                recordedAt: DateTime(2026, 5, 15, 9, 41),
                isReplay: false,
                thumbnailHue: 20,
              ),
              sizeBytes: 2048,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2 KB'), findsOneWidget);
    expect(find.text('Não'), findsOneWidget);
  });
}
