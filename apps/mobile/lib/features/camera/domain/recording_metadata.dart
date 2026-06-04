class RecordingMetadata {
  const RecordingMetadata({
    required this.id,
    required this.name,
    required this.duration,
    required this.recordedAt,
    required this.isReplay,
    required this.thumbnailHue,
    this.thumbnailPath,
  });

  final String id;
  final String name;
  final Duration duration;
  final DateTime recordedAt;
  final bool isReplay;
  final int thumbnailHue;
  final String? thumbnailPath;
}
