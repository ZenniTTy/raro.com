import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/format_catalog.dart';
import 'package:raro_shared/raro_shared.dart' as shared;

FormatCapability cap(Resolution r, Fps f, {bool physical = false}) =>
    FormatCapability(resolution: r, fps: f, requiresPhysicalLens: physical);

void main() {
  group('resolutionLabel', () {
    test('mapeia cada Resolution do pigeon', () {
      expect(resolutionLabel(Resolution.hd720), '720p');
      expect(resolutionLabel(Resolution.fhd1080), '1080p');
      expect(resolutionLabel(Resolution.uhd4k), '4K');
    });
  });

  group('fpsLabel', () {
    test('mapeia cada Fps do pigeon', () {
      expect(fpsLabel(Fps.fps30), '30FPS');
      expect(fpsLabel(Fps.fps60), '60FPS');
    });
  });

  group('availableSharedResolutions', () {
    test('lista vazia retorna vazio', () {
      expect(availableSharedResolutions(const []), isEmpty);
    });

    test(
      'combos virtuais mapeiam para as Resolutions shared correspondentes',
      () {
        final formats = [
          cap(Resolution.hd720, Fps.fps30),
          cap(Resolution.fhd1080, Fps.fps30),
          cap(Resolution.fhd1080, Fps.fps60),
          cap(Resolution.uhd4k, Fps.fps30),
        ];
        expect(availableSharedResolutions(formats), [
          shared.Resolution.hd720,
          shared.Resolution.fullHd1080,
          shared.Resolution.uhd4k,
        ]);
      },
    );

    test('o combo 4K@60 físico vira shared.Resolution.uhd4k60 distinto', () {
      final formats = [
        cap(Resolution.fhd1080, Fps.fps60),
        cap(Resolution.uhd4k, Fps.fps30),
        cap(Resolution.uhd4k, Fps.fps60, physical: true),
      ];
      expect(availableSharedResolutions(formats), [
        shared.Resolution.fullHd1080,
        shared.Resolution.uhd4k,
        shared.Resolution.uhd4k60,
      ]);
    });

    test('4K@60 só no virtual (sem físico) NÃO vira uhd4k60', () {
      final formats = [cap(Resolution.uhd4k, Fps.fps60)];
      expect(
        availableSharedResolutions(formats),
        isNot(contains(shared.Resolution.uhd4k60)),
      );
      expect(availableSharedResolutions(formats), [shared.Resolution.uhd4k]);
    });

    test('não duplica Resolutions quando há 30 e 60 do mesmo res', () {
      final formats = [
        cap(Resolution.fhd1080, Fps.fps30),
        cap(Resolution.fhd1080, Fps.fps60),
      ];
      expect(availableSharedResolutions(formats), [
        shared.Resolution.fullHd1080,
      ]);
    });
  });
}
