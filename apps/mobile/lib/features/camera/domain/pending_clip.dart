import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class PendingClip {
  const PendingClip({required this.path, required this.metadata});

  final String path;
  final RecordingMetadata metadata;

  String get id => metadata.id;

  VideoEntity get asEntity => VideoEntity(
    id: metadata.id,
    name: metadata.name,
    duration: metadata.duration,
    recordedAt: metadata.recordedAt,
    isReplay: metadata.isReplay,
    thumbnailHue: metadata.thumbnailHue,
    filePath: path,
    thumbnailPath: metadata.thumbnailPath,
    resolutionLabel: metadata.resolutionLabel,
    fpsLabel: metadata.fpsLabel,
    lensLabel: metadata.lensLabel,
  );
}
