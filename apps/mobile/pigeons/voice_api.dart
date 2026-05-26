import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/voice_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/VoiceApi.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/VoiceApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
@HostApi()
abstract class VoiceHostApi {
  void voicePing();
}

@FlutterApi()
abstract class VoiceFlutterApi {
  void voiceReady();
}
