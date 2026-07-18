# Tap-to-focus Android Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or superpowers:subagent-driven-development) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No M54, tocar na preview move o foco no ponto tocado, mostra um ring nativo, e o `onFocusChanged` só reporta `locked=true` quando o foco realmente conclui.

**Architecture:** O toque é capturado NO NATIVO (`CameraPlatformView.kt`) via `GestureDetector.onSingleTapUp` no `previewView.setOnTouchListener` — obrigatório porque com `EagerGestureRecognizer` o Flutter pai nunca recebe o tap (memória `raro-pattern-flutter-platformview-tap-must-be-native`). O `PreviewView.meteringPointFactory` (compensa rotação/crop/scale) constrói o `MeteringPoint`; a `CameraManager` executa `startFocusAndMetering` e reporta o resultado real via callback. Um ring `View` overlay leve espelha o timing do iOS (`FocusRingConfig`). O caminho Pigeon `focusAt(FocusPoint)` (coordenadas normalizadas) fica intacto e separado do tap nativo em pixel.

**Tech Stack:** Kotlin, CameraX (`camera-core` já presente — `PreviewView`, `MeteringPointFactory`, `FocusMeteringAction`, `startFocusAndMetering`, `FocusMeteringResult`), `ViewPropertyAnimator` para o ring, `ContextCompat.getMainExecutor` para o listener do `ListenableFuture`.

## Global Constraints

- Wake word = `"Raro"` (invariante; não tocado aqui).
- Bundle `com.rarocamera`; `namespace` Kotlin `com.rarocamera.raro_mobile`.
- Method Channels namespace `com.rarocamera/<feature>`.
- **Sem mudança de contrato Pigeon** (`apps/mobile/pigeons/camera_api.dart` inalterado) e **sem tocar `.swift`** — Fatia 2 é Android-only.
- Kotlin: ktlint default; sem swallow de erro (sempre `Log.w`/rethrow com contexto).
- Sem comentários explicando WHAT em produção.
- Build Android: `JAVA_HOME` = JBR 21 do Android Studio (Homebrew JDK 26 quebra o Kotlin/AGP).
- Cor do ring = branco (`FocusRingConfig.color = .white` no iOS); espelhar. Não introduzir hex fora de recurso.

---

### Task 1: `CameraManager.focusAtMeteringPoint` — foco por MeteringPoint com resultado honesto

O tap nativo precisa de um caminho que aceite um `MeteringPoint` já construído pelo `previewView.meteringPointFactory` (o factory do PreviewView compensa rotação/crop/scale — `SurfaceOrientedMeteringPointFactory(1f,1f)` do `focusAt` normalizado NÃO faz isso). Este método também expõe o `FocusMeteringResult.isFocusSuccessful` real via callback, para o HostApi parar de mentir `locked=true`.

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt` (adicionar método perto de `focusAt`, ~linha 198)

**Interfaces:**
- Consumes: campo existente `camera: Camera?`; `CameraNativeException.NotRunning`.
- Produces: `fun focusAtMeteringPoint(point: MeteringPoint, onResult: (Boolean) -> Unit)` — executa `startFocusAndMetering`, adiciona listener ao `ListenableFuture<FocusMeteringResult>` no main executor, chama `onResult(result.isFocusSuccessful)` em sucesso e `onResult(false)` em falha/cancel. Task 3 (PlatformView) e Task 4 (HostApi) consomem.

- [ ] **Step 1: Adicionar imports**

Em `CameraManager.kt`, junto aos imports `androidx.camera.core.*` (após linha 16):

```kotlin
import androidx.camera.core.MeteringPoint
```

E junto aos imports de concorrência (após linha 37 `import java.util.concurrent.TimeUnit`):

```kotlin
import java.util.concurrent.ExecutionException
```

- [ ] **Step 2: Adicionar o método `focusAtMeteringPoint`**

Logo após o método `focusAt(point: FocusPoint)` existente (após a linha 198, antes de `providerNow()`):

```kotlin
  fun focusAtMeteringPoint(point: MeteringPoint, onResult: (Boolean) -> Unit) {
    val cam = camera ?: throw CameraNativeException.NotRunning
    val action = FocusMeteringAction.Builder(point)
      .setAutoCancelDuration(5, TimeUnit.SECONDS)
      .build()
    val future = cam.cameraControl.startFocusAndMetering(action)
    future.addListener({
      val ok = try {
        future.get().isFocusSuccessful
      } catch (e: ExecutionException) {
        Log.w(TAG, "focus metering failed", e)
        false
      } catch (e: InterruptedException) {
        Thread.currentThread().interrupt()
        Log.w(TAG, "focus metering interrupted", e)
        false
      }
      onResult(ok)
    }, ContextCompat.getMainExecutor(context))
  }
```

- [ ] **Step 3: Verificar que compila**

Run (com JBR 21):
```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL. (Este passo é gate de compilação — não há infra de teste Kotlin no projeto; a prova funcional é no device, Task 6.)

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt
git commit -m "feat(camera): focusAtMeteringPoint com resultado honesto no android"
```

---

### Task 2: `FocusRing` — overlay nativo espelhando o timing do iOS

Ring de foco desenhado NO NATIVO no ponto exato do toque (sem roundtrip). Espelha `FocusRingConfig.swift`: branco, raio 32dp, duração 1.2s, scale 1.4→1.0, fade nos últimos 20%. `View` custom com `onDraw` (círculo stroke) animada por `ViewPropertyAnimator`.

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt`

**Interfaces:**
- Produces: `class FocusRingView(context: Context) : View` com `fun show(centerX: Float, centerY: Float)` — posiciona e anima o ring no FrameLayout pai. Task 3 (PlatformView) consome.

- [ ] **Step 1: Criar `FocusRingView.kt`**

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.TypedValue
import android.view.View

class FocusRingView(context: Context) : View(context) {
  private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    color = Color.WHITE
    strokeWidth = dp(1.5f)
  }
  private val radiusPx = dp(32f)

  init {
    visibility = INVISIBLE
  }

  override fun onDraw(canvas: Canvas) {
    canvas.drawCircle(width / 2f, height / 2f, radiusPx, ringPaint)
  }

  fun show(centerX: Float, centerY: Float) {
    val side = (radiusPx + ringPaint.strokeWidth) * 2f
    layoutParams?.let {
      it.width = side.toInt()
      it.height = side.toInt()
      layoutParams = it
    }
    x = centerX - side / 2f
    y = centerY - side / 2f

    animate().cancel()
    alpha = 1f
    scaleX = 1.4f
    scaleY = 1.4f
    visibility = VISIBLE
    animate()
      .scaleX(1f)
      .scaleY(1f)
      .setDuration(DURATION_MS)
      .withEndAction {
        animate()
          .alpha(0f)
          .setDuration(FADE_MS)
          .withEndAction { visibility = INVISIBLE }
          .start()
      }
      .start()
  }

  private fun dp(value: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

  companion object {
    private const val DURATION_MS = 960L
    private const val FADE_MS = 240L
  }
}
```

- [ ] **Step 2: Verificar que compila**

Run:
```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt
git commit -m "feat(camera): focus ring nativo android espelhando timing ios"
```

---

### Task 3: `CameraPlatformView` — captar tap nativo, montar MeteringPoint, mostrar ring

O `PreviewView` passa a viver dentro de um `FrameLayout` que hospeda o ring. `GestureDetector.onSingleTapUp` (padrão oficial CameraX — distingue tap de scroll/pinça) captura o toque; `previewView.meteringPointFactory.createPoint(e.x, e.y)` constrói o ponto; `manager.focusAtMeteringPoint` executa; o ring aparece imediatamente no ponto tocado.

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt` (reescrita)

**Interfaces:**
- Consumes: `manager.focusAtMeteringPoint` (Task 1); `FocusRingView.show` (Task 2); `previewView.meteringPointFactory`.
- Produces: PlatformView cujo `getView()` retorna o `FrameLayout` (preview + ring). Comportamento observável: tap → ring + foco.

- [ ] **Step 1: Reescrever `CameraPlatformView.kt`**

```kotlin
package com.rarocamera.raro_mobile.camera

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import androidx.camera.view.PreviewView
import io.flutter.plugin.platform.PlatformView

class CameraPlatformView(
  context: Context,
  private val manager: CameraManager,
) : PlatformView {
  private val previewView: PreviewView = PreviewView(context).apply {
    scaleType = PreviewView.ScaleType.FILL_CENTER
    implementationMode = PreviewView.ImplementationMode.COMPATIBLE
  }

  private val focusRing = FocusRingView(context)

  private val container: FrameLayout = FrameLayout(context).apply {
    addView(
      previewView,
      FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT,
      ),
    )
    addView(focusRing, FrameLayout.LayoutParams(0, 0))
  }

  private val gestureDetector = GestureDetector(
    context,
    object : GestureDetector.SimpleOnGestureListener() {
      override fun onDown(e: MotionEvent): Boolean = true

      override fun onSingleTapUp(e: MotionEvent): Boolean {
        handleTap(e.x, e.y)
        return true
      }
    },
  )

  init {
    manager.surfaceProvider = previewView.surfaceProvider
    installTapListener()
  }

  @SuppressLint("ClickableViewAccessibility")
  private fun installTapListener() {
    previewView.setOnTouchListener { _, event ->
      gestureDetector.onTouchEvent(event)
    }
  }

  private fun handleTap(x: Float, y: Float) {
    focusRing.show(x, y)
    val point = previewView.meteringPointFactory.createPoint(x, y)
    try {
      manager.focusAtMeteringPoint(point) { locked ->
        Log.d(TAG, "tap focus at ($x,$y) locked=$locked")
      }
    } catch (e: CameraNativeException) {
      Log.w(TAG, "tap focus ignored: ${e.message}")
    }
  }

  override fun getView(): View = container

  override fun dispose() {
    manager.surfaceProvider = null
  }

  private companion object {
    const val TAG = "RaroCamera"
  }
}
```

- [ ] **Step 2: Verificar que compila**

Run:
```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt
git commit -m "feat(camera): tap-to-focus nativo android com ring e meteringpoint"
```

---

### Task 4: `CameraHostApiImpl.focusAt` — parar de mentir `locked=true`

O caminho Pigeon `focusAt(FocusPoint)` (coordenadas normalizadas, se algum caller Dart usar) hoje reporta `onFocusChanged(point, true)` imediatamente — mentira otimista. Rotear pelo resultado real. Como o `focusAt` normalizado usa `SurfaceOrientedMeteringPointFactory`, adicionar uma sobrecarga em `CameraManager` que também devolve o resultado, mantendo a semântica de coordenadas normalizadas (NÃO reusar o factory do PreviewView aqui — este caminho não tem pixel de tela).

**Files:**
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt` (`focusAt` passa a aceitar callback de resultado)
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt:82-90`

**Interfaces:**
- Consumes: `focusAtMeteringPoint` (Task 1) internamente.
- Produces: `fun focusAt(point: FocusPoint, onResult: (Boolean) -> Unit)` — constrói o `MeteringPoint` normalizado e delega ao caminho de resultado honesto.

- [ ] **Step 1: Refatorar `CameraManager.focusAt` para reportar resultado**

Substituir o método `focusAt(point: FocusPoint)` atual (linhas 190-198) por:

```kotlin
  fun focusAt(point: FocusPoint, onResult: (Boolean) -> Unit) {
    val factory = SurfaceOrientedMeteringPointFactory(1f, 1f)
    val meteringPoint = factory.createPoint(point.x.toFloat(), point.y.toFloat())
    focusAtMeteringPoint(meteringPoint, onResult)
  }
```

(`focusAtMeteringPoint` já lança `NotRunning` se `camera == null`, preservando o comportamento anterior.)

- [ ] **Step 2: Atualizar `CameraHostApiImpl.focusAt` para o resultado real**

Substituir o método `focusAt` (linhas 82-90) por:

```kotlin
  override fun focusAt(point: FocusPoint, callback: (Result<Unit>) -> Unit) {
    try {
      manager.focusAt(point) { locked ->
        main.post { flutterApi.onFocusChanged(point, locked) {} }
      }
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }
```

- [ ] **Step 3: Verificar que compila**

Run:
```bash
cd apps/mobile/android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt
git commit -m "fix(camera): onfocuschanged reporta resultado real no android (fim da mentira otimista)"
```

---

### Task 5: Suíte Dart + analyze verdes (não-regressão)

Fatia 2 é Android nativo; não há novo código Dart. Confirmar que nada regrediu na suíte Dart existente e no analyze, incluindo os goldens full-bleed (o ring é nativo — não deve aparecer em golden Flutter, mas o Stack de controles não pode ter mudado).

**Files:**
- (nenhum — apenas verificação)

- [ ] **Step 1: analyze**

Run:
```bash
bun run --filter '@raro/mobile' analyze
```
Expected: `No issues found!`

- [ ] **Step 2: suíte Dart completa**

Run:
```bash
bun run --filter '@raro/mobile' test
```
Expected: todos verdes (baseline: 331 testes). Se pendurar, `pkill -f "flutter_tester --disable-vm-service"`.

- [ ] **Step 3: Commit (se algum ajuste foi necessário; senão pular)**

Só se algo precisou mudar para os testes passarem. Do contrário, sem commit — a suíte já estava verde.

---

### Task 6: Prova no device (M54) — DoD da spec

Gate final. Sem infra de teste Kotlin, a prova é no device físico com o kit adb (memória `raro-pattern-android-surfaceview-fullbleed-eats-overlays` documenta o kit).

**Files:**
- (nenhum — validação física)

- [ ] **Step 1: Build + install release/profile no M54**

```bash
cd apps/mobile && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
Confirmar install fresco antes de testar (memória `feedback_verify_device_install_before_test`): ler `Success` do `adb install`.

- [ ] **Step 2: DoD 1 — tap → ring + foco perceptível**

Abrir a câmera no M54, tocar em pontos diferentes: ring branco aparece no ponto tocado; foco muda perceptivelmente (aproximar/afastar objeto perto vs. longe). Registrar no PR.

- [ ] **Step 3: DoD 2 — screencap com ring**

```bash
adb exec-out screencap -p > /private/tmp/claude-501/focus-ring.png
```
(TextureView COMPATIBLE permite captura — ADR-0027.) Anexar no PR.

- [ ] **Step 4: DoD 3 — `onFocusChanged` honesto no log**

```bash
adb logcat -s RaroCamera:D | grep "tap focus"
```
Confirmar `locked=true` só após conclusão do foco (e `locked=false` quando falhar, ex. tocar em superfície sem contraste). Colar trecho no PR.

- [ ] **Step 5: DoD 4 — controles têm prioridade**

Tocar SOBRE os botões (troca de lente, REC): o controle dispara, o foco NÃO "vaza" por baixo. Confirmar o Stack de controles preservado.

- [ ] **Step 6: finishing-a-development-branch**

Após todos os DoDs verdes: usar a skill `superpowers:finishing-a-development-branch` — verificar testes, apresentar as 4 opções, PR pra develop.

---

## Notas de execução

- **Ordem dos MeteringPoint factories (não confundir):** tap nativo = `previewView.meteringPointFactory.createPoint(pixelX, pixelY)` (compensa rotação/crop/scale); caminho Pigeon normalizado = `SurfaceOrientedMeteringPointFactory(1f,1f).createPoint(normX, normY)`. Os dois NÃO se misturam (spec §2.2).
- **`onDown` retorna `true`** no `SimpleOnGestureListener` — sem isso o `GestureDetector` descarta a sequência e `onSingleTapUp` nunca dispara.
- **`@SuppressLint("ClickableViewAccessibility")`** é necessário no `setOnTouchListener` (lint exige `performClick`; aqui é preview de câmera, tap-to-focus não é um "click" acessível — padrão oficial CameraX).
- **Ring nativo, não Flutter:** o toque é nativo (Eager entrega à view nativa), então desenhar o feedback no nativo evita roundtrip e latência (memória `raro-pattern-flutter-platformview-tap-must-be-native`).
- **Build Android:** SEMPRE `JAVA_HOME` = JBR 21 do Android Studio.
