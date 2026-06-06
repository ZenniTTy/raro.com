import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/pigeon_replay_buffer_repository.dart';

class _MockHostApi extends Mock implements ReplayBufferHostApi {}

void main() {
  late _MockHostApi api;
  late PigeonReplayBufferRepository repo;

  setUp(() {
    api = _MockHostApi();
    repo = PigeonReplayBufferRepository(api);
  });

  test('enableReplayBuffer delegates with the seconds', () async {
    when(() => api.enableReplayBuffer(any())).thenAnswer((_) async {});
    await repo.enable(30);
    verify(() => api.enableReplayBuffer(30)).called(1);
  });

  test('disableReplayBuffer delegates', () async {
    when(() => api.disableReplayBuffer()).thenAnswer((_) async {});
    await repo.disable();
    verify(() => api.disableReplayBuffer()).called(1);
  });

  test('saveReplay delegates', () async {
    when(() => api.saveReplay()).thenAnswer((_) async {});
    await repo.save();
    verify(() => api.saveReplay()).called(1);
  });
}
