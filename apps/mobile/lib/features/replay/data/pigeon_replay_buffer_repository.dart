import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';

class PigeonReplayBufferRepository implements ReplayBufferRepository {
  PigeonReplayBufferRepository(this._api);

  final ReplayBufferHostApi _api;

  @override
  Future<void> enable(int seconds) => _api.enableReplayBuffer(seconds);

  @override
  Future<void> disable() => _api.disableReplayBuffer();

  @override
  Future<void> save() => _api.saveReplay();
}
