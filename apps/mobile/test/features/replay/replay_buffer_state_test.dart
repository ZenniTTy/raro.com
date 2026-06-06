import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';

void main() {
  test('idle is the initial sealed variant', () {
    const state = ReplayBufferState.idle();
    expect(state, isA<ReplayIdle>());
  });

  test('buffering carries the window seconds', () {
    const state = ReplayBufferState.buffering(seconds: 30);
    expect((state as ReplayBuffering).seconds, 30);
  });

  test('failed carries the message', () {
    const state = ReplayBufferState.failed(message: 'thermalThrottled');
    expect((state as ReplayFailedState).message, 'thermalThrottled');
  });

  test('saving is a distinct variant', () {
    const state = ReplayBufferState.saving();
    expect(state, isA<ReplaySaving>());
  });
}
