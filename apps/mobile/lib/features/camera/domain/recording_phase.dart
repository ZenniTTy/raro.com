sealed class RecordingPhase {
  const RecordingPhase();

  bool get acceptsStart => false;
  bool get acceptsStop => false;
}

class RecordingIdle extends RecordingPhase {
  const RecordingIdle();

  @override
  bool get acceptsStart => true;
}

class RecordingStarting extends RecordingPhase {
  const RecordingStarting();
}

class RecordingActive extends RecordingPhase {
  const RecordingActive({required this.sessionId, required this.startedAt});
  final String sessionId;
  final DateTime startedAt;

  @override
  bool get acceptsStop => true;
}
