package com.rarocamera.raro_mobile.replay

import com.rarocamera.raro_mobile.generated.replay_buffer.ReplayBufferHostApi

class ReplayBufferHostApiImpl : ReplayBufferHostApi {
  override fun enableReplayBuffer(seconds: Long) {
    throw UnsupportedOperationException("formatUnsupported: replay buffer is iOS-only until Sprint 3")
  }

  override fun disableReplayBuffer() {
    throw UnsupportedOperationException("formatUnsupported: replay buffer is iOS-only until Sprint 3")
  }

  override fun saveReplay() {
    throw UnsupportedOperationException("formatUnsupported: replay buffer is iOS-only until Sprint 3")
  }
}
