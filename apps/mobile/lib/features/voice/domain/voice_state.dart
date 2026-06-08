sealed class VoiceState {
  const VoiceState();
}

class VoiceIdle extends VoiceState {
  const VoiceIdle();

  @override
  bool operator ==(Object other) => other is VoiceIdle;

  @override
  int get hashCode => (VoiceIdle).hashCode;
}

class VoiceListening extends VoiceState {
  const VoiceListening();

  @override
  bool operator ==(Object other) => other is VoiceListening;

  @override
  int get hashCode => (VoiceListening).hashCode;
}

class VoicePaused extends VoiceState {
  const VoicePaused();

  @override
  bool operator ==(Object other) => other is VoicePaused;

  @override
  int get hashCode => (VoicePaused).hashCode;
}

class VoiceUnavailable extends VoiceState {
  const VoiceUnavailable();

  @override
  bool operator ==(Object other) => other is VoiceUnavailable;

  @override
  int get hashCode => (VoiceUnavailable).hashCode;
}
