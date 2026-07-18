package com.rarocamera.raro_mobile.voice

import com.rarocamera.raro_mobile.generated.voice.WakeCommand
import java.text.Normalizer

object VoiceCommandParser {
  private val STOP_STEMS = listOf("parar", "para", "encerr")
  private val START_STEMS = listOf("gravar", "grava", "comec")

  fun parse(transcript: String): WakeCommand? {
    val words = normalize(transcript).split(" ").filter { it.isNotBlank() }
    if (words.isEmpty()) return null
    if (words.any { matchesStem(it, STOP_STEMS) }) return WakeCommand.STOP
    if (words.any { matchesStem(it, START_STEMS) }) return WakeCommand.START
    return null
  }

  private fun matchesStem(word: String, stems: List<String>): Boolean =
    stems.any { stem -> word == stem || word.startsWith(stem) }

  private fun normalize(s: String): String {
    val lower = s.trim().lowercase()
    val decomposed = Normalizer.normalize(lower, Normalizer.Form.NFD)
    return decomposed.replace(Regex("\\p{Mn}+"), "").replace(Regex("\\s+"), " ")
  }
}
