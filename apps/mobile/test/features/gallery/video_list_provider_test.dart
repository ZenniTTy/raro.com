import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
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

  group('videoListProvider', () {
    test('Sprint 1 retorna lista mock não-vazia', () async {
      final container = makeContainer();

      final videos = await container.read(videoListProvider.future);

      expect(videos, isNotEmpty);
      expect(videos.length, greaterThanOrEqualTo(5));
    });

    test('ids são únicos', () async {
      final container = makeContainer();

      final videos = await container.read(videoListProvider.future);

      final ids = videos.map((v) => v.id).toSet();
      expect(ids.length, videos.length);
    });

    test('contém ao menos um Raro Replay', () async {
      final container = makeContainer();

      final videos = await container.read(videoListProvider.future);

      expect(videos.any((v) => v.isReplay), isTrue);
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
