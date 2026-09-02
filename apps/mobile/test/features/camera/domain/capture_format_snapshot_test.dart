import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';
import 'package:raro_mobile/features/camera/domain/capture_format_snapshot.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart' as shared;

void main() {
  test('usa a sessão ativa (lente 0.5×) e não as settings', () {
    final snap = snapshotCaptureFormat(
      active: const CameraSettings(
        lens: LensType.ultraWide,
        resolution: Resolution.uhd4k,
        fps: Fps.fps30,
      ),
      shell: const CameraShellState(recording: false, lens: LensType.wide),
      settings: const RecordingSettings(
        resolution: shared.Resolution.fullHd1080,
        fps: shared.Fps.fps60,
      ),
    );
    expect(snap.resolutionLabel, '4K');
    expect(snap.fpsLabel, '30FPS');
    expect(snap.lensLabel, '0.5×');
  });

  test('sem sessão cai na lente do shell e no formato das settings', () {
    final snap = snapshotCaptureFormat(
      shell: const CameraShellState(recording: false, lens: LensType.ultraWide),
      settings: const RecordingSettings(
        resolution: shared.Resolution.fullHd1080,
        fps: shared.Fps.fps30,
      ),
    );
    expect(snap.resolutionLabel, '1080p');
    expect(snap.fpsLabel, '30FPS');
    expect(snap.lensLabel, '0.5×');
  });
}
