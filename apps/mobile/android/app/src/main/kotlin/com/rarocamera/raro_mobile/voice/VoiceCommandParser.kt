package com.rarocamera.raro_mobile.voice

import com.rarocamera.raro_mobile.generated.voice.WakeCommand
import java.text.Normalizer

object VoiceCommandParser {
  private const val WAKE = "raro"
  private val STOP_VERBS = listOf("parar", "encerrar")
  private val START_VERBS = listOf("gravar", "comecar")

  fun parse(transcript: String): WakeCommand? {
    val n = normalize(transcript)
    if (!n.contains(WAKE)) return null
    if (STOP_VERBS.any { n.contains(it) }) return WakeCommand.STOP
    if (START_VERBS.any { n.contains(it) }) return WakeCommand.START
    return null
  }

  private fun normalize(s: String): String {
    val lower = s.trim().lowercase()
    val decomposed = Normalizer.normalize(lower, Normalizer.Form.NFD)
    return decomposed.replace(Regex("\\p{Mn}+"), "").replace(Regex("\\s+"), " ")
  }
}
