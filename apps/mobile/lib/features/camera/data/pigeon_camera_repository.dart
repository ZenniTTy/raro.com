import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';

class PigeonCameraRepository implements CameraRepository {
  PigeonCameraRepository(this._api);

  final CameraHostApi _api;

  @override
  Future<CameraCapabilities> discoverCapabilities() =>
      _api.discoverCapabilities();

  @override
  Future<void> startSession(int textureId, CameraConfig config) =>
      _api.startSession(textureId, config);

  @override
  Future<void> stopSession() => _api.stopSession();

  @override
  Future<void> switchLens(LensType lens) => _api.switchLens(lens);

  @override
  Future<void> setFormat(Resolution resolution, Fps fps) =>
      _api.setFormat(resolution, fps);

  @override
  Future<void> focusAt(FocusPoint point) => _api.focusAt(point);

  @override
  Future<String> startRecording(RecordingOptions options) =>
      _api.startRecording(options);

  @override
  Future<void> stopRecording() => _api.stopRecording();

  @override
  Future<bool> requestPermission() => _api.requestPermission();

  @override
  Future<bool> hasPermission() => _api.hasPermission();
}
