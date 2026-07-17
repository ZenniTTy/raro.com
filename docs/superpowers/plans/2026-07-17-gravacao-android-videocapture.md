# Gravação Android (CameraX VideoCapture) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir os stubs `startRecording`/`stopRecording` no Android por gravação MP4 real (com áudio) via CameraX, resolvendo o "Falha ao gravar" do Galaxy M54 e habilitando o comando de voz da Fatia 3.

**Architecture:** O Kotlin ganha um `RecordingController` que grava um `.mp4` cru num arquivo temporário via `VideoCapture<Recorder>` e reporta ciclo de vida pelos callbacks Pigeon já existentes (`onRecordingStarted/Finished/Failed`). O vault, o sidecar JSON atômico e o thumbnail já são responsabilidade do Dart (`VaultService`/`recordingVaultSink`) — o nativo só produz o arquivo e devolve o path. `bindIfReady` passa a bindar `Preview + VideoCapture` juntos.

**Tech Stack:** Kotlin, CameraX (`androidx.camera:camera-video:1.6.1`), Pigeon (contrato inalterado), `MediaMetadataRetriever` (thumbnail), Robolectric/JUnit para teste unitário Kotlin onde couber, prova de device via `adb` + `ffprobe`.

## Global Constraints

- **Zero mudança de contrato Pigeon.** `startRecording(RecordingOptions): String`, `stopRecording()`, `onRecordingStarted(String)`, `onRecordingFinished(String path, int durationMs)`, `onRecordingFailed(CameraErrorCode, String?)` já existem em `apps/mobile/pigeons/camera_api.dart` — só implementar.
- **Zero `.swift`, zero regen Pigeon, zero Dart de produção** (o Dart já consome os callbacks; só testes Dart se necessário).
- **ADR-0030 mergeado ANTES do código de dependência** (regra "mudou dep = ADR antes"). `androidx.camera:camera-video` é artefato Maven novo. O ADR atualiza o Blueprint (encoding linear Android = CameraX Recorder; replay = MediaCodec).
- **Áudio obrigatório** (`withAudioEnabled()`), senão MP4 mudo — mesmo bug do iOS.
- **Nome do arquivo temp = `raro_<sessionId>.mp4`** — `_idFromPath` (`camera_flutter_api_provider.dart:117`) remove o prefixo `raro_`. Nome errado = id errado no vault.
- **Sem fallback silencioso de formato** (gate §10): qualidade efetiva negociada pelo CameraX é logada; `includeReplayPreroll=true` é ignorado com `Log.w` explícito.
- **Preservar `bindIfReady` da sessão 0036**: surface antes do bind (memória `raro-pattern-android-camerax-surface-bind-race-on-return`).
- Wake word "Raro", trial 30d, planos, bundle `com.rarocamera` — não tocados.

---

### Task 1: ADR-0030 (dependência camera-video + atualização do Blueprint)

**Files:**
- Create: `docs/decisions/0030-gravacao-android-camerax-videocapture.md`
- Modify: `docs/Blueprint.md` (linha ~55, tabela/texto de encoding Android)

**Interfaces:**
- Produces: decisão registrada que autoriza `androidx.camera:camera-video` e reconcilia o Blueprint. Nenhum símbolo de código.

- [ ] **Step 1: Escrever o ADR** seguindo o formato dos ADRs existentes (ver `docs/decisions/0018-recording-pipeline-mp4.md` e `0027`). Conteúdo mínimo:
  - **Data:** 2026-07-17 · **Status:** Accepted · **Decisores:** Eduardo Rodrigues
  - **Contexto:** Fatia 1 pré-APK; Android grava via stub; Blueprint linha 55 fixa `MediaCodec`+`MediaMuxer`.
  - **Opções:** (1) CameraX `VideoCapture<Recorder>` — mux interno, áudio e negociação de formato prontos, mínimo código; (2) `MediaCodec`+`MediaMuxer` — controle total, obrigatório para replay/buffer circular, muito mais código para gravação linear; (3) status quo (stub).
  - **Decisão:** Opção 1 para gravação LINEAR. `MediaCodec`+`MediaMuxer` fica RESERVADO ao replay buffer (fatia futura, memória `raro-pattern-android-mediacodec-buffer-management`). Adiciona `androidx.camera:camera-video:1.6.1` (mesma família/versão dos artefatos presentes).
  - **Consequências:** atualiza o Blueprint; `includeReplayPreroll` ignorado nesta fatia; paridade de gravação linear com o iOS (ADR-0018/0020, também `.mp4`).
  - Referenciar ADR-0018/0020 (estratégia MP4 iOS) e a spec `docs/superpowers/specs/2026-07-17-gravacao-android-videocapture-design.md`.
- [ ] **Step 2: Atualizar o Blueprint** na linha de encoding Android: de `MediaCodec + MediaMuxer para encoding + buffer` para algo como `Gravação linear: CameraX VideoCapture<Recorder> (ADR-0030). Replay/pré-roll buffer: MediaCodec + MediaMuxer (fatia futura).`
- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0030-gravacao-android-camerax-videocapture.md docs/Blueprint.md
git commit -m "docs(decisions): adr-0030 gravacao android camerax videocapture + atualiza blueprint"
```

---

### Task 2: Adicionar dependência camera-video + permissão de áudio

**Files:**
- Modify: `apps/mobile/android/app/build.gradle.kts:49-54` (bloco `dependencies`)
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml` (garantir `RECORD_AUDIO`)

**Interfaces:**
- Produces: classes `androidx.camera.video.{VideoCapture, Recorder, Recording, PendingRecording, QualitySelector, Quality, FileOutputOptions, VideoRecordEvent}` disponíveis no classpath.

- [ ] **Step 1: Adicionar a dependência.** Em `build.gradle.kts`, no bloco `dependencies`, após a linha `camera-view`:

```kotlin
dependencies {
    implementation("androidx.camera:camera-core:1.6.1")
    implementation("androidx.camera:camera-camera2:1.6.1")
    implementation("androidx.camera:camera-lifecycle:1.6.1")
    implementation("androidx.camera:camera-view:1.6.1")
    implementation("androidx.camera:camera-video:1.6.1")
}
```

- [ ] **Step 2: Confirmar `RECORD_AUDIO` no manifest.** Ler `apps/mobile/android/app/src/main/AndroidManifest.xml`. Se `<uses-permission android:name="android.permission.RECORD_AUDIO" />` não existir, adicionar junto a `CAMERA`. (O onboarding já pede o runtime grant; aqui é só a declaração.)

- [ ] **Step 3: Verificar que compila.**

Run:
```bash
cd apps/mobile/android && ./gradlew :app:compileDebugKotlin
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/android/app/build.gradle.kts apps/mobile/android/app/src/main/AndroidManifest.xml
git commit -m "build(android): adiciona camera-video 1.6.1 + record_audio para gravacao"
```

---

### Task 3: RecordingController — gravar MP4 temp e reportar ciclo de vida

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/RecordingController.kt`
- Test: `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/RecordingControllerTest.kt`

**Interfaces:**
- Consumes: `context: Context`, um `VideoCapture<Recorder>` fornecido pelo `CameraManager` (Task 4), e `Executor` main.
- Produces:
  - `class RecordingController(context, mainExecutor)`
  - `fun tempFileFor(sessionId: String): File` → `File(context.cacheDir, "raro_$sessionId.mp4")`
  - `fun start(videoCapture, sessionId, callbacks)` inicia a gravação
  - `fun stop()` finaliza
  - `fun isRecording(): Boolean`
  - `interface RecordingCallbacks { fun onStarted(sessionId); fun onFinished(path, durationMs); fun onFailed(code: CameraErrorCode, message: String?) }`

- [ ] **Step 1: Escrever o teste do naming/estado (a parte testável sem device).** `RecordingControllerTest.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RecordingControllerTest {
  private val context: Context = ApplicationProvider.getApplicationContext()

  @Test
  fun tempFile_uses_raro_prefix_so_dart_id_parsing_matches() {
    val controller = RecordingController(context) { it.run() }
    val file = controller.tempFileFor("abc123")
    assertEquals("raro_abc123.mp4", file.name)
  }

  @Test
  fun isRecording_false_before_start() {
    val controller = RecordingController(context) { it.run() }
    assertFalse(controller.isRecording())
  }
}
```

- [ ] **Step 2: Rodar o teste e ver falhar** (classe não existe).

Run:
```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest --tests "*RecordingControllerTest*"
```
Expected: FAIL — `Unresolved reference: RecordingController`. (Se Robolectric não estiver no projeto, ver nota no fim da task.)

- [ ] **Step 3: Implementar o `RecordingController`.**

```kotlin
package com.rarocamera.raro_mobile.camera

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.video.Recorder
import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode
import java.io.File
import java.util.concurrent.Executor

private const val TAG = "RaroRecording"

class RecordingController(
  private val context: Context,
  private val mainExecutor: Executor,
) {
  interface RecordingCallbacks {
    fun onStarted(sessionId: String)
    fun onFinished(path: String, durationMs: Long)
    fun onFailed(code: CameraErrorCode, message: String?)
  }

  private var recording: Recording? = null

  fun isRecording(): Boolean = recording != null

  fun tempFileFor(sessionId: String): File = File(context.cacheDir, "raro_$sessionId.mp4")

  @SuppressLint("MissingPermission")
  fun start(
    videoCapture: VideoCapture<Recorder>,
    sessionId: String,
    callbacks: RecordingCallbacks,
  ) {
    if (recording != null) {
      callbacks.onFailed(CameraErrorCode.ALREADY_RUNNING, "recording already in progress")
      return
    }
    val target = tempFileFor(sessionId)
    val outputOptions = FileOutputOptions.Builder(target).build()
    recording = videoCapture.output
      .prepareRecording(context, outputOptions)
      .withAudioEnabled()
      .start(mainExecutor) { event ->
        when (event) {
          is VideoRecordEvent.Start -> callbacks.onStarted(sessionId)
          is VideoRecordEvent.Finalize -> {
            val current = recording
            recording = null
            if (event.hasError()) {
              Log.w(TAG, "recording finalize error code=${event.error}", event.cause)
              callbacks.onFailed(
                CameraErrorCode.SESSION_FAILED,
                "recording failed error=${event.error}",
              )
            } else {
              val durationMs = event.recordingStats.recordedDurationNanos / 1_000_000
              callbacks.onFinished(target.absolutePath, durationMs)
            }
          }
          else -> Unit
        }
      }
  }

  fun stop() {
    recording?.stop()
  }
}
```

- [ ] **Step 4: Rodar o teste e ver passar.**

Run:
```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest --tests "*RecordingControllerTest*"
```
Expected: PASS (2 testes).

> **Nota Robolectric:** se `org.robolectric:robolectric` não estiver em `build.gradle.kts` `testImplementation`, os testes de `RecordingController` que precisam de `Context` não rodam. Nesse caso: (a) adicionar `testImplementation("org.robolectric:robolectric:4.13")` + `testImplementation("androidx.test:core:1.6.1")` no bloco de deps de teste E `testOptions { unitTests.isIncludeAndroidResources = true }` no `android {}`, OU (b) se o projeto não tem infra de teste Kotlin nativo, refatorar `tempFileFor` para função pura `fun raroTempName(sessionId: String) = "raro_$sessionId.mp4"` testável sem `Context` e testar só ela. Escolher (b) se (a) exigir mudar a stack de build (então é ADR). Verificar `ls apps/mobile/android/app/src/test` antes.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/RecordingController.kt apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/RecordingControllerTest.kt
git commit -m "feat(android): recordingcontroller grava mp4 temp com audio via camerax"
```

---

### Task 4: CameraManager binda VideoCapture + expõe start/stop

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`

**Interfaces:**
- Consumes: `RecordingController` (Task 3), `buildPreview` existente.
- Produces:
  - `fun startRecording(options: RecordingOptions, callbacks: RecordingController.RecordingCallbacks): String` (gera e retorna sessionId)
  - `fun stopRecording()`
  - `bindIfReady` passa a bindar `Preview + VideoCapture` juntos.

- [ ] **Step 1: Adicionar campos e helper de VideoCapture.** No topo da classe `CameraManager` (após `private var preview`):

```kotlin
  private var videoCapture: VideoCapture<Recorder>? = null
  private val recordingController = RecordingController(context, ContextCompat.getMainExecutor(context))
```

E os imports necessários no topo do arquivo:

```kotlin
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.VideoCapture
import java.util.UUID
```

- [ ] **Step 2: Construir o VideoCapture derivado do formato.** Adicionar método privado:

```kotlin
  private fun buildVideoCapture(resolution: Resolution): VideoCapture<Recorder> {
    val quality = when (resolution) {
      Resolution.UHD4K -> Quality.UHD
      Resolution.FHD1080 -> Quality.FHD
      Resolution.HD720 -> Quality.HD
    }
    val recorder = Recorder.Builder()
      .setQualitySelector(
        QualitySelector.fromOrderedList(listOf(quality, Quality.FHD, Quality.HD)),
      )
      .build()
    return VideoCapture.withOutput(recorder)
  }
```

- [ ] **Step 3: Bindar Preview + VideoCapture juntos no `bindIfReady`.** Substituir o corpo do `try` em `bindIfReady` (`CameraManager.kt:103-110`) por:

```kotlin
    try {
      p.unbindAll()
      val selector = CameraLensDiscovery.selectorFor(p, config.lens)
      val pv = buildPreview(config.resolution, config.fps)
      pv.setSurfaceProvider(sp)
      val vc = buildVideoCapture(config.resolution)
      camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
      preview = pv
      videoCapture = vc
      currentConfig = config
    } catch (e: CameraNativeException) {
      throw e
    } catch (e: Throwable) {
      Log.w(TAG, "bindIfReady failed", e)
      throw CameraNativeException.SessionFailed(e.message ?: e.javaClass.simpleName)
    }
```

> Aplicar o MESMO padrão de bind (adicionar `vc`) em `switchLens` (`:127-138`) e `setFormat` (`:140-150`) para não perder a gravação ao trocar lente/formato. Em cada um: `val vc = buildVideoCapture(<resolution>)`, incluir `vc` no `bindToLifecycle`, e `videoCapture = vc`. Em `stopSession` (`:119-125`) adicionar `videoCapture = null`.

- [ ] **Step 4: Expor start/stop.** Adicionar à classe:

```kotlin
  fun startRecording(
    options: RecordingOptions,
    callbacks: RecordingController.RecordingCallbacks,
  ): String {
    val vc = videoCapture ?: throw CameraNativeException.NotRunning
    if (options.includeReplayPreroll) {
      Log.w(TAG, "includeReplayPreroll ignored on Android (replay buffer is a future slice)")
    }
    val sessionId = UUID.randomUUID().toString()
    recordingController.start(vc, sessionId, callbacks)
    return sessionId
  }

  fun stopRecording() {
    if (!recordingController.isRecording()) throw CameraNativeException.NotRunning
    recordingController.stop()
  }
```

- [ ] **Step 5: Verificar compilação.**

Run:
```bash
cd apps/mobile/android && ./gradlew :app:compileDebugKotlin
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt
git commit -m "feat(android): cameramanager binda videocapture e expoe start/stop recording"
```

---

### Task 5: Ligar HostApi — remover os stubs

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt:91-105`

**Interfaces:**
- Consumes: `manager.startRecording(options, callbacks)`, `manager.stopRecording()`, `flutterApi.onRecordingStarted/Finished/Failed`.
- Produces: implementação real de `startRecording`/`stopRecording` do contrato Pigeon.

- [ ] **Step 1: Substituir os dois stubs.** Trocar `startRecording`/`stopRecording` (`:91-105`) por:

```kotlin
  override fun startRecording(options: RecordingOptions): String {
    try {
      return manager.startRecording(
        options,
        object : RecordingController.RecordingCallbacks {
          override fun onStarted(sessionId: String) {
            main.post { flutterApi.onRecordingStarted(sessionId) {} }
          }
          override fun onFinished(path: String, durationMs: Long) {
            main.post { flutterApi.onRecordingFinished(path, durationMs) {} }
          }
          override fun onFailed(code: CameraErrorCode, message: String?) {
            main.post { flutterApi.onRecordingFailed(code, message) {} }
          }
        },
      )
    } catch (e: Throwable) {
      throw toFlutterError(e)
    }
  }

  override fun stopRecording() {
    try {
      manager.stopRecording()
    } catch (e: Throwable) {
      throw toFlutterError(e)
    }
  }
```

E adicionar o import: `import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode`.

- [ ] **Step 2: Verificar compilação.**

Run:
```bash
cd apps/mobile/android && ./gradlew :app:compileDebugKotlin
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt
git commit -m "feat(android): liga startrecording/stoprecording ao cameramanager (remove stubs)"
```

---

### Task 6: Thumbnail Android (paridade de galeria)

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt` (`generateThumbnail`, `:107-117`)
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/ThumbnailExtractor.kt`

**Interfaces:**
- Consumes: `videoPath: String`.
- Produces: `fun extractFirstFrameJpeg(context, videoPath): String` (path do `.jpg` gerado ao lado do vídeo).

- [ ] **Step 1: Implementar o extractor.** `ThumbnailExtractor.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream

object ThumbnailExtractor {
  fun extractFirstFrameJpeg(context: Context, videoPath: String): String {
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(videoPath)
      val frame = retriever.getFrameAtTime(0)
        ?: throw CameraNativeException.FormatUnsupported
      val stem = File(videoPath).nameWithoutExtension
      val out = File(context.cacheDir, "$stem.jpg")
      FileOutputStream(out).use { frame.compress(Bitmap.CompressFormat.JPEG, 85, it) }
      return out.absolutePath
    } finally {
      retriever.release()
    }
  }
}
```

- [ ] **Step 2: Ligar no HostApi.** Substituir o stub `generateThumbnail` (`:107-117`) por:

```kotlin
  override fun generateThumbnail(videoPath: String, callback: (Result<String>) -> Unit) {
    try {
      callback(Result.success(ThumbnailExtractor.extractFirstFrameJpeg(context, videoPath)))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }
```

Isso exige `context` no `CameraHostApiImpl`. Se ainda não tiver, o `manager` já o tem — adicionar um getter `val context: Context get() = ...` no manager OU passar `applicationContext` ao construir o `CameraHostApiImpl` no `MainActivity.kt`. Escolher passar o context ao construtor (mais explícito): mudar a assinatura para `CameraHostApiImpl(context, manager, flutterApi)` e atualizar `MainActivity.kt`.

- [ ] **Step 3: Verificar compilação.**

Run:
```bash
cd apps/mobile/android && ./gradlew :app:compileDebugKotlin
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/ThumbnailExtractor.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt
git commit -m "feat(android): thumbnail via mediametadataretriever (paridade galeria)"
```

---

### Task 7: Prova de device (gate §10) + regressão de ciclo de vida

**Files:** nenhum (validação).

**Interfaces:** nenhuma.

- [ ] **Step 1: Confirmar install fresco ANTES de testar** (gate §10, memória `feedback_verify_device_install_before_test`).

Run:
```bash
cd apps/mobile && flutter build apk --debug && \
  adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
Expected: `Success`. Anotar timestamp.

- [ ] **Step 2: Gravar 1 clipe no M54.** Abrir o app, câmera, REC → contar ~5s → parar. Confirmar via kit adb que a UI de REC ficou ativa:

```bash
adb shell "svc power stayon usb"
adb exec-out screencap -p > /tmp/raro_rec_active.png
```

- [ ] **Step 3: Puxar o clipe do vault e provar formato+áudio com ffprobe** (gate §10). O vault fica no sandbox interno do app (`path_provider` documentsDir → `files/vault/`), acessível via `run-as`:

```bash
adb exec-out run-as com.rarocamera ls files/vault/
# pegar o <id>.mp4 mais recente e copiar:
adb exec-out run-as com.rarocamera cat files/vault/<id>.mp4 > /tmp/raro_clip.mp4
ffprobe -v error -show_entries stream=codec_type,codec_name,width,height,r_frame_rate /tmp/raro_clip.mp4
```
Expected: uma stream `video` (h264/hevc, dimensões coerentes com o formato, fps) E uma stream `audio` (aac). **Anexar a saída no PR.** Se faltar a stream de áudio → `withAudioEnabled` não pegou (bug), não fechar a task.

- [ ] **Step 4: Confirmar galeria.** No app, abrir a galeria: o clipe aparece com thumbnail (não só cor) e reproduz.

- [ ] **Step 5: Regressão de ciclo de vida (sessão 0036).** Com a câmera ociosa (não gravando), ir em Configurações e voltar. A câmera deve reaparecer viva (o `bindIfReady` agora binda 2 use cases; provar que não regrediu). Gravar 1 clipe após o retorno.

- [ ] **Step 6: Suíte Dart + analyze verdes.**

Run:
```bash
cd apps/mobile && bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test
```
Expected: analyze limpo; suíte verde (citar total).

- [ ] **Step 7: Abrir PR** com: saída do ffprobe (vídeo+áudio), screencap da UI de REC, confirmação do install fresco (timestamp/UUID), nota de regressão de ciclo de vida OK. ADR-0030 já mergeado (Task 1).

---

## Notas de execução

- **Ordem de merge:** Task 1 (ADR) PRIMEIRO e idealmente mergeado antes das tasks de código (regra "dep = ADR antes"). As demais podem ir no mesmo PR de código, com o ffprobe no corpo.
- **Se o `./gradlew` não existir** em `apps/mobile/android`, usar o wrapper do projeto ou `bun run --filter '@raro/mobile'` scripts equivalentes — verificar `apps/mobile/package.json` antes.
- **4K60 (`requiresPhysicalLens`)**: o `QualitySelector.fromOrderedList` cai de UHD para FHD/HD se o device não suportar — logado, não silencioso. O M54 pode não ter UHD60; a prova ffprobe registra o que saiu de verdade.
- **Não tocar** replay buffer, voz, foco, i18n — fatias separadas.
