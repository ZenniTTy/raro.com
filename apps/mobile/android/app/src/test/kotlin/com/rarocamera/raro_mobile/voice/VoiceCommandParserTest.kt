package com.rarocamera.raro_mobile.voice

import com.rarocamera.raro_mobile.generated.voice.WakeCommand
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class VoiceCommandParserTest {
  @Test fun `raro gravar vira start`() =
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("raro gravar"))

  @Test fun `raro parar vira stop`() =
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("raro parar"))

  @Test fun `transcricao real do vosk grava vira start`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("grava"))
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("grava grava"))
  }

  @Test fun `transcricao real do vosk para vira stop`() {
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("para"))
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("raro para"))
  }

  @Test fun `sinonimo comecar vira start`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("começar"))
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("comecar"))
  }

  @Test fun `sinonimo encerrar vira stop`() =
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("encerrar"))

  @Test fun `case e acento toleram`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("  RARO  Gravar "))
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("Párar"))
  }

  @Test fun `stop tem prioridade sobre start quando ambos presentes`() =
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("raro parar de gravar"))

  @Test fun `wake word opcional (vosk-small nao ouve raro)`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("gravar"))
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("parar"))
  }

  @Test fun `fala sem radical de comando vira null`() {
    assertNull(VoiceCommandParser.parse("bom dia"))
    assertNull(VoiceCommandParser.parse("raro"))
    assertNull(VoiceCommandParser.parse("claras"))
    assertNull(VoiceCommandParser.parse("a grande"))
    assertNull(VoiceCommandParser.parse(""))
  }

  @Test fun `palavra que apenas contem radical no meio nao casa`() {
    assertNull(VoiceCommandParser.parse("separadamente"))
    assertNull(VoiceCommandParser.parse("disparar"))
  }
}
