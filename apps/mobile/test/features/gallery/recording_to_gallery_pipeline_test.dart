import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/application/persist_recording.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:raro_mobile/features/gallery/presentation/widgets/video_thumbnail.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_billing_gateway.dart';
import '../../helpers/fake_system_gallery_exporter.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  late Directory tempRoot;
  late File recorded;
  late StreamController<RecordingResult> events;
  late VaultService vault;
  late _MockCameraRepository thumbnails;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('gallery_pipeline_');
    recorded = File('${tempRoot.path}/raro_sess-m54.mp4')
      ..writeAsBytesSync(List.filled(1024, 7));
    events = StreamController<RecordingResult>.broadcast();
    vault = VaultService(documentsDir: tempRoot);
    thumbnails = _MockCameraRepository();
    when(
      () => thumbnails.generateThumbnail(any()),
    ).thenAnswer((_) async => '${tempRoot.path}/vault/sess-m54.jpg');
  });

  tearDown(() async {
    await events.close();
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        recordingEventsProvider.overrideWithValue(events.stream),
        vaultServiceProvider.overrideWith((ref) async => vault),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  PersistRecording persistUnconfigured() {
    return PersistRecording(
      billing: UnconfiguredBillingGateway(),
      vault: vault,
      gallery: FakeSystemGalleryExporter(),
      thumbnails: thumbnails,
      logger: Logger(level: Level.off),
    );
  }

  test(
    'STOP bem-sucedido vira pending: vault e lista da galeria ficam vazios',
    () async {
      final container = makeContainer();
      container.read(recordingVaultSinkProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      events.add(
        RecordingResult.finished(path: recorded.path, durationMs: 4200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(pendingRecordingProvider)?.id, 'sess-m54');
      expect(recorded.existsSync(), isTrue);
      expect(await vault.listAll(), isEmpty);
      expect(await container.read(videoListProvider.future), isEmpty);
    },
  );

  test(
    'Save com billing não configurado não entra no vault nem na galeria',
    () async {
      final container = makeContainer();
      container.read(recordingVaultSinkProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      events.add(
        RecordingResult.finished(path: recorded.path, durationMs: 4200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final pending = container.read(pendingRecordingProvider);
      expect(pending, isNotNull);
      final outcome = await persistUnconfigured()(pending!);

      expect(outcome, isA<PersistFailed>());
      expect(recorded.existsSync(), isTrue);
      expect(container.read(pendingRecordingProvider)?.id, 'sess-m54');
      expect(await vault.listAll(), isEmpty);
      expect(await container.read(videoListProvider.future), isEmpty);
      verifyNever(() => thumbnails.generateThumbnail(any()));
    },
  );

  test(
    'voltar do Preview descarta o pending e a galeria continua vazia',
    () async {
      final container = makeContainer();
      container.read(recordingVaultSinkProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      events.add(
        RecordingResult.finished(path: recorded.path, durationMs: 4200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(pendingRecordingProvider.notifier).discard();

      expect(container.read(pendingRecordingProvider), isNull);
      expect(recorded.existsSync(), isFalse);
      expect(await vault.listAll(), isEmpty);
      expect(await container.read(videoListProvider.future), isEmpty);
    },
  );

  test(
    'sessionFailed (CameraX ERROR_NO_VALID_DATA) não cria pending nem vault',
    () async {
      final container = makeContainer();
      container.read(recordingVaultSinkProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      events.add(
        const RecordingResult.failed(
          code: CameraErrorCode.sessionFailed,
          message: 'recording failed error=8',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(pendingRecordingProvider), isNull);
      expect(await vault.listAll(), isEmpty);
      expect(await container.read(videoListProvider.future), isEmpty);
    },
  );

  testWidgets('galeria com vault vazio mostra nenhum vídeo e zero thumbnails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [videoListProvider.overrideWith((ref) async => const [])],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: GalleryScreen(onBack: () {}, onOpenVideo: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('nenhum vídeo'), findsOneWidget);
    expect(find.byType(VideoThumbnail), findsNothing);
  });
}
