# Voz Android (SpeechRecognizer foreground + Vosk background) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans para implementar task-by-task. Steps usam checkbox (`- [ ]`).

**Goal:** "raro gravar" / "raro parar" reconhecidos no Android — foreground (app visível, `SpeechRecognizer` on-device) e background (tela apagada, FGS `microphone` + Vosk) — atrás do Pigeon `VoiceHostApi` inalterado, com toggle opt-in em Settings.

**Architecture:** Duas camadas atrás do MESMO Pigeon (zero mudança de contrato). `VoiceHostApiImpl` (registrado no `MainActivity`) roteia: app visível → `ForegroundVoiceRecognizer` (`SpeechRecognizer` on-device + `VoiceCommandParser`); toggle background ON + app minimizado → `VoiceBackgroundService` (FGS type=microphone + `WakeEngine`←`VoskWakeEngine`, `AudioRecord` 16kHz mono → Vosk). Nunca os dois capturando juntos.

**Tech Stack:** Kotlin, `android.speech.SpeechRecognizer` (on-device, API 31), `checkRecognitionSupport` (API 33 + fallback SDK_INT), `com.alphacephei:vosk-android:0.3.47`, modelo `vosk-model-small-pt-0.3` (31MB asset), FGS type `microphone` (targetSdk 36).

## Global Constraints

- Wake word = `"Raro"` de `raro_shared` (invariante; espelhar em constante Kotlin, hard rule).
- 2 comandos DISTINTOS (start/stop), NÃO toggle (ADR-0024).
- **Contrato Pigeon `voice_api.dart` INALTERADO** — `VoiceHostApi{isAvailable(async), startListening, stopListening}` + `VoiceFlutterApi{onWakeDetected(WakeCommand), onListeningStateChanged(VoiceListeningState)}`. Enums `WakeCommand{start,stop}`, `VoiceListeningState{idle,listening,paused,unavailable}`.
- **Sem tocar `.swift`** — Android-only.
- SDK: minSdk 24, targetSdk 36, compileSdk 36 (Flutter 3.44).
- Vosk AAR = **`0.3.47`** (NÃO 0.3.50 — tag C++). Apache 2.0.
- `checkRecognitionSupport`/`RecognitionSupport` = **API 33**; fallback por `Build.VERSION.SDK_INT` para 24–32.
- FGS microphone é **while-in-use**: inicia só com app visível; nunca de background/BOOT.
- Sem swallow de erro sem log; sem comentários explicando WHAT; ktlint default.
- Build Android: `JAVA_HOME` = JBR 21 do Android Studio.
- Method Channel namespace já definido pelo Pigeon.

---

### Task 1: SPIKE-GATE — provar pt-BR on-device no M54 (BLOQUEANTE)

Antes de QUALQUER bridge, provar que o M54 (API 36) tem pt-BR on-device via `checkRecognitionSupport`. Se ausente → o design muda (Vosk assume também o foreground). NÃO escalar para Task 2+ sem este gate verde. Lição: `feedback_synthetic_eval_is_not_the_gate_device_is`.

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/SpeechRecognitionProbe.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt` (chamar o probe no `configureFlutterEngine`, atrás de um log; REMOVER após o gate)

**Interfaces:**
- Produces: `object SpeechRecognitionProbe { fun probe(context: Context) }` — loga em `RaroVoiceProbe` o SDK_INT, se `SpeechRecognizer.isOnDeviceRecognitionAvailable(context)`, e (se SDK_INT>=33) o resultado de `checkRecognitionSupport` para `EXTRA_LANGUAGE="pt-BR"`: installed / supported / pending languages.

- [ ] **Step 1: Criar `SpeechRecognitionProbe.kt`**

```kotlin
package com.rarocamera.raro_mobile.voice

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log

object SpeechRecognitionProbe {
  private const val TAG = "RaroVoiceProbe"

  fun probe(context: Context) {
    Log.i(TAG, "SDK_INT=${Build.VERSION.SDK_INT}")
    val onDeviceAvailable = SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
    Log.i(TAG, "isOnDeviceRecognitionAvailable=$onDeviceAvailable")

    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
      Log.i(TAG, "SDK<33: checkRecognitionSupport indisponivel; fallback path em producao")
      return
    }
    if (!onDeviceAvailable) {
      Log.w(TAG, "on-device recognition indisponivel neste device")
      return
    }

    val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
    }
    recognizer.checkRecognitionSupport(
      intent,
      context.mainExecutor,
      object : RecognitionSupportCallback {
        override fun onSupportResult(recognitionSupport: RecognitionSupport) {
          Log.i(TAG, "installed=${recognitionSupport.installedOnDeviceLanguages}")
          Log.i(TAG, "supported=${recognitionSupport.supportedOnDeviceLanguages}")
          Log.i(TAG, "pending=${recognitionSupport.pendingOnDeviceLanguages}")
          val ptInstalled = recognitionSupport.installedOnDeviceLanguages.any {
            it.equals("pt-BR", ignoreCase = true) || it.startsWith("pt", ignoreCase = true)
          }
          Log.i(TAG, "PT_BR_ON_DEVICE_INSTALLED=$ptInstalled")
          recognizer.destroy()
        }

        override fun onError(error: Int) {
          Log.w(TAG, "checkRecognitionSupport error=$error")
          recognizer.destroy()
        }
      },
    )
  }
}
```

- [ ] **Step 2: Chamar o probe no MainActivity (temporário)**

Em `MainActivity.configureFlutterEngine`, após o `super.configureFlutterEngine(...)`:

```kotlin
com.rarocamera.raro_mobile.voice.SpeechRecognitionProbe.probe(applicationContext)
```

- [ ] **Step 3: Build + install + rodar no M54**

```bash
cd apps/mobile && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb logcat -c && echo "abra o app"
```
Após abrir o app:
```bash
adb logcat -d -s RaroVoiceProbe
```
Expected: `PT_BR_ON_DEVICE_INSTALLED=true`. Registrar a saída no PR.

- [ ] **Step 4: GATE — decidir com base no resultado**
- Se `PT_BR_ON_DEVICE_INSTALLED=true` → SpeechRecognizer é o foreground (Task 3+). Prosseguir.
- Se `false` mas em `supported` → precisa trigger de download; documentar e usar Vosk no foreground também.
- Se ausente de tudo → Vosk assume foreground E background (design fallback do ADR-0029). Ajustar Task 3.

- [ ] **Step 5: Remover o probe do MainActivity**

Reverter o Step 2 (remover a linha `SpeechRecognitionProbe.probe(...)`). Manter `SpeechRecognitionProbe.kt` no repo como ferramenta (documentado). Commit:

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/SpeechRecognitionProbe.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt
git commit -m "feat(voice): spike-gate provando pt-br on-device no m54 (checkRecognitionSupport)"
```

---

### Task 2: Dependências + manifest + asset do modelo Vosk

**Files:**
- Modify: `apps/mobile/android/app/build.gradle.kts:54` (adicionar Vosk após camera-video)
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml` (permissões FGS + service)
- Create: `apps/mobile/android/app/src/main/jniLibs/` NÃO — o AAR traz as libs. Asset do modelo em `apps/mobile/android/app/src/main/assets/vosk-model-small-pt-0.3/` (descompactado)

**Interfaces:**
- Produces: dep Vosk resolvível; manifest com FGS microphone; modelo em assets.

- [ ] **Step 1: Adicionar a dep Vosk**

Em `build.gradle.kts`, após a linha `implementation("androidx.camera:camera-video:1.6.1")`:

```kotlin
    implementation("com.alphacephei:vosk-android:0.3.47")
```

- [ ] **Step 2: Baixar + descompactar o modelo em assets**

```bash
cd apps/mobile/android/app/src/main/assets
curl -L -o vosk-model-small-pt-0.3.zip https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip
unzip -q vosk-model-small-pt-0.3.zip && rm vosk-model-small-pt-0.3.zip
ls vosk-model-small-pt-0.3/  # deve ter am/, conf/, graph/, ivector/
```
Nota: 31MB entram no repo/APK. Confirmar `.gitignore` não bloqueia assets.

- [ ] **Step 3: Manifest — permissões + service**

Em `AndroidManifest.xml`, após as `uses-permission` existentes (RECORD_AUDIO já existe):

```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

Dentro de `<application>`, após a `<activity>`:

```xml
        <service
            android:name=".voice.VoiceBackgroundService"
            android:exported="false"
            android:foregroundServiceType="microphone" />
```

- [ ] **Step 4: Verificar build (sem o service ainda implementado, o manifest referencia — criar stub mínimo ou adiar o `<service>` para Task 5)**

NOTA DE ORDEM: o `<service>` referencia `VoiceBackgroundService` que só existe na Task 5. Para não quebrar o build, adicionar o bloco `<service>` SÓ na Task 5. Nesta task, adicionar apenas as 2 `uses-permission` e a dep. Rebuild:

```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL (Vosk resolve).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/android/app/build.gradle.kts apps/mobile/android/app/src/main/AndroidManifest.xml apps/mobile/android/app/src/main/assets/vosk-model-small-pt-0.3/
git commit -m "build(voice): dep vosk-android 0.3.47 + modelo pt asset + permissoes fgs"
```

---

### Task 3: `VoiceCommandParser` — matching de "raro gravar"/"raro parar" (função pura, testável)

Porta 1:1 do parser Swift. Recebe transcript, devolve `WakeCommand?`. Função pura → testável sem device (única parte com teste unitário Kotlin via a rota de função pura, sem Robolectric, como na Fatia 1).

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/VoiceCommandParser.kt`
- Test: `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/voice/VoiceCommandParserTest.kt`

**Interfaces:**
- Produces: `object VoiceCommandParser { fun parse(transcript: String): WakeCommand? }` — normaliza (lowercase, trim, remove acento), casa `"raro gravar"`→`start`, `"raro parar"`→`stop` com tolerância fuzzy leve (contains). Task 4 e Task 5 consomem.

- [ ] **Step 1: Ver o parser Swift de referência**

Ler `apps/mobile/ios/Runner/Native/Voice/VoiceCommandParser.swift` (ou equivalente) para espelhar a normalização e as frases exatas. Confirmar wake word de `raro_shared`.

- [ ] **Step 2: Escrever o teste (red)**

```kotlin
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

  @Test fun `case e acento e espaco toleram`() {
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("  RARO  Gravar "))
    assertEquals(WakeCommand.STOP, VoiceCommandParser.parse("Raro Párar"))
  }

  @Test fun `frase contendo o comando casa`() =
    assertEquals(WakeCommand.START, VoiceCommandParser.parse("ok raro gravar agora"))

  @Test fun `transcript sem comando vira null`() {
    assertNull(VoiceCommandParser.parse("bom dia"))
    assertNull(VoiceCommandParser.parse("raro"))
  }
}
```

- [ ] **Step 3: Rodar o teste (deve falhar — classe não existe)**

```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:testDebugUnitTest --tests "*VoiceCommandParserTest*"
```
Expected: FAIL (unresolved reference VoiceCommandParser).

- [ ] **Step 4: Implementar `VoiceCommandParser.kt`**

```kotlin
package com.rarocamera.raro_mobile.voice

import com.rarocamera.raro_mobile.generated.voice.WakeCommand
import java.text.Normalizer

object VoiceCommandParser {
  private const val WAKE = "raro"
  private const val START_VERB = "gravar"
  private const val STOP_VERB = "parar"

  fun parse(transcript: String): WakeCommand? {
    val n = normalize(transcript)
    if (!n.contains(WAKE)) return null
    return when {
      n.contains("$WAKE $START_VERB") || (n.contains(WAKE) && n.contains(START_VERB)) -> WakeCommand.START
      n.contains("$WAKE $STOP_VERB") || (n.contains(WAKE) && n.contains(STOP_VERB)) -> WakeCommand.STOP
      else -> null
    }
  }

  private fun normalize(s: String): String {
    val lower = s.trim().lowercase()
    val decomposed = Normalizer.normalize(lower, Normalizer.Form.NFD)
    return decomposed.replace(Regex("\\p{Mn}+"), "").replace(Regex("\\s+"), " ")
  }
}
```

- [ ] **Step 5: Rodar o teste (green)**

```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:testDebugUnitTest --tests "*VoiceCommandParserTest*"
```
Expected: PASS (5 testes). Se não houver test source set configurado no `build.gradle.kts`, adicionar `testImplementation("junit:junit:4.13.2")` (dep de teste, não runtime — não exige ADR pois é infra de teste, mesma classe do que a Fatia 1 evitou; se o projeto não tiver test source set Kotlin, usar a rota de compilação-só e validar a lógica por inspeção + device).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/VoiceCommandParser.kt apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/voice/VoiceCommandParserTest.kt
git commit -m "feat(voice): VoiceCommandParser raro gravar/parar (porta do parser swift)"
```

---

### Task 4: `ForegroundVoiceRecognizer` — SpeechRecognizer on-device, restart-loop

Foreground (app visível). `SpeechRecognizer` on-device contínuo com restart-loop; NÃO reciclar por erro benigno de silêncio (`ERROR_NO_MATCH`/`ERROR_SPEECH_TIMEOUT`) — restart limpo esperado, contado em log (anti-lição iOS, memória `raro-pattern-sfspeech-continuous-no-recycle-per-error`).

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/ForegroundVoiceRecognizer.kt`

**Interfaces:**
- Consumes: `VoiceCommandParser.parse` (Task 3).
- Produces: `class ForegroundVoiceRecognizer(context, onCommand: (WakeCommand)->Unit, onState: (VoiceListeningState)->Unit)` com `fun start()`, `fun stop()`, `fun isAvailable(): Boolean`. Task 6 (HostApi) consome.

- [ ] **Step 1: Implementar `ForegroundVoiceRecognizer.kt`**

(Detalhamento completo do restart-loop, `RecognitionListener`, tratamento de `onResults`/`onPartialResults` → `parse` → `onCommand`, e o gate de erro benigno. Ver corpo abaixo.)

```kotlin
package com.rarocamera.raro_mobile.voice

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.rarocamera.raro_mobile.generated.voice.VoiceListeningState
import com.rarocamera.raro_mobile.generated.voice.WakeCommand

class ForegroundVoiceRecognizer(
  private val context: Context,
  private val onCommand: (WakeCommand) -> Unit,
  private val onState: (VoiceListeningState) -> Unit,
) {
  private var recognizer: SpeechRecognizer? = null
  private var running = false
  private var benignRestarts = 0

  fun isAvailable(): Boolean =
    SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

  fun start() {
    if (running) return
    if (!isAvailable()) {
      onState(VoiceListeningState.UNAVAILABLE)
      return
    }
    running = true
    launchSession()
  }

  fun stop() {
    running = false
    recognizer?.destroy()
    recognizer = null
    onState(VoiceListeningState.IDLE)
  }

  private fun launchSession() {
    if (!running) return
    recognizer?.destroy()
    val r = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
    r.setRecognitionListener(listener)
    recognizer = r
    r.startListening(recognizeIntent())
    onState(VoiceListeningState.LISTENING)
  }

  private fun recognizeIntent(): Intent =
    Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
      putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
    }

  private fun handleTranscripts(bundle: Bundle?) {
    val hits = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION) ?: return
    for (t in hits) {
      val cmd = VoiceCommandParser.parse(t)
      if (cmd != null) {
        Log.i(TAG, "wake matched: $t -> $cmd")
        onCommand(cmd)
        return
      }
    }
  }

  private val listener = object : RecognitionListener {
    override fun onResults(results: Bundle?) {
      handleTranscripts(results)
      relaunch("results")
    }

    override fun onPartialResults(partialResults: Bundle?) {
      handleTranscripts(partialResults)
    }

    override fun onError(error: Int) {
      if (error == SpeechRecognizer.ERROR_NO_MATCH ||
        error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT
      ) {
        benignRestarts++
        Log.d(TAG, "benign error=$error, restarting (count=$benignRestarts)")
        relaunch("benign")
        return
      }
      Log.w(TAG, "recognizer error=$error")
      relaunch("error")
    }

    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
  }

  private fun relaunch(reason: String) {
    if (!running) return
    launchSession()
  }

  private companion object {
    const val TAG = "RaroVoice"
  }
}
```

- [ ] **Step 2: Compilar**

```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/ForegroundVoiceRecognizer.kt
git commit -m "feat(voice): ForegroundVoiceRecognizer on-device com restart-loop (sem reciclo por silencio benigno)"
```

---

### Task 5: `WakeEngine` + `VoskWakeEngine` + `VoiceBackgroundService` (FGS microphone)

Background. Interface `WakeEngine` trocável; `VoskWakeEngine` (`AudioRecord` 16kHz mono → Vosk `Recognizer`); `VoiceBackgroundService` (FGS type=microphone, notificação fixa). Registrar o `<service>` no manifest AGORA (Task 2 Step 3 adiou).

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/WakeEngine.kt` (interface)
- Create: `.../voice/VoskWakeEngine.kt`
- Create: `.../voice/VoiceBackgroundService.kt`
- Modify: `AndroidManifest.xml` (adicionar o `<service>` adiado)

**Interfaces:**
- Consumes: `VoiceCommandParser.parse`, Vosk `Model`/`Recognizer`.
- Produces: `interface WakeEngine { fun start(onCommand:(WakeCommand)->Unit); fun stop() }`; `VoskWakeEngine(context)`; `VoiceBackgroundService` (start/stop via `Intent`).

- [ ] **Step 1: `WakeEngine.kt` (interface trocável Vosk→Sensory)**

```kotlin
package com.rarocamera.raro_mobile.voice

import com.rarocamera.raro_mobile.generated.voice.WakeCommand

interface WakeEngine {
  fun start(onCommand: (WakeCommand) -> Unit)
  fun stop()
}
```

- [ ] **Step 2: `VoskWakeEngine.kt` — AudioRecord 16kHz mono → Vosk**

```kotlin
package com.rarocamera.raro_mobile.voice

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import com.rarocamera.raro_mobile.generated.voice.WakeCommand
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import kotlin.concurrent.thread

class VoskWakeEngine(private val context: Context) : WakeEngine {
  private var model: Model? = null
  private var record: AudioRecord? = null
  @Volatile private var running = false

  @SuppressLint("MissingPermission")
  override fun start(onCommand: (WakeCommand) -> Unit) {
    if (running) return
    val modelDir = ensureModelUnpacked()
    val m = Model(modelDir.absolutePath)
    model = m
    val recognizer = Recognizer(m, SAMPLE_RATE.toFloat())

    val minBuf = AudioRecord.getMinBufferSize(
      SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
    )
    val bufSize = maxOf(minBuf, SAMPLE_RATE) // >=1s
    val rec = AudioRecord(
      MediaRecorder.AudioSource.VOICE_RECOGNITION,
      SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufSize,
    )
    if (rec.state != AudioRecord.STATE_INITIALIZED) {
      Log.w(TAG, "AudioRecord nao inicializou")
      rec.release()
      recognizer.close()
      m.close()
      return
    }
    record = rec
    running = true
    rec.startRecording()

    thread(name = "vosk-wake") {
      val buffer = ShortArray(bufSize)
      while (running) {
        val n = rec.read(buffer, 0, buffer.size)
        if (n > 0) {
          if (recognizer.acceptWaveForm(buffer, n)) {
            emitIfMatch(recognizer.result, onCommand)
          } else {
            emitIfMatch(recognizer.partialResult, onCommand)
          }
        }
      }
      recognizer.close()
    }
  }

  private fun emitIfMatch(json: String, onCommand: (WakeCommand) -> Unit) {
    val text = runCatching {
      val obj = JSONObject(json)
      obj.optString("text").ifEmpty { obj.optString("partial") }
    }.getOrDefault("")
    if (text.isBlank()) return
    val cmd = VoiceCommandParser.parse(text) ?: return
    Log.i(TAG, "vosk wake matched: $text -> $cmd")
    onCommand(cmd)
  }

  override fun stop() {
    running = false
    record?.let {
      runCatching { it.stop() }
      it.release()
    }
    record = null
    model?.close()
    model = null
  }

  private fun ensureModelUnpacked(): File {
    val dest = File(context.filesDir, MODEL_DIR)
    if (dest.exists() && File(dest, "am").exists()) return dest
    dest.mkdirs()
    copyAssetDir(MODEL_DIR, dest)
    return dest
  }

  private fun copyAssetDir(assetPath: String, dest: File) {
    val assets = context.assets
    val children = assets.list(assetPath) ?: emptyArray()
    if (children.isEmpty()) {
      assets.open(assetPath).use { input ->
        dest.outputStream().use { input.copyTo(it) }
      }
      return
    }
    dest.mkdirs()
    for (child in children) {
      copyAssetDir("$assetPath/$child", File(dest, child))
    }
  }

  private companion object {
    const val TAG = "RaroVoice"
    const val SAMPLE_RATE = 16000
    const val MODEL_DIR = "vosk-model-small-pt-0.3"
  }
}
```

- [ ] **Step 3: `VoiceBackgroundService.kt` — FGS microphone + notificação**

```kotlin
package com.rarocamera.raro_mobile.voice

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class VoiceBackgroundService : Service() {
  private var engine: WakeEngine? = null

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    startAsForeground()
    val e = VoskWakeEngine(applicationContext)
    engine = e
    e.start { command ->
      commandListener?.invoke(command)
    }
    Log.i(TAG, "voice background service started")
    return START_STICKY
  }

  private fun startAsForeground() {
    val channelId = ensureChannel()
    val notification: Notification = NotificationCompat.Builder(this, channelId)
      .setContentTitle("Raro")
      .setContentText("Escuta em segundo plano ativa")
      .setSmallIcon(applicationInfo.icon)
      .setOngoing(true)
      .build()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
    } else {
      startForeground(NOTIF_ID, notification)
    }
  }

  private fun ensureChannel(): String {
    val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val channel = NotificationChannel(
      CHANNEL_ID, "Escuta de voz", NotificationManager.IMPORTANCE_LOW,
    )
    mgr.createNotificationChannel(channel)
    return CHANNEL_ID
  }

  override fun onDestroy() {
    engine?.stop()
    engine = null
    Log.i(TAG, "voice background service stopped")
    super.onDestroy()
  }

  companion object {
    private const val TAG = "RaroVoice"
    private const val CHANNEL_ID = "raro_voice_bg"
    private const val NOTIF_ID = 4243
    var commandListener: ((com.rarocamera.raro_mobile.generated.voice.WakeCommand) -> Unit)? = null

    fun start(context: Context) {
      val intent = Intent(context, VoiceBackgroundService::class.java)
      context.startForegroundService(intent)
    }

    fun stop(context: Context) {
      context.stopService(Intent(context, VoiceBackgroundService::class.java))
    }
  }
}
```

- [ ] **Step 4: Registrar o `<service>` no manifest**

Adicionar o bloco `<service>` adiado da Task 2 Step 3 (dentro de `<application>`).

- [ ] **Step 5: Compilar**

```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL (Vosk `Model`/`Recognizer` resolvem).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/WakeEngine.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/VoskWakeEngine.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/VoiceBackgroundService.kt apps/mobile/android/app/src/main/AndroidManifest.xml
git commit -m "feat(voice): wakeengine + voskwakeengine + fgs microphone service"
```

---

### Task 6: `VoiceHostApiImpl` + registro no MainActivity + handoff foreground/background

Cola tudo: `VoiceHostApiImpl` implementa o Pigeon, roteia foreground↔background, registra no `MainActivity`. Handoff: app visível → `ForegroundVoiceRecognizer`; toggle ON + minimizado → `VoiceBackgroundService`. Nunca os dois juntos.

**Files:**
- Create: `.../voice/VoiceHostApiImpl.kt`
- Modify: `MainActivity.kt` (registrar `VoiceHostApi.setUp` + `VoiceFlutterApi`)

**Interfaces:**
- Consumes: `ForegroundVoiceRecognizer` (Task 4), `VoiceBackgroundService` (Task 5), gerado `VoiceHostApi`/`VoiceFlutterApi`/`WakeCommand`/`VoiceListeningState`.
- Produces: `VoiceHostApiImpl(context, flutterApi)` registrada; `isAvailable`/`startListening`/`stopListening` funcionais; eventos `onWakeDetected`/`onListeningStateChanged` chegam ao Dart.

- [ ] **Step 1: Implementar `VoiceHostApiImpl.kt`**

```kotlin
package com.rarocamera.raro_mobile.voice

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.SpeechRecognizer
import com.rarocamera.raro_mobile.generated.voice.VoiceFlutterApi
import com.rarocamera.raro_mobile.generated.voice.VoiceHostApi
import com.rarocamera.raro_mobile.generated.voice.VoiceListeningState
import com.rarocamera.raro_mobile.generated.voice.WakeCommand

class VoiceHostApiImpl(
  private val context: Context,
  private val flutterApi: VoiceFlutterApi,
) : VoiceHostApi {
  private val main = Handler(Looper.getMainLooper())
  private val foreground = ForegroundVoiceRecognizer(
    context,
    onCommand = { cmd -> emitCommand(cmd) },
    onState = { state -> emitState(state) },
  )

  init {
    VoiceBackgroundService.commandListener = { cmd -> emitCommand(cmd) }
  }

  override fun isAvailable(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(foreground.isAvailable()))
  }

  override fun startListening() {
    main.post { foreground.start() }
  }

  override fun stopListening() {
    main.post { foreground.stop() }
  }

  private fun emitCommand(cmd: WakeCommand) {
    main.post { flutterApi.onWakeDetected(cmd) {} }
  }

  private fun emitState(state: VoiceListeningState) {
    main.post { flutterApi.onListeningStateChanged(state) {} }
  }
}
```

NOTA: o handoff automático foreground↔background por ciclo de vida da Activity (onStop/onStart) + toggle de Settings é o ponto mais sutil. Para esta fatia, `startListening`/`stopListening` controlam o foreground; o background é acionado pelo toggle de Settings via um caminho a definir no Step 3 (o toggle Dart chama um método — mas o contrato Pigeon não tem "startBackground"). DECISÃO: o toggle de Settings persiste a preferência; quando o app vai a background COM a preferência ON e a escuta ativa, o `MainActivity.onStop` inicia o FGS. Detalhar no Step 3.

- [ ] **Step 2: Registrar no MainActivity**

Em `configureFlutterEngine`, após o bloco da câmera:

```kotlin
    val voiceFlutterApi = com.rarocamera.raro_mobile.generated.voice.VoiceFlutterApi(messenger)
    val voiceHostApi = com.rarocamera.raro_mobile.voice.VoiceHostApiImpl(applicationContext, voiceFlutterApi)
    com.rarocamera.raro_mobile.generated.voice.VoiceHostApi.setUp(messenger, voiceHostApi)
```

- [ ] **Step 3: Handoff foreground↔background via ciclo de vida**

Em `MainActivity`, guardar referência ao `VoiceHostApiImpl` e à preferência de background (lida via `SharedPreferences` — a mesma chave que o Settings Dart persiste, memória `raro-pattern-single-source-of-truth-persisted-settings`). Em `onStop()`: se a escuta está ativa E o toggle background ON → `foreground.stop()` + `VoiceBackgroundService.start(this)`. Em `onStart()`: se o serviço está ativo → `VoiceBackgroundService.stop(this)` + `foreground.start()`. Detalhar a chave exata lendo o Settings Dart (`features/settings` + `raro_shared`). NÃO os dois capturando juntos.

(Como a chave de preferência e o wiring do Settings Dart dependem de leitura do código existente, este step exige inspecionar `features/settings` antes de escrever — segue o padrão do plano de nunca inventar chave.)

- [ ] **Step 4: Compilar + regenerar Pigeon se necessário (NÃO — contrato inalterado, só implementar o gerado)**

```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/voice/VoiceHostApiImpl.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt
git commit -m "feat(voice): voicehostapiimpl + registro no mainactivity + handoff foreground/background"
```

---

### Task 7: Analyze + suíte Dart + prova no device (DoD)

**Files:** (nenhum — verificação)

- [ ] **Step 1: analyze + suíte Dart**

```bash
bun run --filter '@raro/mobile' analyze
bun run --filter '@raro/mobile' test
```
Expected: `No issues found!` + 331 verdes (baseline). O Dart consumidor de voz já existe; confirmar que a implementação nativa não exigiu mudança Dart.

- [ ] **Step 2: DoD no M54 — foreground**

App aberto: "raro gravar" inicia gravação real (Fatia 1), "raro parar" finaliza. 5/5 detecções em logcat (`adb logcat -s RaroVoice`). Contar `wake matched` (start E stop). Reciclos benignos « N (não loop 6x/s).

- [ ] **Step 3: DoD no M54 — background**

Toggle "Escuta em segundo plano" ON, minimizar o app: comandos funcionam via FGS + Vosk. Notificação fixa visível. Tela desligada: idem (ressalva OEM). Desligar o toggle mata o serviço.

- [ ] **Step 4: Prova de install fresco ANTES de pedir teste** (memória `feedback_verify_device_install_before_test`): ler `Success` do `adb install` + confirmar binário novo.

- [ ] **Step 5: finishing-a-development-branch**

Após DoDs verdes + auditoria adversarial 3-lentes (como Fatia 1/2): usar `superpowers:finishing-a-development-branch`. PR pra develop. ADR-0029 já commitado.

---

## Notas de execução

- **Spike-gate é BLOQUEANTE** (Task 1). Se pt-BR on-device ausente no M54, Task 4 muda (Vosk no foreground também).
- **FGS while-in-use:** o serviço SÓ inicia com app visível (Task 6 Step 3 parte de `onStop` com o app ainda em foreground na transição). NUNCA iniciar de BOOT/background.
- **Não reciclar por silêncio benigno** (`ERROR_NO_MATCH`/`ERROR_SPEECH_TIMEOUT`) — restart limpo, contado em log. Métrica = contagem de detecções (memória `raro-pattern-sfspeech-continuous-no-recycle-per-error`).
- **Vosk 0.3.47** (não 0.3.50). Modelo 31MB em assets, descompactado para `filesDir` no 1º uso.
- **Handoff:** nunca foreground + background capturando juntos.
- **Auditoria adversarial** antes do PR (padrão Fatia 1/2): silent-failure + lifecycle + contract-drift + thread-safety.
- **Chave de preferência do toggle:** LER `features/settings` + `raro_shared` antes de escrever o Step 3 da Task 6 — nunca inventar.
