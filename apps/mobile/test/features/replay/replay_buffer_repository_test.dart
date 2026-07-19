import 'package:flutter/services.dart';
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

  group('plataforma sem bridge (channel-error) não derruba a UI', () {
    final channelError = PlatformException(
      code: 'channel-error',
      message: 'Unable to establish connection on channel: "...".',
    );

    test('enable engole channel-error (replay não implementado na '
        'plataforma) sem relançar', () async {
      when(() => api.enableReplayBuffer(any())).thenThrow(channelError);
      await expectLater(repo.enable(15), completes);
    });

    test('disable engole channel-error sem relançar', () async {
      when(() => api.disableReplayBuffer()).thenThrow(channelError);
      await expectLater(repo.disable(), completes);
    });

    test('save engole channel-error sem relançar', () async {
      when(() => api.saveReplay()).thenThrow(channelError);
      await expectLater(repo.save(), completes);
    });
  });

  group('falhas reais da bridge NÃO são engolidas (propagam)', () {
    final realFailure = PlatformException(
      code: 'thermalThrottled',
      message: 'device is hot',
    );

    test('enable propaga PlatformException que não é channel-error', () async {
      when(() => api.enableReplayBuffer(any())).thenThrow(realFailure);
      await expectLater(repo.enable(30), throwsA(isA<PlatformException>()));
    });

    test('save propaga PlatformException que não é channel-error', () async {
      when(() => api.saveReplay()).thenThrow(realFailure);
      await expectLater(repo.save(), throwsA(isA<PlatformException>()));
    });
  });
}
