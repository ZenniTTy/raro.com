import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
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
  final repository = ref.watch(cameraRepositoryProvider);
  final logger = ref.watch(appLoggerProvider);
  final subscription = events.listen((event) async {
    if (event is RecordingFailed) {
      logger.e(
        'recording failed code=${event.code.name} message=${event.message}',
      );
      return;
    }
    if (event is! RecordingFinished) {
      return;
    }
    final vault = await ref.read(vaultServiceProvider.future);
    final source = File(event.path);
    final id = _idFromPath(event.path);
    final recordedAt = DateTime.now();
    final metadata = RecordingMetadata(
      id: id,
      name: _nameFor(recordedAt),
      duration: Duration(milliseconds: event.durationMs),
      recordedAt: recordedAt,
      isReplay: false,
      thumbnailHue: _hueFor(id),
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
    logger.w('thumbnail generation failed id=$id error=$error');
  }
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
