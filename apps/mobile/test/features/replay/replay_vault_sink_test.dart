import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  late Directory tempRoot;
  late File savedReplay;
  late StreamController<ReplayResult> events;
  late _MockCameraRepository repository;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('replay_sink_test_');
    savedReplay = File('${tempRoot.path}/raro_replay_x.mp4')
      ..writeAsBytesSync(List.filled(1024, 7));
    events = StreamController<ReplayResult>.broadcast();
    repository = _MockCameraRepository();
  });

  tearDown(() async {
    await events.close();
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        replayEventsProvider.overrideWithValue(events.stream),
        vaultServiceProvider.overrideWith(
          (ref) async => VaultService(documentsDir: tempRoot),
        ),
        cameraRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('saves the replay video to vault with isReplay true', () async {
    when(
      () => repository.generateThumbnail(any()),
    ).thenAnswer((_) async => '${tempRoot.path}/vault/x.jpg');
    final container = makeContainer();
    container.read(replayVaultSinkProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    events.add(ReplayResult.saved(path: savedReplay.path, durationMs: 15000));

    final vault = VaultService(documentsDir: tempRoot);
    var videos = <VideoEntity>[];
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      videos = await vault.listAll();
      if (videos.isNotEmpty) break;
    }
    expect(videos.single.isReplay, isTrue);
    expect(File(videos.single.filePath!).existsSync(), isTrue);
  });
}
