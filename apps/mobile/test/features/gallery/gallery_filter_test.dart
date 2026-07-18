import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/gallery/domain/gallery_filter.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

void main() {
  final now = DateTime(2026, 6, 2, 15);

  VideoEntity video({
    required String id,
    required DateTime at,
    bool replay = false,
  }) {
    return VideoEntity(
      id: id,
      name: 'v$id',
      duration: const Duration(seconds: 30),
      recordedAt: at,
      isReplay: replay,
      thumbnailHue: 0,
    );
  }

  late List<VideoEntity> all;

  setUp(() {
    // now = ter 2026-06-02; segunda da semana = 2026-06-01.
    all = [
      video(id: 'today', at: DateTime(2026, 6, 2, 9)),
      video(id: 'monday', at: DateTime(2026, 6, 1, 9)),
      video(id: 'lastweek', at: DateTime(2026, 5, 28, 9)),
      video(id: 'old', at: DateTime(2026, 4, 1, 9)),
      video(id: 'replay', at: DateTime(2026, 6, 2, 8), replay: true),
    ];
  });

  group('GalleryFilter.apply', () {
    test('all devolve a lista inteira', () {
      final result = GalleryFilter.all.apply(all, now: now);
      expect(result.length, all.length);
    });

    test('today devolve apenas vídeos do mesmo dia', () {
      final ids = GalleryFilter.today
          .apply(all, now: now)
          .map((v) => v.id)
          .toSet();
      expect(ids, {'today', 'replay'});
    });

    test('thisWeek inclui hoje e dias anteriores na semana corrente', () {
      final ids = GalleryFilter.thisWeek
          .apply(all, now: now)
          .map((v) => v.id)
          .toSet();
      expect(ids, contains('today'));
      expect(ids, contains('monday'));
      expect(ids, isNot(contains('lastweek')));
      expect(ids, isNot(contains('old')));
    });

    test('raroReplay devolve apenas vídeos isReplay', () {
      final ids = GalleryFilter.raroReplay
          .apply(all, now: now)
          .map((v) => v.id)
          .toSet();
      expect(ids, {'replay'});
    });

    test('enum cobre exatamente os 4 filtros do protótipo', () {
      expect(GalleryFilter.values, [
        GalleryFilter.all,
        GalleryFilter.today,
        GalleryFilter.thisWeek,
        GalleryFilter.raroReplay,
      ]);
    });
  });
}
