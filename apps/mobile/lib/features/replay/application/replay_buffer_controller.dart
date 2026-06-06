import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository_provider.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_buffer_controller.g.dart';

@riverpod
class ReplayBufferController extends _$ReplayBufferController {
  @override
  ReplayBufferState build() {
    final events = ref.watch(replayEventsProvider);
    final subscription = events.listen((event) {
      if (event is ReplayFailedResult) {
        state = ReplayBufferState.failed(message: event.message ?? event.code);
      } else if (event is ReplaySavedResult) {
        final current = state;
        if (current is ReplayBuffering) {
          state = current;
        } else if (current is! ReplayIdle) {
          state = const ReplayBufferState.idle();
        }
      }
    });
    ref.onDispose(subscription.cancel);
    return const ReplayBufferState.idle();
  }

  Future<void> setWindow(int seconds) async {
    final repo = ref.read(replayBufferRepositoryProvider);
    await repo.enable(seconds);
    state = ReplayBufferState.buffering(seconds: seconds);
  }

  Future<void> disable() async {
    final repo = ref.read(replayBufferRepositoryProvider);
    await repo.disable();
    state = const ReplayBufferState.idle();
  }

  Future<void> save() async {
    final current = state;
    final repo = ref.read(replayBufferRepositoryProvider);
    state = const ReplayBufferState.saving();
    try {
      await repo.save();
    } finally {
      state = current is ReplayBuffering
          ? current
          : const ReplayBufferState.idle();
    }
  }
}
