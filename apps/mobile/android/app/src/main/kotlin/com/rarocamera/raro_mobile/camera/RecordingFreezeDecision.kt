package com.rarocamera.raro_mobile.camera

enum class RecordingFreezeDecision {
  RESUME_ONLY,
  ABORT_QUEUED_STOP,
  START,
}

fun decideRecordingAfterFreeze(
  pendingStart: Boolean,
  queuedStop: Boolean,
): RecordingFreezeDecision {
  if (!pendingStart) return RecordingFreezeDecision.RESUME_ONLY
  if (queuedStop) return RecordingFreezeDecision.ABORT_QUEUED_STOP
  return RecordingFreezeDecision.START
}
