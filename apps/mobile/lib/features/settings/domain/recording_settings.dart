import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:raro_shared/raro_shared.dart';

part 'recording_settings.freezed.dart';

@freezed
abstract class RecordingSettings with _$RecordingSettings {
  const factory RecordingSettings({
    @Default(Resolution.fullHd1080) Resolution resolution,
    @Default(Fps.fps60) Fps fps,
    @Default(BufferDuration.seconds30) BufferDuration bufferDuration,
    @Default(ControlMode.voice) ControlMode controlMode,
    AppLanguage? language,
  }) = _RecordingSettings;
}
