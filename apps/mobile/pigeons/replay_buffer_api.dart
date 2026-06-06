import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/replay_buffer_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/ReplayBufferApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'ReplayBufferPigeonError'),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/replay_buffer/ReplayBufferApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated.replay_buffer',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
@HostApi()
abstract class ReplayBufferHostApi {
  void enableReplayBuffer(int seconds);
  void disableReplayBuffer();
  void saveReplay();
}

@FlutterApi()
abstract class ReplayBufferFlutterApi {
  void onReplaySaved(String path, int durationMs);
  void onReplayFailed(String code, String? message);
}
