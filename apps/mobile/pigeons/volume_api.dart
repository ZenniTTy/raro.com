import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/volume_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/VolumeApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'VolumePigeonError'),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/volume/VolumeApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated.volume',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
@HostApi()
abstract class VolumeHostApi {
  void volumePing();
}

@FlutterApi()
abstract class VolumeFlutterApi {
  void volumeReady();
}
