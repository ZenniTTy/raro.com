import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/voice/application/voice_flutter_api_provider.dart';
import 'package:raro_mobile/features/voice/data/voice_repository.dart';
import 'package:raro_mobile/features/voice/data/voice_repository_provider.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_controller.g.dart';

const bool _voiceEngineAvailable = false;

typedef RecordingTrigger = void Function(WakeCommand command);

@Riverpod(keepAlive: true)
class VoiceRecordingTrigger extends _$VoiceRecordingTrigger {
  @override
  RecordingTrigger? build() => null;

  void register(RecordingTrigger trigger) => state = trigger;
}

@Riverpod(keepAlive: true)
class VoiceController extends _$VoiceController {
  @override
  VoiceState build() {
    final repo = ref.watch(voiceRepositoryProvider);

    final wakeSub = ref.watch(voiceWakeEventsProvider).listen(_handleWake);
    ref.onDispose(wakeSub.cancel);

    final stateSub = ref.watch(voiceStateEventsProvider).listen((s) {
      state = _mapState(s);
    });
    ref.onDispose(stateSub.cancel);

    ref.listen(settingsControllerProvider, (prev, next) {
      _syncListening(repo, next.value?.controlMode);
    }, fireImmediately: true);

    return const VoiceIdle();
  }

  Future<void> _syncListening(VoiceRepository repo, ControlMode? mode) async {
    if (mode == null) return;
    if (!_voiceEngineAvailable) {
      await repo.stopListening();
      if (ref.mounted) state = const VoiceIdle();
      return;
    }
    if (mode != ControlMode.voice) {
      await repo.stopListening();
      if (ref.mounted) state = const VoiceIdle();
      return;
    }
    final available = await repo.isAvailable();
    if (!ref.mounted) return;
    if (!available) {
      state = const VoiceUnavailable();
      return;
    }
    await repo.startListening();
  }

  void _handleWake(WakeCommand command) {
    final trigger = ref.read(voiceRecordingTriggerProvider);
    trigger?.call(command);
  }

  VoiceState _mapState(VoiceListeningState s) => switch (s) {
    VoiceListeningState.idle => const VoiceIdle(),
    VoiceListeningState.listening => const VoiceListening(),
    VoiceListeningState.paused => const VoicePaused(),
    VoiceListeningState.unavailable => const VoiceUnavailable(),
  };
}
