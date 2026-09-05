import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class PreviewClipDetails {
  const PreviewClipDetails({
    required this.name,
    required this.durationLabel,
    required this.recordedAtLabel,
    required this.isReplay,
    this.resolutionLabel,
    this.fpsLabel,
    this.lensLabel,
    this.sizeLabel,
  });

  factory PreviewClipDetails.fromVideo(VideoEntity video, {int? sizeBytes}) {
    return PreviewClipDetails(
      name: video.name,
      durationLabel: video.formattedDuration,
      recordedAtLabel: formatRecordedAt(video.recordedAt),
      isReplay: video.isReplay,
      resolutionLabel: _nonEmpty(video.resolutionLabel),
      fpsLabel: _nonEmpty(video.fpsLabel),
      lensLabel: _nonEmpty(video.lensLabel),
      sizeLabel: sizeBytes == null ? null : formatFileSize(sizeBytes),
    );
  }

  final String name;
  final String durationLabel;
  final String recordedAtLabel;
  final bool isReplay;
  final String? resolutionLabel;
  final String? fpsLabel;
  final String? lensLabel;
  final String? sizeLabel;
}

String formatRecordedAt(DateTime at) {
  final day = at.day.toString().padLeft(2, '0');
  final month = at.month.toString().padLeft(2, '0');
  final hour = at.hour.toString().padLeft(2, '0');
  final minute = at.minute.toString().padLeft(2, '0');
  return '$day/$month/${at.year} $hour:$minute';
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = bytes / (1024 * 1024);
  if (mb < 10) return '${mb.toStringAsFixed(1)} MB';
  return '${mb.round()} MB';
}

String? _nonEmpty(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}
