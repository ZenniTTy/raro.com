import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_mobile/features/camera/domain/capture_format_snapshot.dart';
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
  final repository = ref.watch(cameraRepositoryProvider);
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
    final vault = await ref.read(vaultServiceProvider.future);
    final source = File(event.path);
    final id = _idFromPath(event.path);
    final recordedAt = DateTime.now();
    final metadata = RecordingMetadata(
      id: id,
      name: _nameFor(recordedAt),
      duration: Duration(milliseconds: event.durationMs),
      recordedAt: recordedAt,
      isReplay: true,
      thumbnailHue: _hueFor(id),
      resolutionLabel: snap.resolutionLabel,
      fpsLabel: snap.fpsLabel,
      lensLabel: snap.lensLabel,
    );
    final entity = await vault.save(source, metadata: metadata);
    await _generateThumbnail(repository, logger, vault, id, entity.filePath);
    if (ref.mounted) ref.invalidate(videoListProvider);
  });
  ref.onDispose(subscription.cancel);
  return subscription;
}

Future<void> _generateThumbnail(
  CameraRepository repository,
  Logger logger,
  VaultService vault,
  String id,
  String? videoPath,
) async {
  if (videoPath == null) return;
  try {
    final thumbnailPath = await repository.generateThumbnail(videoPath);
    await vault.attachThumbnail(id, thumbnailPath);
  } on Object catch (error) {
    logger.w('replay thumbnail generation failed id=$id error=$error');
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
