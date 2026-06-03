import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

void main() {
  group('VideoEntity', () {
    test('formattedDuration formata Duration como mm:ss', () {
      final a = VideoEntity(
        id: '1',
        name: 'Pôr do sol',
        duration: const Duration(minutes: 2, seconds: 14),
        recordedAt: _fixedDate,
        isReplay: false,
        thumbnailHue: 20,
      );
      final b = VideoEntity(
        id: '2',
        name: 'Flash',
        duration: const Duration(seconds: 9),
        recordedAt: _fixedDate,
        isReplay: true,
        thumbnailHue: 200,
      );

      expect(a.formattedDuration, '02:14');
      expect(b.formattedDuration, '00:09');
    });

    test('value equality por id', () {
      final a = VideoEntity(
        id: '1',
        name: 'A',
        duration: const Duration(seconds: 1),
        recordedAt: _fixedDate,
        isReplay: false,
        thumbnailHue: 0,
      );
      final b = VideoEntity(
        id: '1',
        name: 'A',
        duration: const Duration(seconds: 1),
        recordedAt: _fixedDate,
        isReplay: false,
        thumbnailHue: 0,
      );

      expect(a, b);
    });

    test('VideoEntity filePath defaults to null and round-trips', () {
      final v = VideoEntity(
        id: '1',
        name: 'x',
        duration: Duration.zero,
        recordedAt: DateTime(2026),
        isReplay: false,
        thumbnailHue: 0,
      );
      expect(v.filePath, isNull);
      expect(v.copyWith(filePath: '/vault/1.mov').filePath, '/vault/1.mov');
    });
  });
}

final _fixedDate = DateTime.utc(2026, 6, 1, 12);
