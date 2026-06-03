import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/camera_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/CameraApi.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/camera/CameraApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated.camera',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
enum LensType { ultraWide, wide }

enum Resolution { hd720, fhd1080, uhd4k }

enum Fps { fps30, fps60 }

enum CameraErrorCode {
  permissionDenied,
  deviceUnavailable,
  lensUnavailable,
  formatUnsupported,
  sessionFailed,
  alreadyRunning,
  notRunning,
}

class CameraCapabilities {
  CameraCapabilities({
    required this.availableLenses,
    required this.supportedResolutions,
    required this.supportedFps,
  });

  final List<LensType> availableLenses;
  final List<Resolution> supportedResolutions;
  final List<Fps> supportedFps;
}

class CameraConfig {
  CameraConfig({
    required this.lens,
    required this.resolution,
    required this.fps,
  });

  final LensType lens;
  final Resolution resolution;
  final Fps fps;
}

class FocusPoint {
  FocusPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class RecordingOptions {
  RecordingOptions({
    required this.resolution,
    required this.fps,
    required this.codec,
  });

  Resolution resolution;
  Fps fps;
  String codec;
}

@HostApi()
abstract class CameraHostApi {
  @async
  CameraCapabilities discoverCapabilities();

  @async
  void startSession(int textureId, CameraConfig config);

  @async
  void stopSession();

  @async
  void switchLens(LensType lens);

  @async
  void setFormat(Resolution resolution, Fps fps);

  @async
  void focusAt(FocusPoint point);

  /// Starts recording on the running session. Returns a session id.
  String startRecording(RecordingOptions options);

  /// Stops recording. The saved file path arrives via
  /// [CameraFlutterApi.onRecordingFinished] (MovieFileOutput finalizes async).
  void stopRecording();

  @async
  bool requestPermission();

  @async
  bool hasPermission();
}

@FlutterApi()
abstract class CameraFlutterApi {
  void onSessionStarted(CameraConfig activeConfig);
  void onSessionStopped();
  void onLensSwitched(LensType lens);
  void onFocusChanged(FocusPoint point, bool locked);
  void onError(CameraErrorCode code, String? message);
  void onRecordingFinished(String path, int durationMs);
  void onRecordingFailed(CameraErrorCode code, String? message);
}
