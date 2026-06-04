import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart'
    as pigeon;
import 'package:raro_mobile/features/camera/domain/recording_options_mapper.dart';
import 'package:raro_shared/raro_shared.dart' as shared;

void main() {
  test('hd720 + fps30 maps 1:1', () {
    final r = mapToPigeonFormat(
      resolution: shared.Resolution.hd720,
      fps: shared.Fps.fps30,
    );
    expect(r.resolution, pigeon.Resolution.hd720);
    expect(r.fps, pigeon.Fps.fps30);
  });

  test('fullHd1080 maps to fhd1080', () {
    final r = mapToPigeonFormat(
      resolution: shared.Resolution.fullHd1080,
      fps: shared.Fps.fps60,
    );
    expect(r.resolution, pigeon.Resolution.fhd1080);
    expect(r.fps, pigeon.Fps.fps60);
  });

  test('uhd4k passes fps through', () {
    final r = mapToPigeonFormat(
      resolution: shared.Resolution.uhd4k,
      fps: shared.Fps.fps30,
    );
    expect(r.resolution, pigeon.Resolution.uhd4k);
    expect(r.fps, pigeon.Fps.fps30);
  });

  test('uhd4k60 decomposes to uhd4k + forced fps60 (ignores incoming fps)', () {
    final r = mapToPigeonFormat(
      resolution: shared.Resolution.uhd4k60,
      fps: shared.Fps.fps30,
    );
    expect(r.resolution, pigeon.Resolution.uhd4k);
    expect(r.fps, pigeon.Fps.fps60);
  });
}
