import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';

void main() {
  test('VoiceState tem os 4 estados distintos', () {
    expect(const VoiceIdle(), isA<VoiceState>());
    expect(const VoiceListening(), isA<VoiceState>());
    expect(const VoicePaused(), isA<VoiceState>());
    expect(const VoiceUnavailable(), isA<VoiceState>());
  });
  test('VoiceState compara por igualdade de valor', () {
    expect(const VoiceListening(), const VoiceListening());
    expect(const VoiceListening() == const VoiceIdle(), isFalse);
    expect(const VoicePaused(), const VoicePaused());
    expect(const VoiceUnavailable(), const VoiceUnavailable());
  });
}
