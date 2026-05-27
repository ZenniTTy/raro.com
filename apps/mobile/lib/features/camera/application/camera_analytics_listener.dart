import 'package:raro_mobile/core/analytics/firebase_analytics_provider.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_analytics_listener.g.dart';

@Riverpod(keepAlive: true)
CameraAnalyticsListener cameraAnalyticsListener(Ref ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  ref.listen(cameraControllerProvider, (previous, next) {
    next.whenData((state) {
      if (state is CameraStateReady) {
        analytics.logEvent(
          name: AnalyticsEvents.cameraStarted,
          parameters: {
            'lens': state.activeSettings.lens.name,
            'resolution': state.activeSettings.resolution.name,
            'fps': state.activeSettings.fps.name,
          },
        );
      } else if (state is CameraStateError) {
        analytics.logEvent(
          name: AnalyticsEvents.cameraError,
          parameters: {
            'code': state.code.name,
            if (state.message != null) 'message': state.message!,
          },
        );
      }
    });
  });
  return const CameraAnalyticsListener();
}

class CameraAnalyticsListener {
  const CameraAnalyticsListener();
}
