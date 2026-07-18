import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class PreviewMetadata {
  const PreviewMetadata({
    required this.titleLabel,
    required this.sizeBytes,
    required this.durationLabel,
    required this.codecLabel,
  });

  factory PreviewMetadata.fromVideo(VideoEntity video) {
    return PreviewMetadata(
      titleLabel: _formatTimestamp(video.recordedAt),
      sizeBytes: video.duration.inSeconds * _bytesPerSecond,
      durationLabel: video.formattedDuration,
      codecLabel: _codec,
    );
  }

  final String titleLabel;
  final int sizeBytes;
  final String durationLabel;
  final String codecLabel;

  String get sizeLabel => '${(sizeBytes / (1024 * 1024)).round()} MB';

  static const String _codec = 'H.265';
  static const int _bytesPerSecond = 1789569;

  static String _formatTimestamp(DateTime at) {
    final day = at.day.toString().padLeft(2, '0');
    final month = at.month.toString().padLeft(2, '0');
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
