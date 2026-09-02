import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/preview/domain/preview_info_badge.dart';

void main() {
  group('previewResolutionFromSize', () {
    test('3840×2160 é 4K', () {
      expect(previewResolutionFromSize(3840, 2160), '4K');
      expect(previewResolutionFromSize(2160, 3840), '4K');
    });

    test('1920×1080 é 1080p', () {
      expect(previewResolutionFromSize(1920, 1080), '1080p');
    });

    test('1280×720 é 720p', () {
      expect(previewResolutionFromSize(1280, 720), '720p');
    });
  });

  group('previewInfoBadge', () {
    test('lente 0.5× vem do sidecar, não de isReplay', () {
      expect(
        previewInfoBadge(
          storedResolution: '4K',
          storedFps: '30FPS',
          storedLens: '0.5×',
        ),
        '4K · 30FPS · 0.5×',
      );
    });

    test(
      'sidecar ganha do tamanho do player (fallback silencioso de lente)',
      () {
        expect(
          previewInfoBadge(
            width: 1920,
            height: 1080,
            storedResolution: '4K',
            storedFps: '30FPS',
            storedLens: '0.5×',
          ),
          '4K · 30FPS · 0.5×',
        );
      },
    );

    test('cai no tamanho do player só quando o sidecar não tem formato', () {
      expect(previewInfoBadge(width: 3840, height: 2160), '4K · 1×');
    });

    test('omite fps quando o sidecar antigo não tem o campo', () {
      expect(
        previewInfoBadge(storedResolution: '4K', storedLens: '0.5×'),
        '4K · 0.5×',
      );
    });
  });
}
