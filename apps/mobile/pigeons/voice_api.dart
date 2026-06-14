import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/voice_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/VoiceApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'VoicePigeonError'),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/voice/VoiceApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated.voice',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
enum WakeCommand { start, stop }

enum VoiceListeningState { idle, listening, paused, unavailable }

@HostApi()
abstract class VoiceHostApi {
  @async
  bool isAvailable();
  void startListening();
  void stopListening();
}

@FlutterApi()
abstract class VoiceFlutterApi {
  void onWakeDetected(WakeCommand command);
  void onListeningStateChanged(VoiceListeningState state);
}
