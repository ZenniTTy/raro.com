import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_shared/raro_shared.dart' as shared;

String resolutionLabel(Resolution resolution) {
  switch (resolution) {
    case Resolution.hd720:
      return '720p';
    case Resolution.fhd1080:
      return '1080p';
    case Resolution.uhd4k:
      return '4K';
  }
}

String fpsLabel(Fps fps) {
  switch (fps) {
    case Fps.fps30:
      return '30FPS';
    case Fps.fps60:
      return '60FPS';
  }
}

bool _isPhysical4k60(FormatCapability format) =>
    format.resolution == Resolution.uhd4k &&
    format.fps == Fps.fps60 &&
    format.requiresPhysicalLens;

shared.Resolution _sharedResolution(FormatCapability format) {
  if (_isPhysical4k60(format)) {
    return shared.Resolution.uhd4k60;
  }
  switch (format.resolution) {
    case Resolution.hd720:
      return shared.Resolution.hd720;
    case Resolution.fhd1080:
      return shared.Resolution.fullHd1080;
    case Resolution.uhd4k:
      return shared.Resolution.uhd4k;
  }
}

List<shared.Resolution> availableSharedResolutions(
  List<FormatCapability> formats,
) {
  final seen = <shared.Resolution>{};
  final ordered = <shared.Resolution>[];
  for (final format in formats) {
    final resolution = _sharedResolution(format);
    if (seen.add(resolution)) {
      ordered.add(resolution);
    }
  }
  return ordered;
}
