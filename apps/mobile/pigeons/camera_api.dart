import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/camera_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/CameraApi.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/CameraApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
@HostApi()
abstract class CameraHostApi {
  void cameraPing();
}

@FlutterApi()
abstract class CameraFlutterApi {
  void cameraReady();
}
