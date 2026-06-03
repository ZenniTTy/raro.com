import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart'
    as pigeon;
import 'package:raro_shared/raro_shared.dart' as shared;

class PigeonFormat {
  const PigeonFormat({required this.resolution, required this.fps});

  final pigeon.Resolution resolution;
  final pigeon.Fps fps;
}

PigeonFormat mapToPigeonFormat({
  required shared.Resolution resolution,
  required shared.Fps fps,
}) {
  switch (resolution) {
    case shared.Resolution.hd720:
      return PigeonFormat(resolution: pigeon.Resolution.hd720, fps: _fps(fps));
    case shared.Resolution.fullHd1080:
      return PigeonFormat(
        resolution: pigeon.Resolution.fhd1080,
        fps: _fps(fps),
      );
    case shared.Resolution.uhd4k:
      return PigeonFormat(resolution: pigeon.Resolution.uhd4k, fps: _fps(fps));
    case shared.Resolution.uhd4k60:
      return const PigeonFormat(
        resolution: pigeon.Resolution.uhd4k,
        fps: pigeon.Fps.fps60,
      );
  }
}

pigeon.Fps _fps(shared.Fps fps) =>
    fps == shared.Fps.fps60 ? pigeon.Fps.fps60 : pigeon.Fps.fps30;
