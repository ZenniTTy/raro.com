import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/gallery_filter.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
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
