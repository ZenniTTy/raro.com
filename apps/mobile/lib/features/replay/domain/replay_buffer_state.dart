sealed class ReplayBufferState {
  const ReplayBufferState();

  const factory ReplayBufferState.idle() = ReplayIdle;
  const factory ReplayBufferState.buffering({required int seconds}) =
      ReplayBuffering;
  const factory ReplayBufferState.saving() = ReplaySaving;
  const factory ReplayBufferState.failed({required String message}) =
      ReplayFailedState;
}

class ReplayIdle extends ReplayBufferState {
  const ReplayIdle();
}

class ReplayBuffering extends ReplayBufferState {
  const ReplayBuffering({required this.seconds});
  final int seconds;
}

class ReplaySaving extends ReplayBufferState {
  const ReplaySaving();
}

class ReplayFailedState extends ReplayBufferState {
  const ReplayFailedState({required this.message});
  final String message;
}
