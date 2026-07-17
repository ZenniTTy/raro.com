package com.rarocamera.raro_mobile.camera

import org.junit.Assert.assertEquals
import org.junit.Test

class RecordingControllerTest {
  @Test
  fun tempName_uses_raro_prefix_so_dart_id_parsing_matches() {
    assertEquals("raro_abc123.mp4", raroTempName("abc123"))
  }

  @Test
  fun tempName_composes_any_session_id() {
    assertEquals("raro_9f8e-01.mp4", raroTempName("9f8e-01"))
  }
}
