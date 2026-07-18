package com.rarocamera.raro_mobile.voice

import com.rarocamera.raro_mobile.generated.voice.WakeCommand

interface WakeEngine {
  fun start(onCommand: (WakeCommand) -> Unit): Boolean
  fun stop()
  fun isAlive(): Boolean
}
