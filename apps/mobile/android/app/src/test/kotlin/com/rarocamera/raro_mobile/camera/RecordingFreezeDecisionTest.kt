package com.rarocamera.raro_mobile.camera

import org.junit.Assert.assertEquals
import org.junit.Test

class RecordingFreezeDecisionTest {
  @Test
  fun pendingStart_false_only_resumes_replay() {
    assertEquals(
      RecordingFreezeDecision.RESUME_ONLY,
      decideRecordingAfterFreeze(pendingStart = false, queuedStop = false),
    )
    assertEquals(
      RecordingFreezeDecision.RESUME_ONLY,
      decideRecordingAfterFreeze(pendingStart = false, queuedStop = true),
    )
  }

  @Test
  fun queuedStop_before_recorder_aborts_instead_of_start_then_stop() {
    assertEquals(
      RecordingFreezeDecision.ABORT_QUEUED_STOP,
      decideRecordingAfterFreeze(pendingStart = true, queuedStop = true),
    )
  }

  @Test
  fun pendingStart_without_stop_starts_recording() {
    assertEquals(
      RecordingFreezeDecision.START,
      decideRecordingAfterFreeze(pendingStart = true, queuedStop = false),
    )
  }
}
