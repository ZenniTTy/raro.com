import 'dart:async';

import 'package:raro_mobile/core/native_bridges/generated/volume_api.g.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/volume/application/volume_flutter_api_provider.dart';
import 'package:raro_mobile/features/volume/data/volume_repository.dart';
import 'package:raro_mobile/features/volume/data/volume_repository_provider.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volume_controller.g.dart';

typedef VolumePressTrigger = void Function(VolumeDirection direction);

@Riverpod(keepAlive: true)
class VolumeRecordingTrigger extends _$VolumeRecordingTrigger {
  @override
  VolumePressTrigger? build() => null;

  void register(VolumePressTrigger trigger) => state = trigger;
}

@Riverpod(keepAlive: true)
class VolumeController extends _$VolumeController {
  bool _cameraVisible = false;

  @override
  bool build() {
    final repo = ref.watch(volumeRepositoryProvider);

    final pressSub = ref.watch(volumePressEventsProvider).listen((direction) {
      ref.read(volumeRecordingTriggerProvider)?.call(direction);
    });
    ref.onDispose(pressSub.cancel);

    ref.listen(settingsControllerProvider, (_, _) {
      unawaited(_sync(repo));
    }, fireImmediately: true);

    return false;
  }

  Future<void> attach() async {
    _cameraVisible = true;
    await _sync(ref.read(volumeRepositoryProvider));
  }

  Future<void> detach() async {
    _cameraVisible = false;
    await _sync(ref.read(volumeRepositoryProvider));
  }

  Future<void> _sync(VolumeRepository repo) async {
    final mode = ref.read(settingsControllerProvider).value?.controlMode;
    if (_cameraVisible && mode == ControlMode.volume) {
      final available = await repo.isAvailable();
      if (!ref.mounted) return;
      if (available) {
        await repo.startListening();
        if (ref.mounted) state = true;
        return;
      }
    }
    await repo.stopListening();
    if (ref.mounted) state = false;
  }
}
