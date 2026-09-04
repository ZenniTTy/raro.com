import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/application/persist_recording_scope.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_mobile/features/camera/domain/capture_format_snapshot.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_vault_sink.g.dart';

@Riverpod(keepAlive: true)
StreamSubscription<ReplayResult> replayVaultSink(Ref ref) {
  final events = ref.watch(replayEventsProvider);
  final logger = ref.watch(appLoggerProvider);
  final subscription = events.listen((event) async {
    if (event is ReplayFailedResult) {
      logger.e('replay failed code=${event.code} message=${event.message}');
      return;
    }
    if (event is! ReplaySavedResult) {
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
    final clip = PendingClip(
      path: event.path,
      metadata: RecordingMetadata(
        id: id,
        name: _nameFor(recordedAt),
        duration: Duration(milliseconds: event.durationMs),
        recordedAt: recordedAt,
        isReplay: true,
        thumbnailHue: _hueFor(id),
        resolutionLabel: snap.resolutionLabel,
        fpsLabel: snap.fpsLabel,
        lensLabel: snap.lensLabel,
      ),
    );
    final persist = await persistRecordingForRef(ref);
    final outcome = await persist(clip);
    switch (outcome) {
      case PersistNeedsPremium():
        logger.i('replay discarded needsPremium id=$id path=${event.path}');
        await _deleteTemp(File(event.path), logger);
      case PersistSucceeded():
        if (ref.mounted) ref.invalidate(videoListProvider);
      case PersistFailed():
        break;
    }
  });
  ref.onDispose(subscription.cancel);
  return subscription;
}

Future<void> _deleteTemp(File source, Logger logger) async {
  try {
    if (await source.exists()) {
      await source.delete();
    }
  } on Object catch (error) {
    logger.w('replay temp discard failed path=${source.path} error=$error');
  }
}

String _idFromPath(String path) {
  final fileName = path.split('/').last;
  final dot = fileName.lastIndexOf('.');
  final stem = dot == -1 ? fileName : fileName.substring(0, dot);
  return stem.startsWith('raro_replay_') ? stem.substring(12) : stem;
}

String _nameFor(DateTime at) {
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  return 'Replay $hh:$mm';
}

int _hueFor(String id) => id.hashCode.abs() % 360;
