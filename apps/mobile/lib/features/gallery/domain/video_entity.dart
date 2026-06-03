import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_entity.freezed.dart';

@freezed
abstract class VideoEntity with _$VideoEntity {
  const factory VideoEntity({
    required String id,
    required String name,
    required Duration duration,
    required DateTime recordedAt,
    required bool isReplay,
    required int thumbnailHue,
    String? filePath,
  }) = _VideoEntity;

  const VideoEntity._();

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
