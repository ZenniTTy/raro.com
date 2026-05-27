import 'package:flutter/services.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_controller.g.dart';

CameraErrorCode mapPigeonErrorCode(String? raw) {
  if (raw == null) {
    return CameraErrorCode.sessionFailed;
  }
  for (final value in CameraErrorCode.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return CameraErrorCode.sessionFailed;
}

@riverpod
class CameraController extends _$CameraController {
  late CameraRepository _repo;

  @override
  Future<CameraState> build() async {
    _repo = ref.watch(cameraRepositoryProvider);
    ref.onDispose(() {
      _repo.stopSession().ignore();
    });
    final caps = await _repo.discoverCapabilities();
    return CameraState.idle(capabilities: caps);
  }

  Future<void> start({
    required int textureId,
    required CameraSettings settings,
  }) async {
    state = const AsyncData(CameraState.initializing());
    try {
      await _repo.startSession(textureId, settings.toConfig());
      state = AsyncData(CameraState.ready(activeSettings: settings));
    } on PlatformException catch (e) {
      state = AsyncData(
        CameraState.error(
          code: mapPigeonErrorCode(e.code),
          message: e.message ?? e.toString(),
        ),
      );
    } on Object catch (e) {
      state = AsyncData(
        CameraState.error(
          code: CameraErrorCode.sessionFailed,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    await _repo.stopSession();
    final caps = await _repo.discoverCapabilities();
    state = AsyncData(CameraState.idle(capabilities: caps));
  }

  Future<bool> requestPermission() => _repo.requestPermission();

  Future<bool> hasPermission() => _repo.hasPermission();

  Future<void> switchLens(LensType lens) async {
    await _repo.switchLens(lens);
    final current = state.requireValue;
    if (current is CameraStateReady) {
      state = AsyncData(
        CameraState.ready(
          activeSettings: current.activeSettings.copyWith(lens: lens),
          lastFocusPoint: current.lastFocusPoint,
        ),
      );
    }
  }

  Future<void> setFormat(Resolution resolution, Fps fps) async {
    await _repo.setFormat(resolution, fps);
    final current = state.requireValue;
    if (current is CameraStateReady) {
      state = AsyncData(
        CameraState.ready(
          activeSettings: current.activeSettings.copyWith(
            resolution: resolution,
            fps: fps,
          ),
          lastFocusPoint: current.lastFocusPoint,
        ),
      );
    }
  }

  Future<void> focusAt(double x, double y) async {
    final point = FocusPoint(x: x, y: y);
    await _repo.focusAt(point);
    final current = state.requireValue;
    if (current is CameraStateReady) {
      state = AsyncData(
        CameraState.ready(
          activeSettings: current.activeSettings,
          lastFocusPoint: point,
        ),
      );
    }
  }
}
