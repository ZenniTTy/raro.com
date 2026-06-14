import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/pigeon_replay_buffer_repository.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_buffer_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ReplayBufferRepository replayBufferRepository(Ref ref) =>
    PigeonReplayBufferRepository(ReplayBufferHostApi());
