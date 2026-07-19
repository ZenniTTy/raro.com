import 'package:flutter/services.dart';
import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';

class PigeonReplayBufferRepository implements ReplayBufferRepository {
  PigeonReplayBufferRepository(this._api, {this.onUnsupported});

  final ReplayBufferHostApi _api;
  final void Function(String method)? onUnsupported;

  @override
  Future<void> enable(int seconds) =>
      _guarded('enable', () => _api.enableReplayBuffer(seconds));

  @override
  Future<void> disable() =>
      _guarded('disable', () => _api.disableReplayBuffer());

  @override
  Future<void> save() => _guarded('save', () => _api.saveReplay());

  Future<void> _guarded(String method, Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException catch (error) {
      if (error.code == 'channel-error') {
        onUnsupported?.call(method);
        return;
      }
      rethrow;
    }
  }
}
