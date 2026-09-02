import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/domain/capture_format_labels.dart';
import 'package:raro_shared/raro_shared.dart';

void main() {
  test('captureResolutionLabel mapeia 4K60 para 4K', () {
    expect(captureResolutionLabel(Resolution.hd720), '720p');
    expect(captureResolutionLabel(Resolution.fullHd1080), '1080p');
    expect(captureResolutionLabel(Resolution.uhd4k), '4K');
    expect(captureResolutionLabel(Resolution.uhd4k60), '4K');
  });

  test('captureFpsLabel', () {
    expect(captureFpsLabel(Fps.fps30), '30FPS');
    expect(captureFpsLabel(Fps.fps60), '60FPS');
  });
}
