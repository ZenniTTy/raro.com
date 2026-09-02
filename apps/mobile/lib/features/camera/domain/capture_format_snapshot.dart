import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';
import 'package:raro_mobile/features/camera/domain/capture_format_labels.dart';
import 'package:raro_mobile/features/camera/domain/format_catalog.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';

class CaptureFormatSnapshot {
  const CaptureFormatSnapshot({
    required this.resolutionLabel,
    required this.fpsLabel,
    required this.lensLabel,
  });

  final String resolutionLabel;
  final String fpsLabel;
  final String lensLabel;
}

CaptureFormatSnapshot snapshotCaptureFormat({
  CameraSettings? active,
  required CameraShellState shell,
  required RecordingSettings settings,
}) {
  if (active != null) {
    return CaptureFormatSnapshot(
      resolutionLabel: resolutionLabel(active.resolution),
      fpsLabel: fpsLabel(active.fps),
      lensLabel: lensZoomLabel(active.lens),
    );
  }
  return CaptureFormatSnapshot(
    resolutionLabel: captureResolutionLabel(settings.resolution),
    fpsLabel: captureFpsLabel(settings.fps),
    lensLabel: shell.lensLabel,
  );
}
