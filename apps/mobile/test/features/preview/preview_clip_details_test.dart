import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/preview/domain/preview_clip_details.dart';

VideoEntity _video({
  String name = 'Clipe',
  Duration duration = const Duration(minutes: 2, seconds: 30),
  DateTime? recordedAt,
  bool isReplay = false,
  String? resolutionLabel,
  String? fpsLabel,
  String? lensLabel,
}) {
  return VideoEntity(
    id: '1',
    name: name,
    duration: duration,
    recordedAt: recordedAt ?? DateTime(2026, 5, 15, 9, 41),
    isReplay: isReplay,
    thumbnailHue: 20,
    resolutionLabel: resolutionLabel,
    fpsLabel: fpsLabel,
    lensLabel: lensLabel,
  );
}

void main() {
  group('PreviewClipDetails', () {
    test('lê só o que o sidecar/entity já tem', () {
      final details = PreviewClipDetails.fromVideo(
        _video(
          resolutionLabel: '4K',
          fpsLabel: '30FPS',
          lensLabel: '0.5×',
          isReplay: true,
        ),
        sizeBytes: 2048,
      );
      expect(details.name, 'Clipe');
      expect(details.durationLabel, '02:30');
      expect(details.recordedAtLabel, '15/05/2026 09:41');
      expect(details.resolutionLabel, '4K');
      expect(details.fpsLabel, '30FPS');
      expect(details.lensLabel, '0.5×');
      expect(details.sizeLabel, '2 KB');
      expect(details.isReplay, isTrue);
    });

    test('campo ausente no sidecar fica null — UI mostra placeholder', () {
      final details = PreviewClipDetails.fromVideo(_video());
      expect(details.resolutionLabel, isNull);
      expect(details.fpsLabel, isNull);
      expect(details.lensLabel, isNull);
      expect(details.sizeLabel, isNull);
      expect(details.isReplay, isFalse);
    });
  });

  group('formatFileSize', () {
    test('bytes abaixo de 1 KB ficam em B', () {
      expect(formatFileSize(500), '500 B');
    });

    test('1–1023 KB arredonda para KB', () {
      expect(formatFileSize(2048), '2 KB');
    });

    test('abaixo de 10 MB usa uma casa decimal', () {
      expect(formatFileSize(2 * 1024 * 1024), '2.0 MB');
    });

    test('10 MB ou mais arredonda em MB inteiro', () {
      expect(formatFileSize(256 * 1024 * 1024), '256 MB');
    });
  });
}
