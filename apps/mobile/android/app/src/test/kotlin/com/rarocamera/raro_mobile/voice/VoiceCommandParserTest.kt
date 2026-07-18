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

  @Test fun `sinonimo comecar vira start (paridade swift)`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("raro começar"))
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("raro comecar"))
  }

  @Test fun `sinonimo encerrar vira stop (paridade swift)`() =
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("raro encerrar"))

  @Test fun `case e acento e espaco toleram`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("  RARO  Gravar "))
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("Raro Párar"))
  }

  @Test fun `frase contendo o comando casa`() =
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("ok raro gravar agora"))

  @Test fun `stop tem prioridade sobre start quando ambos presentes (paridade swift)`() =
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("raro parar de gravar"))

  @Test fun `sem wake word vira null mesmo com verbo`() {
    assertNull(VoiceCommandParser.parse("gravar agora"))
    assertNull(VoiceCommandParser.parse("bom dia"))
  }

  @Test fun `wake word sozinha sem verbo vira null`() =
    assertNull(VoiceCommandParser.parse("raro"))
}
