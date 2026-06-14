import 'dart:async';

import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_flutter_api_provider.g.dart';

sealed class ReplayResult {
  const ReplayResult();

  const factory ReplayResult.saved({
    required String path,
    required int durationMs,
  }) = ReplaySavedResult;

  const factory ReplayResult.failed({required String code, String? message}) =
      ReplayFailedResult;
}

class ReplaySavedResult extends ReplayResult {
  const ReplaySavedResult({required this.path, required this.durationMs});

  final String path;
  final int durationMs;
}

class ReplayFailedResult extends ReplayResult {
  const ReplayFailedResult({required this.code, this.message});

  final String code;
  final String? message;
}

@Riverpod(keepAlive: true)
Raw<Stream<ReplayResult>> replayEvents(Ref ref) {
  final controller = StreamController<ReplayResult>.broadcast();
  ReplayBufferFlutterApi.setUp(_ReplayFlutterApi(controller));
  ref.onDispose(() {
    ReplayBufferFlutterApi.setUp(null);
    controller.close();
  });
  return controller.stream;
}

class _ReplayFlutterApi implements ReplayBufferFlutterApi {
  _ReplayFlutterApi(this._sink);

  final StreamController<ReplayResult> _sink;

  @override
  void onReplaySaved(String path, int durationMs) =>
      _sink.add(ReplayResult.saved(path: path, durationMs: durationMs));

  @override
  void onReplayFailed(String code, String? message) =>
      _sink.add(ReplayResult.failed(code: code, message: message));
}
