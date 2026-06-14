sealed class RecordingPhase {
  const RecordingPhase();
}

class RecordingIdle extends RecordingPhase {
  const RecordingIdle();
}

class RecordingStarting extends RecordingPhase {
  const RecordingStarting();
}

class RecordingActive extends RecordingPhase {
  const RecordingActive({required this.sessionId, required this.startedAt});
  final String sessionId;
  final DateTime startedAt;
}
