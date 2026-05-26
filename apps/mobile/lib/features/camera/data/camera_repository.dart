import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

abstract class CameraRepository {
  Future<CameraCapabilities> discoverCapabilities();
  Future<void> startSession(int textureId, CameraConfig config);
  Future<void> stopSession();
  Future<void> switchLens(LensType lens);
  Future<void> setFormat(Resolution resolution, Fps fps);
  Future<void> focusAt(FocusPoint point);
  Future<bool> requestPermission();
  Future<bool> hasPermission();
}
