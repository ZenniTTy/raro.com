import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/replay/application/replay_buffer_controller.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository_provider.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';

class _MockRepo extends Mock implements ReplayBufferRepository {}

void main() {
  late _MockRepo repo;
  late StreamController<ReplayResult> events;

  setUp(() {
    repo = _MockRepo();
    events = StreamController<ReplayResult>.broadcast();
  });

  tearDown(() => events.close());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        replayBufferRepositoryProvider.overrideWithValue(repo),
        replayEventsProvider.overrideWithValue(events.stream),
      ],
    );
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      replayBufferControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(keepAlive.close);
    return container;
  }

  test('initial state is idle', () {
    final container = makeContainer();
    expect(container.read(replayBufferControllerProvider), isA<ReplayIdle>());
  });

  test('setWindow enables the buffer and reflects buffering state', () async {
    when(() => repo.enable(any())).thenAnswer((_) async {});
    final container = makeContainer();
    await container.read(replayBufferControllerProvider.notifier).setWindow(30);
    expect(
      container.read(replayBufferControllerProvider),
      isA<ReplayBuffering>().having((s) => s.seconds, 'seconds', 30),
    );
    verify(() => repo.enable(30)).called(1);
  });

  test('save transitions through saving and back to buffering', () async {
    when(() => repo.enable(any())).thenAnswer((_) async {});
    when(() => repo.save()).thenAnswer((_) async {});
    final container = makeContainer();
    final notifier = container.read(replayBufferControllerProvider.notifier);
    await notifier.setWindow(15);
    await notifier.save();
    verify(() => repo.save()).called(1);
    expect(
      container.read(replayBufferControllerProvider),
      isA<ReplayBuffering>(),
    );
  });

  test('onReplayFailed event sets failed state', () async {
    when(() => repo.enable(any())).thenAnswer((_) async {});
    final container = makeContainer();
    container.read(replayBufferControllerProvider.notifier);
    await container.read(replayBufferControllerProvider.notifier).setWindow(15);
    events.add(
      const ReplayResult.failed(code: 'thermalThrottled', message: null),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      container.read(replayBufferControllerProvider),
      isA<ReplayFailedState>(),
    );
  });
}
