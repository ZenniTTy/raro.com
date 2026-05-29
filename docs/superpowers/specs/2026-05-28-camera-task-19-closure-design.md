# 2026-05-28 — camera-task-19-closure

## Status

`Approved` — aprovada por Eduardo Rodrigues em 2026-05-28. Plan correspondente em [`docs/superpowers/plans/2026-05-28-camera-task-19-closure.md`](../plans/2026-05-28-camera-task-19-closure.md). Transição para `In implementation` ao iniciar Task 1 do plan.

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues (Elovision)
- **Implementer agent:** `implementer`
- **Validator agent:** `validator`
- **Parent spec:** [`2026-05-26-camera-native-bridge-design.md`](2026-05-26-camera-native-bridge-design.md) — esta spec é o **closure da Task 19** da spec mãe. Não substitui; complementa.

## Reading order (pre-flight obrigatório)

Antes de implementar, ler nesta ordem:

1. [docs/briefing/original-briefing.md](../../briefing/original-briefing.md) — Seções 5.1 (M01) e 6.2 (Câmera técnica)
2. [docs/Blueprint.md](../../Blueprint.md) — Seções 2.2 (Method Channels), 5 (P05 Câmera), 11 (Roadmap rm-7)
3. [docs/briefing/prototype/Prototipo-RARO.html](../../briefing/prototype/Prototipo-RARO.html) — P05 (linhas 825+, `screenCamera()` e `renderCameraHud()`), incluindo CSS `.focus-ring` (scale-in 1.4→1.0 + fade 1.2s)
4. [CLAUDE.md](../../../CLAUDE.md) — manual autoritativo (especialmente §10 hard gates, §11 anti-patterns)
5. ADRs:
   - [ADR-0013](../../decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md) (Pigeon namespace + anti-FlutterError-redeclaration)
   - [ADR-0014](../../decisions/0014-flutter-3.44-spm-ios-15.md) (Flutter 3.44 + SPM + iOS 15 — minimum target mantido)
   - [ADR-0015](../../decisions/0015-camera-native-bridge-strategy.md) (Camera native bridge strategy + addendum A–H 2026-05-28 — esta spec adiciona **addendum I**)
6. Spec mãe: [`2026-05-26-camera-native-bridge-design.md`](2026-05-26-camera-native-bridge-design.md) — Tasks 1–18 já implementadas e mergeadas; Task 19 pendente
7. Session log mais recente: [docs/sessions/0005-camera-device-validation.md](../../sessions/0005-camera-device-validation.md)

## Problem

A spec mãe `feat/camera-native-bridge` está `In implementation` desde 2026-05-26 com **Tasks 1–18 done** e **Task 19 (device tests + G4 focus ring + G1/G7 perf) parcialmente fechada** em sessão 0005 (2026-05-27→28, iPhone 12 físico, 11 bugs corrigidos, ADR-0015 addendum A–H criado). Restam quatro pontas que bloqueiam o merge:

| Gate pendente | Status atual | Bloqueio |
|---|---|---|
| **G1** start ≤500ms (iOS+Android) | Não medido — apenas logs textuais | Não há instrumentação determinística |
| **G4** focus ring overlay ≤200ms + fade 1.2s | Implementação Flutter (`focus_ring_overlay.dart`) existe mas quebra hybrid composition sobre `UiKitView` (memória `raro-pattern-ios-platformview-camera-preview-black`); harness usa `showOverlays: false` como workaround | UI visual do ring inacessível na entrega |
| **G7** memory ±5MB pré/pós-stop (iOS+Android) | Não medido — sem `task_info` / `Debug.MemoryInfo` callback | Não há baseline de regressão futura |
| **Android device validation (Samsung Galaxy M54 5G)** | Implementação CameraX pronta nas Tasks 1–18; nunca exercitada em device físico | G2/G3/G6b/G7/G8/G9 Android não validados |

Sem esses gates, a spec mãe não pode transicionar para `Done` e a branch `feat/camera-native-bridge` (48 commits ahead) não pode mergear em `develop`. O closure desbloqueia o próximo passo do roadmap (`feat/replay-buffer-native-bridge`, rm-8).

## Sizing (auto-sizing)

- [ ] **Quick** (≤3 arquivos, sem mudança arquitetural)
- [x] **Medium** (1 feature, multi-file, sem novo bridge — só Pigeon callback adicionado)
- [ ] **Large** (novo bridge, novo ADR, multi-feature)

**Justificativa:** mexe em multi-file iOS Swift + Android Kotlin + Dart shared/mobile + Pigeon regen, mas **não introduz novo bridge** (reusa contrato camera) nem **novo ADR** (só addendum I em ADR-0015). Não muda stack/deps. Não muda invariantes (wake word, trial, planos).

## Q-table (perguntas pré-implementação — todas respondidas)

| # | Question | Answer |
|---|---|---|
| 1 | Abordagem do focus ring nativo (G4)? | **Native CALayer (iOS) + View Drawable (Android)**. `CAShapeLayer` sublayer no `AVCaptureVideoPreviewLayer` (Swift) + `FocusRingView` custom View dentro de `FrameLayout` wrapper sobre `PreviewView` (Kotlin). Tap continua no Flutter (`GestureDetector` mantém-se), `focusAt(x,y)` dispara render nativo. `focus_ring_overlay.dart` Flutter é deletado. Constantes em `raro_shared` (`FocusRingConfig`). |
| 2 | Método de medição G1/G7? | **Híbrido**: `OSSignposter` (iOS 15+) + `mach_absolute_time` + `task_info(TASK_VM_INFO).phys_footprint` (Swift) / `android.os.Trace` + `SystemClock.elapsedRealtimeNanos` + `Debug.MemoryInfo.getTotalPss()` (Kotlin). Callback Pigeon novo `FlutterApi.onPerformanceMetric(PerformanceMetric)`. Instruments + Android Studio Profiler rodados manualmente para baseline 1× registrado em ADR-0015 addendum I. |
| 3 | Validação Android — qual device físico? | **Samsung Galaxy M54 5G** (Exynos 1380, One UI 6 / Android 14). Triple cam 108MP wide + 8MP ultra-wide + 2MP macro. **Limite hardware: 4K@30fps** (não @60). G6 vira G6a iOS / G6b Android com targets distintos. One UI 6 honra Android 14 FGS policy → **modal anti-kill não necessário** (diferente de Xiaomi). |
| 4 | G10 iPad rejection? | **Removido do escopo.** Cliente contratou iOS smartphone + Android smartphone apenas. Lógica `discoverCapabilities` empty → throw `deviceUnavailable` permanece coberta por contract test. App Store Connect — capability `iPhone-only` configurada no release prep (futuro). |
| 5 | Bumpar iOS minimum para 16+ (habilita `ContinuousClock`)? | **Não.** Manter iOS 15+ (ADR-0014). `mach_absolute_time` + `OSSignposter` cobrem 100% das medições necessárias. ROI de bump baixo: iOS 15 market share ≈1.5% (May 2026), mas custo de ADR novo + risco regressão SPM não justifica para v1.0. Reavaliar em v1.1. |
| 6 | `CameraController.tapToFocusState` Android? | **Sim.** Usar Flow observer para detectar transição real do AF (FOCUSED/FAILED/NOT_FOCUSED) e emitir `onFocusChanged(success: Bool)` real. iOS equivalente: KVO em `device.isAdjustingFocus` com debounce 100ms (mitigação R3). UX: ring some quando AF confirma de verdade. |
| 7 | Pipeline `/verify-slice` cadence? | **Por task major + final.** T1 G4, T2 G1/G7, T3 device sweep, T4 closure. Memória `feedback_per_task_harness_validation` — nunca batched. |

## Observable goals (testes em device + harness)

**Cada item gera teste verificável** (unit/widget/native/integration). Asterisco (*) = manual em device físico.

### G1 — startSession ≤500ms

- [ ] G1a (iOS) — `OSSignposter` interval `startSession` em iPhone 12: `deltaMs ≤ 500` em ≥3 runs consecutivos cold + warm. *
- [ ] G1b (Android) — `Trace` section `startSession` em Samsung M54: `deltaMs ≤ 500` em ≥3 runs. *
- [ ] G1c (unit) — `CameraPerfMetricsTests.swift` valida `nsToMs(timebaseInfo, delta)` math correto.
- [ ] G1d (unit) — `CameraPerfMetricsTest.kt` valida `nsToMs(elapsedRealtimeNanos)` math.

### G2 — capabilities iPhone 12 + Samsung M54

- [ ] G2a (iOS) — iPhone 12 reporta `builtInDualWideCamera` com `virtualDeviceSwitchOverVideoZoomFactors[0] == 2.0`. * (já validado em sessão 0005, re-confirmar)
- [ ] G2b (Android) — Samsung M54 reporta `LENS_FACING_BACK` × 3 (wide 108MP + ultra-wide 8MP + macro 2MP) via CameraX `CameraInfo`. *

### G3 — lens switch 0.5×/1× sem blackout

- [ ] G3a (iOS) — switch 1×→0.5× via `videoZoomFactor` mapping (0.5x=zoom 1.0, 1x=zoom 2.0); preview frames consecutivos sem black frame. * (já validado em sessão 0005, re-confirmar)
- [ ] G3b (Android) — switch via CameraX `setLinearZoom` ou lens replace; PreviewView mantém última frame durante transição (CameraX padrão). *

### G4 — focus ring scale-in 1.4→1.0 + fade 1.2s

- [ ] G4a (iOS unit) — `CameraPlatformViewTests.swift` confirma `showFocusRing(point)` adiciona `CAShapeLayer` ao container layer com `CABasicAnimation` (`scale.x`, `scale.y` 1.4→1.0, easeOut, duration 1.2s) + `CAKeyframeAnimation` (`opacity` `[0,1,0]` keyTimes `[0,0.2,1]`).
- [ ] G4b (Android unit) — `FocusRingViewTest.kt` confirma `showFocusRing(point)` configura `ObjectAnimator` scaleX/Y 1.4→1.0 + alpha keyframes [0,1,0] com duração 1200ms.
- [ ] G4c (Flutter widget) — `camera_preview_widget_test.dart` confirma `GestureDetector.onTapDown` chama `cameraController.focusAt(nx, ny)` com coords normalizadas; sem Stack overlay Flutter; sem `_focus` state.
- [ ] G4d (golden iOS) — golden snapshot do harness com ring visível em (0.5, 0.4) — iPhone 12 simulator.
- [ ] G4e (golden Android) — golden snapshot do harness com ring visível em (0.5, 0.4) — Android emulator.
- [ ] G4f (device iOS) — tap em iPhone 12 dispara ring CALayer visível em <200ms; ring some em 1.2s. *
- [ ] G4g (device Android) — tap em Samsung M54 dispara ring View visível em <200ms; ring some quando AF confirma (via `tapToFocusState`); fallback 1.2s timeout. *
- [ ] G4h (design fidelity) — `design-fidelity-checker` compara ring vs protótipo HTML (.focus-ring class): color `#FFFFFF`, strokeWidth 1.5, scale 1.4→1.0 easeOut, opacity [0,1,0]; APPROVE | DEVIATIONS.

### G5 — resolução muda runtime (1080p/4K)

- [ ] G5a (iOS) — `setFormat(.uhd4k)` em iPhone 12 muda metadata `activeFormat.formatDescription` para 3840×2160. * (validado em sessão 0005, re-confirmar)
- [ ] G5b (Android) — `setFormat(.fullhd)` em Samsung M54 reconfigura `Preview.Builder.setResolutionSelector`. *

### G6 — 4K capability

- [ ] G6a (iOS) — iPhone 12 confirma 4K@60 ativo via metadata `activeVideoMinFrameDuration` (1/60 = 16.6ms). * (validado em sessão 0005)
- [ ] G6b (Android) — Samsung M54 confirma 4K@30 max suportado (Exynos 1380 hardware limit); app não tenta @60 e expõe via `discoverCapabilities.maxFps`. *

### G7 — memory ±5MB pré/pós-stop

- [ ] G7a (iOS) — em iPhone 12: capture `phys_footprint` antes de `startSession`, depois de `stopSession`; delta ≤ 5MB. Repetir 3× consecutivos sem leak acumulativo. *
- [ ] G7b (Android) — em Samsung M54: capture `Debug.MemoryInfo.getTotalPss()` antes/depois; delta ≤ 5MB. Repetir 3×. *
- [ ] G7c (iOS Instruments) — baseline Allocations trace salvo em `docs/perf/baselines/camera-iphone12.trace.summary.md` (não commitar `.trace` binário; só summary).
- [ ] G7d (Android Profiler) — baseline Memory Profiler salvo em `docs/perf/baselines/camera-m54.profile.summary.md`.

### G8/G9 — lifecycle background/foreground (cobertura parcial)

- [ ] G8a (iOS) — Control Center invocado durante captura: `AVCaptureSession.wasInterrupted` observer dispara; ao fechar Control Center, `interruptionEnded` retoma session sem crash. * (validado em sessão 0005, re-confirmar)
- [ ] G8b (Android) — Recents Menu durante captura: `Lifecycle.onPause` para preview sem destruir bridge; volta de Recents retoma. *
- [ ] G9 (parcial) — fechar app via ícone e reabrir (cold restart): **adiado** — exige Apple Developer Program ($99/ano). Documentar como `⏳ TestFlight`.

## UI / protótipo

- **Tela do protótipo:** P05 — Câmera viva ([Prototipo-RARO.html linhas 824+](../../briefing/prototype/Prototipo-RARO.html))
- **Tokens canônicos (Blueprint §4 / `raro_shared` `FocusRingConfig`):**
  - Color ring: `#FFFFFF` (`0xFFFFFFFF`)
  - Stroke width: 1.5
  - Radius: 32px
  - Duration: 1200ms
  - Scale: 1.4 → 1.0 (easeOut / DecelerateInterpolator)
  - Opacity keyframes: `[0.0, 1.0, 0.0]`
  - Opacity keyTimes: `[0.0, 0.2, 1.0]`
- **Microinterações:** ring aparece em <200ms do tap, fade-out termina em 1.2s (ou ao receber AF result, o que vier primeiro)
- **Copy:** N/A (focus ring não tem texto)

## Out of scope

- **G10 iPad** — cliente smartphone-only; lógica `deviceUnavailable` já coberta por contract test; capability `iPhone-only` em release prep (futuro)
- **G9 cold restart real (fechar app via ícone)** — exige Apple Developer Program; cobertura funcional via Control Center + observers já implementados
- **Rule-of-thirds + Viewport grain overlays Flutter** — ainda usam Stack sobre UiKitView (mesmo problema do focus ring). Migração nativa fica como issue dedicada (`feat/camera-grain-overlay` futura). `showOverlays` flag em `camera_preview_widget.dart` permanece para opt-in desses overlays; harness continua usando `showOverlays=false` até a spec dedicada migrá-los para nativo.
- **Pixel emulator validation** — substituído pelo device físico Samsung M54
- **Replay buffer / voice / volume bridges** — specs próprias (rm-8, rm-9, rm-10)
- **iPhone 13+/14+/15+ baseline** — iPhone 12 cobre Task 19; outros devices via Firebase Performance pós-release
- **Modal anti-kill Samsung** — One UI 6 honra Android 14 FGS; desnecessário (memória `raro-pattern-xiaomi-miui-hyperos-detection` permanece relevante só para Xiaomi/MIUI/HyperOS)
- **Bumping iOS minimum para 16+** — adiar para v1.1 ou ADR dedicado

## Architecture (resumo)

### G4 Native focus ring

```
Flutter GestureDetector ─tap(x,y)─▶ focusAt(FocusPoint{x,y}) via Pigeon
                                              │
              ┌───────────────────────────────┴────────────────────────────┐
              ▼                                                            ▼
  iOS CameraHostApiImpl                                  Android CameraHostApiImpl
       │                                                          │
       ├─ CameraManager.focusAt                                   ├─ CameraManager.focusAt
       │   device.focusPointOfInterest = CGPoint(x,y)             │   cameraControl.startFocusAndMetering(action)
       │   device.focusMode = .autoFocus                          │
       │                                                          │
       ├─ CameraPlatformView.showFocusRing(point)                 ├─ CameraPlatformView.showFocusRing(point)
       │   CAShapeLayer ring = ovalIn(CGRect)                     │   focusRingView.showAt(x,y)
       │   CABasicAnimation(scale) 1.4→1.0 easeOut 1200ms         │   ObjectAnimator(scaleX/Y) 1.4→1.0 1200ms
       │   CAKeyframeAnimation(opacity) [0,1,0]                   │   ObjectAnimator(alpha) keyframes
       │   ring.addAnimation; container.layer.addSublayer         │
       │                                                          │
       └─ KVO device.isAdjustingFocus (debounce 100ms)             └─ tapToFocusState Flow.collect
            edge true→false → flutterApi.onFocusChanged(true)         FOCUSED → flutterApi.onFocusChanged(true)
            timeout 3s     → flutterApi.onFocusChanged(false)         FAILED   → flutterApi.onFocusChanged(false)
                                                                      NOT_FOCUSED → continue ring (no fade yet)
```

### G1/G7 Performance instrumentation

```
iOS CameraManager.startSession (e equivalentes: stopSession, switchLens, setFormat)
   │
   ├─ signposter.beginInterval("startSession", id)
   ├─ let memPre = CameraPerfMetrics.physFootprintKb()
   ├─ let t0 = mach_absolute_time()
   │
   ├─ ... existing startSession code ...
   │
   ├─ let t1 = mach_absolute_time()
   ├─ let deltaMs = CameraPerfMetrics.nsToMs(t1 - t0)
   ├─ let memPost = CameraPerfMetrics.physFootprintKb()
   ├─ signposter.endInterval("startSession", interval)
   │
   └─ Task { @MainActor in flutterApi.onPerformanceMetric(
        PerformanceMetric(name: "startSession", deltaMs: deltaMs, memoryKb: memPost - memPre)
      ) }

Android equivalente:
   Trace.beginSection("startSession")
   val memPre = CameraPerfMetrics.totalPssKb()
   val t0 = SystemClock.elapsedRealtimeNanos()
   ... ...
   val deltaMs = (SystemClock.elapsedRealtimeNanos() - t0) / 1_000_000.0
   val memPost = CameraPerfMetrics.totalPssKb()
   Trace.endSection()
   flutterApi.onPerformanceMetric(PerformanceMetric(name="startSession", deltaMs=deltaMs, memoryKb=memPost - memPre))

Mitigação R6: memPost captura em coroutine/background (não bloqueia critical path)
```

### Pigeon contract delta

```dart
// packages/shared/pigeons/camera.dart (adicionar)

class PerformanceMetric {
  PerformanceMetric({required this.name, required this.deltaMs, required this.memoryKb});
  final String name;
  final double deltaMs;
  final int memoryKb;
}

@FlutterApi()
abstract class CameraFlutterApi {
  void onFocusChanged(FocusPoint point, bool locked); // existente
  void onPerformanceMetric(PerformanceMetric metric); // NOVO
}
```

### `raro_shared` delta

```dart
// packages/shared/lib/src/camera/focus_ring_config.dart (NOVO)

class FocusRingConfig {
  const FocusRingConfig._();
  static const int colorArgb = 0xFFFFFFFF;
  static const double strokeWidth = 1.5;
  static const int durationMs = 1200;
  static const double scaleFrom = 1.4;
  static const double scaleTo = 1.0;
  static const double radiusPx = 32.0;
  static const List<double> opacityKeyframes = [0.0, 1.0, 0.0];
  static const List<double> opacityKeyTimes = [0.0, 0.2, 1.0];
}
```

iOS/Android espelham as constantes em código nativo (Swift `FocusRingConfig` enum + Kotlin `object FocusRingConfig`) com comment `// MIRROR: packages/shared/lib/src/camera/focus_ring_config.dart — source of truth`.

## File map

### Flutter — delete

- `apps/mobile/lib/features/camera/presentation/focus_ring_overlay.dart`
- `apps/mobile/test/features/camera/presentation/focus_ring_overlay_test.dart` (se existir)

### Flutter — create

- `packages/shared/lib/src/camera/focus_ring_config.dart`
- `packages/shared/test/camera/focus_ring_config_test.dart`

### Flutter — update

- `packages/shared/lib/raro_shared.dart` (export `FocusRingConfig`)
- `packages/shared/pigeons/camera.dart` (add `PerformanceMetric` + `onPerformanceMetric`)
- `apps/mobile/lib/features/camera/presentation/camera_preview_widget.dart` (remove `_focus` state + `FocusRingOverlay` import/usage; **mantém** `showOverlays` flag + Stack envolvendo rule-of-thirds e grain — esses dois continuam Flutter overlays até spec dedicada `feat/camera-grain-overlay` migrá-los para nativo. Focus ring sai do Stack e passa a ser renderizado pelo native side, visível independente do flag)
- `apps/mobile/lib/features/camera/application/camera_controller.dart` (perf metric stream + state)
- `apps/mobile/lib/features/camera/data/camera_repository.dart` (abstract perf metric stream)
- `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart` (wire `onPerformanceMetric` → stream)
- `apps/mobile/lib/features/camera/presentation/camera_test_harness_screen.dart` (add perf HUD: deltaMs + memoryKb por evento)
- `apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart` (update)
- `apps/mobile/test/features/camera/application/camera_controller_test.dart` (add perf test)
- `apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart` (add perf bridge test)

### iOS native — create

- `apps/mobile/ios/Runner/Native/Camera/CameraPerfMetrics.swift`
- `apps/mobile/ios/RunnerTests/CameraPerfMetricsTests.swift`
- `apps/mobile/ios/RunnerTests/CameraPlatformViewTests.swift` (focus ring sublayer assertions)

### iOS native — update

- `apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift` (add `showFocusRing(point)` + `CAShapeLayer` + animations)
- `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` (add `OSSignposter` + perf wrappers; KVO `isAdjustingFocus` + debounce 100ms)
- `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift` (trigger `showFocusRing` after `focusAt`; emit `onPerformanceMetric`)
- `apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift` (regen via Pigeon)

### Android native — create

- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt`
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetrics.kt`
- `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetricsTest.kt`
- `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/FocusRingViewTest.kt`

### Android native — update

- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt` (wrap `PreviewView` + `FocusRingView` em `FrameLayout`; add `showFocusRing(point)`)
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt` (add `Trace` + perf wrappers; observe `tapToFocusState` Flow)
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt` (trigger `showFocusRing`; emit `onPerformanceMetric`)
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/camera/CameraApi.g.kt` (regen via Pigeon)

### Docs

- `docs/decisions/0015-camera-native-bridge-strategy.md` — add **addendum I: Task 19 closure**
- `docs/Blueprint.md` — add row para `FocusRingConfig` em Seção 5 (P05 Câmera) ou Seção 4 (tokens)
- `docs/perf/baselines/camera-iphone12.summary.md` (novo dir + arquivo)
- `docs/perf/baselines/camera-m54.summary.md`
- `docs/sessions/0006-camera-task-19-closure.md` (criar ao final)
- `docs/sessions/0001-INDEX.md` (append row 0006 ao topo)
- `docs/10-CHANGELOG.md` (entry `0.4.2 — 2026-05-28`)
- `CLAUDE.md` (§11 append anti-pattern: "renderizar overlay UI Flutter sobre PlatformView quebra hybrid composition iOS — migrar para CALayer/View nativo")

## Risks

| # | Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|---|
| R1 | `CAShapeLayer` sublayer interfere com video orientation/rotation | Médio | Médio | `contentsScale = UIScreen.main.scale`; `bounds` derivado de `container.bounds`; testar device rotation no harness |
| R2 | `FocusRingView` Android intercepta touch | Médio | Baixo | `FrameLayout` wrapper; `setClickable(false)` + `setFocusable(false)` no ring; manter tap no Flutter; integration test confirma tap funciona |
| R3 | KVO `isAdjustingFocus` iOS dispara em alta frequência | Médio | Baixo | Debounce 100ms; emit `onFocusChanged(true)` apenas em edge true→false; timeout 3s para `success=false` |
| R4 | `tapToFocusState` Flow Android exige `LifecycleOwner` | Baixo | Baixo | Usar `LifecycleOwner` do `CameraPlatformView` (já existe); `lifecycleScope.launch { stateFlow.collect { ... } }` |
| R5 | `mach_absolute_time` precisão sub-ms em iPhone 12 reporta 0 para ops ultra-curtas | Baixo | Baixo | `timebaseInfo` init lazy; helper documenta limite de precisão (~tens of ns) |
| R6 | `Debug.MemoryInfo.getTotalPss()` Android é caro (5–20ms) e polui métrica se medido no critical path | **Alto** | Alto | Medir **fora** do bloco crítico: `memPost` capturado em coroutine; emit metric assíncrono via `flutterApi` |
| R7 | OSSignposter custom Instruments package issue (documentado opentelemetry-swift #582) | Baixo | Baixo | Usar apenas templates Instruments built-in (Points of Interest, Time Profiler, Allocations); custom `.instrpkg` fora do escopo |
| R8 | Samsung M54 ultra-wide reporta `lensFacing` inesperado | Médio | Médio | Filtrar via `INFO_SUPPORTED_HARDWARE_LEVEL ≥ LIMITED`; fallback skip ultra-wide se hardware level insuficiente |
| R9 | Pigeon regen quebra arquivos generated existentes | Baixo | Baixo | Commit isolado regen; diff manual revisado; CI lint roda em `.g.{dart,swift,kt}` |
| R10 | Memory baseline iPhone 12 não representa devices mais novos | Baixo | Médio | Documentar baseline como device-specific; futura Firebase Performance pós-release cobre outros devices |
| R11 | Rule-of-thirds + grain overlays continuam quebrando hybrid composition | **Conhecido, out-of-scope** | Médio | Documentar como issue em INDEX 0001; harness mantém `showOverlays=false`; spec dedicada (`feat/camera-grain-overlay`) próxima |

## Hard gates (CLAUDE.md §10) ativos

- [x] Method Channel tocado (Pigeon delta) → contract test `pigeon_camera_repository_test.dart` cobre `onPerformanceMetric` bridge end-to-end
- [x] Tela do protótipo tocada (P05) → `design-fidelity-checker` valida ring color/timing/animations contra `.focus-ring` HTML
- [ ] Mudou stack/dep → **não** (Pigeon, OSSignposter, Trace, CameraX já são deps existentes)
- [x] Integration test device → iPhone 12 + Samsung M54 obrigatórios (não emulator)
- [x] Per-task `/verify-slice` → após T1, T2, T3 (memória `feedback_per_task_harness_validation`)

## ADRs necessários

- [x] ADR existente: [ADR-0015](../../decisions/0015-camera-native-bridge-strategy.md) — adicionar **addendum I: Task 19 closure** com tabela de decisões (G4 CALayer/View, OSSignposter, mach_absolute_time mantido, 4K@30 Android device-limit, One UI 6 FGS, getTapToFocusState)
- [x] ADR existente: [ADR-0014](../../decisions/0014-flutter-3.44-spm-ios-15.md) — iOS 15 minimum **mantido**; bump 16+ rejeitado (Q-table #5)
- [ ] ADR novo necessário → **não** (`adr-guardian` valida na T1)

## Sequenciamento (PR plan)

```
branch: feat/camera-native-bridge  (continua — não cria branch nova)

T1: G4 native focus ring  (~5 commits)
   1.  feat(shared): add FocusRingConfig constants + tests
   2.  refactor(camera): remove focus_ring_overlay.dart + simplify preview widget + tests
   3.  feat(camera/ios): CAShapeLayer focus ring + showFocusRing + KVO isAdjustingFocus + tests
   4.  feat(camera/android): FocusRingView + showFocusRing + tapToFocusState observer + tests
   5.  /verify-slice  → flutter-test-author (TDD red→green) + design-fidelity-checker

T2: G1/G7 perf instrumentation  (~7 commits)
   6.  feat(shared): pigeon contract PerformanceMetric + onPerformanceMetric
   7.  chore(codegen): regenerate camera_api.g.{dart,swift,kt}
   8.  feat(camera/ios): OSSignposter + CameraPerfMetrics + emit perf + tests
   9.  feat(camera/android): Trace + CameraPerfMetrics + emit perf + tests
  10.  feat(camera): repository + controller perf metric stream + tests
  11.  feat(camera): harness HUD shows deltaMs + memoryKb
  12.  /verify-slice  → flutter-perf-auditor

T3: Device sweep (iPhone 12 + Samsung M54)  (~5 commits)
  13.  docs(perf): camera-iphone12.summary.md baseline numbers + Instruments screenshot
  14.  docs(perf): camera-m54.summary.md baseline + 4K@30 confirmation + Profiler screenshot
  15.  docs(adr): ADR-0015 addendum I — Task 19 closure (G4 native pattern, OSSignposter choice, 4K Android, One UI 6 FGS)
  16.  docs(blueprint): FocusRingConfig row + 4K@30 Android caveat in P05 section
  17.  docs(claude): §11 add anti-pattern Flutter overlay over PlatformView
  /verify-slice final + validator subagent (SPEC_COMPLIANT)

T4: Closure  (~4 commits)
  18.  docs(session): 0006 session log
  19.  docs(index): append row 0006
  20.  docs(changelog): 0.4.2 entry
  21.  docs(spec): mark camera-native-bridge spec as Done + this spec as Done
  → merge feat/camera-native-bridge → develop → main
```

## References

- Briefing: Seções 5.1 (M01), 6.2 (Câmera técnica)
- Blueprint: Seções 2.2 (Method Channels), 5 (P05), 11 (Roadmap rm-7)
- Protótipo: `Prototipo-RARO.html` linhas 824+ (`.focus-ring` CSS class)
- ADRs: 0013 (Pigeon), 0014 (iOS 15+), 0015 (camera bridge strategy + addendum A–H, I a criar)
- Spec mãe: [`2026-05-26-camera-native-bridge-design.md`](2026-05-26-camera-native-bridge-design.md)
- Session anterior: [`docs/sessions/0005-camera-device-validation.md`](../../sessions/0005-camera-device-validation.md)
- Memórias auto-loaded (`MEMORY.md`):
  - `raro-pattern-ios-platformview-camera-preview-black` — motiva native ring
  - `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping` — base de G2/G3 iOS
  - `raro-pattern-android-camerax-ultra-wide-unreliable` — informa filtro M54
  - `raro-pattern-xiaomi-miui-hyperos-detection` — confirma que M54 (Samsung) não precisa modal
  - `feedback_device_debug_use_real_logs_not_assumptions` — guia debug iPhone/M54
  - `feedback_per_task_harness_validation` — exige /verify-slice por task
  - `feedback_tdd_pin_behavior_not_type` — exige assertions de campo + 1 teste por branch
- Sources MCP/Web consultadas (2026-05-28):
  - [Apple OSSignposter docs](https://developer.apple.com/documentation/os/ossignposter)
  - [Apple ContinuousClock docs](https://developer.apple.com/documentation/swift/continuousclock) (rejeitada — exige iOS 16)
  - [Apple AVCaptureVideoPreviewLayer overlay thread](https://developer.apple.com/forums/thread/97336)
  - [SE-0329 Clock, Instant, Duration](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md)
  - [CameraX releases (tapToFocusState API)](https://developer.android.com/jetpack/androidx/releases/camera)
  - [GSMArena Samsung Galaxy M54](https://www.gsmarena.com/samsung_galaxy_m54-12189.php)
  - [Don't Kill My App — Samsung](https://dontkillmyapp.com/samsung)
  - [opentelemetry-swift #582](https://github.com/open-telemetry/opentelemetry-swift/issues/582)
