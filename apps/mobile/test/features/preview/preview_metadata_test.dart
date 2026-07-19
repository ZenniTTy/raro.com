import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/preview/domain/preview_metadata.dart';

VideoEntity _video({
  Duration duration = const Duration(minutes: 2, seconds: 30),
  bool isReplay = false,
}) {
  return VideoEntity(
    id: '1',
    name: 'Clipe',
    duration: duration,
    recordedAt: DateTime(2026, 5, 15, 9, 41),
    isReplay: isReplay,
    thumbnailHue: 20,
  );
}

void main() {
  group('PreviewMetadata', () {
    test('codec é H.265 (mock conforme protótipo)', () {
      final meta = PreviewMetadata.fromVideo(_video());
      expect(meta.codecLabel, 'H.265');
    });

    test('durationLabel usa o formato mm:ss do vídeo', () {
      final meta = PreviewMetadata.fromVideo(
        _video(duration: const Duration(minutes: 2, seconds: 30)),
      );
      expect(meta.durationLabel, '02:30');
    });

    test('sizeLabel é determinístico e proporcional à duração', () {
      final short = PreviewMetadata.fromVideo(
        _video(duration: const Duration(seconds: 30)),
      );
      final long = PreviewMetadata.fromVideo(
        _video(duration: const Duration(minutes: 5)),
      );
      expect(long.sizeBytes, greaterThan(short.sizeBytes));
    });

    test('mesma duração → mesmo sizeLabel (sem aleatoriedade)', () {
      final a = PreviewMetadata.fromVideo(
        _video(duration: const Duration(minutes: 2, seconds: 30)),
      );
      final b = PreviewMetadata.fromVideo(
        _video(duration: const Duration(minutes: 2, seconds: 30)),
      );
      expect(a.sizeLabel, b.sizeLabel);
    });

    test('sizeLabel formata em MB com unidade', () {
      final meta = PreviewMetadata.fromVideo(
        _video(duration: const Duration(minutes: 2, seconds: 30)),
      );
      expect(meta.sizeLabel, endsWith(' MB'));
      expect(meta.sizeLabel, matches(RegExp(r'^\d+ MB$')));
    });

    test('titleLabel formata timestamp "DD/MM HH:MM" a partir de recordedAt '
        '(a palavra Vídeo vem do arb na presentation)', () {
      final meta = PreviewMetadata.fromVideo(_video());
      expect(meta.titleLabel, '15/05 09:41');
    });
  });
}
