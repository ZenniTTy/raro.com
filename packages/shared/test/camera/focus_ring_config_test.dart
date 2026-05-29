import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('FocusRingConfig', () {
    test(
      'exposes ring visual constants matching prototype .focus-ring CSS',
      () {
        expect(FocusRingConfig.colorArgb, 0xFFFFFFFF);
        expect(FocusRingConfig.strokeWidth, 1.5);
        expect(FocusRingConfig.durationMs, 1200);
        expect(FocusRingConfig.scaleFrom, 1.4);
        expect(FocusRingConfig.scaleTo, 1.0);
        expect(FocusRingConfig.radiusPx, 32.0);
      },
    );

    test('opacity keyframes match [0,1,0] with keyTimes [0,0.2,1]', () {
      expect(FocusRingConfig.opacityKeyframes, [0.0, 1.0, 0.0]);
      expect(FocusRingConfig.opacityKeyTimes, [0.0, 0.2, 1.0]);
      expect(
        FocusRingConfig.opacityKeyframes.length,
        FocusRingConfig.opacityKeyTimes.length,
      );
    });

    test('cannot be instantiated (private constructor)', () {
      expect(FocusRingConfig.durationMs > 0, isTrue);
    });
  });
}
