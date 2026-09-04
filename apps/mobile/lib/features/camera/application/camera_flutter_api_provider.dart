import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_mobile/features/camera/domain/capture_format_snapshot.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_flutter_api_provider.g.dart';

sealed class RecordingResult {
  const RecordingResult();

  const factory RecordingResult.started({required String sessionId}) =
      RecordingStarted;

  const factory RecordingResult.finished({
    required String path,
    required int durationMs,
  }) = RecordingFinished;

  const factory RecordingResult.failed({
    required CameraErrorCode code,
    String? message,
  }) = RecordingFailed;
}

class RecordingStarted extends RecordingResult {
  const RecordingStarted({required this.sessionId});

  final String sessionId;
}

class RecordingFinished extends RecordingResult {
  const RecordingFinished({required this.path, required this.durationMs});

  final String path;
  final int durationMs;
}

class RecordingFailed extends RecordingResult {
  const RecordingFailed({required this.code, this.message});

  final CameraErrorCode code;
  final String? message;
}

@Riverpod(keepAlive: true)
Raw<Stream<RecordingResult>> recordingEvents(Ref ref) {
  final controller = StreamController<RecordingResult>.broadcast();
  CameraFlutterApi.setUp(_RecordingFlutterApi(controller));
  ref.onDispose(() {
    CameraFlutterApi.setUp(null);
    controller.close();
  });
  return controller.stream;
}

@Riverpod(keepAlive: true)
StreamSubscription<RecordingResult> recordingVaultSink(Ref ref) {
  final events = ref.watch(recordingEventsProvider);
  final logger = ref.watch(appLoggerProvider);
  final subscription = events.listen((event) {
    if (event is RecordingFailed) {
      logger.e(
        'recording failed code=${event.code.name} message=${event.message}',
      );
      return;
    }
    if (event is! RecordingFinished) {
      return;
    }
    final settings =
        ref.read(settingsControllerProvider).value ?? const RecordingSettings();
    final ready = ref.exists(cameraControllerProvider)
        ? ref.read(cameraControllerProvider).value
        : null;
    final snap = snapshotCaptureFormat(
      active: ready is CameraStateReady ? ready.activeSettings : null,
      shell: ref.read(cameraShellProvider),
      settings: settings,
    );
    final id = _idFromPath(event.path);
    final recordedAt = DateTime.now();
    ref
        .read(pendingRecordingProvider.notifier)
        .replace(
          PendingClip(
            path: event.path,
            metadata: RecordingMetadata(
              id: id,
              name: _nameFor(recordedAt),
              duration: Duration(milliseconds: event.durationMs),
              recordedAt: recordedAt,
              isReplay: false,
              thumbnailHue: _hueFor(id),
              resolutionLabel: snap.resolutionLabel,
              fpsLabel: snap.fpsLabel,
              lensLabel: snap.lensLabel,
            ),
          ),
        );
  });
  ref.onDispose(subscription.cancel);
  return subscription;
}

String _idFromPath(String path) {
  final fileName = path.split('/').last;
  final dot = fileName.lastIndexOf('.');
  final stem = dot == -1 ? fileName : fileName.substring(0, dot);
  return stem.startsWith('raro_') ? stem.substring(5) : stem;
}

@visibleForTesting
String idFromPathForTest(String path) => _idFromPath(path);

String _nameFor(DateTime at) {
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  return 'Vídeo $hh:$mm';
}

int _hueFor(String id) => id.hashCode.abs() % 360;

class _RecordingFlutterApi implements CameraFlutterApi {
  _RecordingFlutterApi(this._sink);

  final StreamController<RecordingResult> _sink;

  @override
  void onRecordingStarted(String sessionId) =>
      _sink.add(RecordingResult.started(sessionId: sessionId));

  @override
  void onRecordingFinished(String path, int durationMs) =>
      _sink.add(RecordingResult.finished(path: path, durationMs: durationMs));

  @override
  void onRecordingFailed(CameraErrorCode code, String? message) =>
      _sink.add(RecordingResult.failed(code: code, message: message));

  @override
  void onSessionStarted(CameraConfig activeConfig) {}

  @override
  void onSessionStopped() {}

  @override
  void onLensSwitched(LensType lens) {}

  @override
  void onFocusChanged(FocusPoint point, bool locked) {}

  @override
  void onError(CameraErrorCode code, String? message) {}
}
