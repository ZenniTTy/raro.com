import 'dart:async';

import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_flutter_api_provider.g.dart';

class _VoiceFlutterApi implements VoiceFlutterApi {
  _VoiceFlutterApi({required this.onWake, required this.onState});

  final void Function(WakeCommand) onWake;
  final void Function(VoiceListeningState) onState;

  @override
  void onWakeDetected(WakeCommand command) => onWake(command);

  @override
  void onListeningStateChanged(VoiceListeningState state) => onState(state);
}

class _VoiceEventSinks {
  final StreamController<WakeCommand> wake =
      StreamController<WakeCommand>.broadcast();
  final StreamController<VoiceListeningState> state =
      StreamController<VoiceListeningState>.broadcast();

  void dispose() {
    wake.close();
    state.close();
  }
}

@Riverpod(keepAlive: true)
_VoiceEventSinks _voiceEventSinks(Ref ref) {
  final sinks = _VoiceEventSinks();
  VoiceFlutterApi.setUp(
    _VoiceFlutterApi(onWake: sinks.wake.add, onState: sinks.state.add),
  );
  ref.onDispose(() {
    VoiceFlutterApi.setUp(null);
    sinks.dispose();
  });
  return sinks;
}

@Riverpod(keepAlive: true)
Raw<Stream<WakeCommand>> voiceWakeEvents(Ref ref) =>
    ref.watch(_voiceEventSinksProvider).wake.stream;

@Riverpod(keepAlive: true)
Raw<Stream<VoiceListeningState>> voiceStateEvents(Ref ref) =>
    ref.watch(_voiceEventSinksProvider).state.stream;
