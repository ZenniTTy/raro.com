import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

class CameraSettings {
  const CameraSettings({
    required this.lens,
    required this.resolution,
    required this.fps,
  });

  final LensType lens;
  final Resolution resolution;
  final Fps fps;

  CameraConfig toConfig() =>
      CameraConfig(lens: lens, resolution: resolution, fps: fps);

  CameraSettings copyWith({LensType? lens, Resolution? resolution, Fps? fps}) =>
      CameraSettings(
        lens: lens ?? this.lens,
        resolution: resolution ?? this.resolution,
        fps: fps ?? this.fps,
      );
}
