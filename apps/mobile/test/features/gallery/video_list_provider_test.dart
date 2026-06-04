import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/gallery_filter.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('video_list_test_');
  });

  tearDown(() async {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        vaultServiceProvider.overrideWith(
          (ref) async => VaultService(documentsDir: tempRoot),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> seedVideo({required String id, required bool isReplay}) async {
    final source = File('${tempRoot.path}/src_$id.mov')
      ..writeAsBytesSync([0, 1, 2, 3]);
    final vault = VaultService(documentsDir: tempRoot);
    await vault.save(
      source,
      metadata: RecordingMetadata(
        id: id,
        name: 'Vídeo $id',
        duration: const Duration(seconds: 10),
        recordedAt: DateTime(2026, 6, 4, 10, id.hashCode % 60),
        isReplay: isReplay,
        thumbnailHue: 100,
      ),
    );
  }

  group('videoListProvider', () {
    test('vault vazio retorna lista vazia (sem mocks após ADR-0019)', () async {
      final container = makeContainer();

      final videos = await container.read(videoListProvider.future);

      expect(videos, isEmpty);
    });

    test('lista os vídeos reais salvos no vault', () async {
      await seedVideo(id: 'aaa', isReplay: false);
      await seedVideo(id: 'bbb', isReplay: true);
      final container = makeContainer();

      final videos = await container.read(videoListProvider.future);

      expect(videos.length, 2);
      expect(videos.map((v) => v.id).toSet(), {'aaa', 'bbb'});
    });

    test('reflete a flag de replay do vídeo salvo', () async {
      await seedVideo(id: 'rep', isReplay: true);
      final container = makeContainer();

      final videos = await container.read(videoListProvider.future);

      expect(videos.single.isReplay, isTrue);
    });
  });

  group('galleryFilterControllerProvider', () {
    test('filtro inicial é GalleryFilter.all', () {
      final container = makeContainer();

      expect(
        container.read(galleryFilterControllerProvider),
        GalleryFilter.all,
      );
    });

    test('select muda o filtro corrente', () {
      final container = makeContainer();

      container
          .read(galleryFilterControllerProvider.notifier)
          .select(GalleryFilter.raroReplay);

      expect(
        container.read(galleryFilterControllerProvider),
        GalleryFilter.raroReplay,
      );
    });
  });
}
