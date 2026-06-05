import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  late Directory tempRoot;
  late File recorded;
  late StreamController<RecordingResult> events;
  late _MockCameraRepository repository;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vault_sink_test_');
    recorded = File('${tempRoot.path}/raro_sess1.mov')
      ..writeAsBytesSync(List.filled(1024, 9));
    events = StreamController<RecordingResult>.broadcast();
    repository = _MockCameraRepository();
  });

  tearDown(() async {
    await events.close();
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        recordingEventsProvider.overrideWithValue(events.stream),
        vaultServiceProvider.overrideWith(
          (ref) async => VaultService(documentsDir: tempRoot),
        ),
        cameraRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<List<VideoEntity>> emitAndWaitUntil(
    ProviderContainer container,
    bool Function(List<VideoEntity>) done,
  ) async {
    container.read(recordingVaultSinkProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    events.add(RecordingResult.finished(path: recorded.path, durationMs: 5000));
    final vault = VaultService(documentsDir: tempRoot);
    var videos = <VideoEntity>[];
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      videos = await vault.listAll();
      if (done(videos)) return videos;
    }
    return videos;
  }

  test('saves the video to vault on RecordingFinished', () async {
    when(
      () => repository.generateThumbnail(any()),
    ).thenAnswer((_) async => '${tempRoot.path}/vault/sess1.jpg');
    final container = makeContainer();

    final videos = await emitAndWaitUntil(container, (v) => v.isNotEmpty);

    expect(videos.single.id, 'sess1');
    expect(File(videos.single.filePath!).existsSync(), isTrue);
  });

  test('attaches thumbnail path when generation succeeds', () async {
    final thumbPath = '${tempRoot.path}/vault/sess1.jpg';
    when(() => repository.generateThumbnail(any())).thenAnswer((_) async {
      await Directory('${tempRoot.path}/vault').create(recursive: true);
      await File(thumbPath).writeAsBytes([0, 1, 2]);
      return thumbPath;
    });
    final container = makeContainer();

    final videos = await emitAndWaitUntil(
      container,
      (v) => v.isNotEmpty && v.single.thumbnailPath != null,
    );

    expect(videos.single.thumbnailPath, endsWith('vault/sess1.jpg'));
    verify(() => repository.generateThumbnail(any())).called(1);
  });

  test('video still lists when thumbnail generation throws', () async {
    when(
      () => repository.generateThumbnail(any()),
    ).thenThrow(Exception('android stub / not finalized'));
    final container = makeContainer();

    final videos = await emitAndWaitUntil(container, (v) => v.isNotEmpty);

    expect(videos.single.id, 'sess1');
    expect(videos.single.thumbnailPath, isNull);
  });

  test('RecordingFailed does not save anything', () async {
    final container = makeContainer();
    container.read(recordingVaultSinkProvider);

    events.add(
      const RecordingResult.failed(code: CameraErrorCode.sessionFailed),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await VaultService(documentsDir: tempRoot).listAll(), isEmpty);
  });
}
