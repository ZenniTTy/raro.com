import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsEvents — camera extension', () {
    test('cameraStarted is camera_started', () {
      expect(AnalyticsEvents.cameraStarted, 'camera_started');
    });
    test('cameraStopped is camera_stopped', () {
      expect(AnalyticsEvents.cameraStopped, 'camera_stopped');
    });
    test('cameraFocusTapped is camera_focus_tapped', () {
      expect(AnalyticsEvents.cameraFocusTapped, 'camera_focus_tapped');
    });
    test('cameraPermissionDenied is camera_permission_denied', () {
      expect(
        AnalyticsEvents.cameraPermissionDenied,
        'camera_permission_denied',
      );
    });
    test('cameraError is camera_error', () {
      expect(AnalyticsEvents.cameraError, 'camera_error');
    });
  });
}
