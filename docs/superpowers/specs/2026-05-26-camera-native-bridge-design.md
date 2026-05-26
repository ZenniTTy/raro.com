# 2026-05-26 — camera-native-bridge

## Status

`Draft`

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues (Elovision)
- **Implementer agent:** `implementer`
- **Validator agent:** `validator`

## Reading order (pre-flight obrigatório)

1. `docs/briefing/original-briefing.md` — Seção 5.1 (M01) e 6.2 (Câmera técnica)
2. `docs/Blueprint.md` — Seções 2.2 (Method Channels), 2.3 (futuro voice), 5 (telas), 11 (Roadmap rm-7)
3. `docs/briefing/prototype/Prototipo-RARO.html` — P05 (linhas 825+ do HTML, função `screenCamera()` e `renderCameraHud()`)
4. `CLAUDE.md` — manual autoritativo
5. ADRs relacionados:
   - ADR-0013 (Pigeon namespace + anti-FlutterError-redeclaration)
   - ADR-0014 (Flutter 3.44 + SPM + iOS 15)
   - ADR-0015 **(novo nesta spec)** — Camera native bridge strategy

## Problem

O briefing (Seção 6.2) e o Blueprint (Seção 2.2) definem que a câmera RARO **não pode usar o plugin oficial `camera` do Flutter Team** porque ele não suporta alternância física entre lentes 0.5× e 1× (issues `flutter#91247` e `flutter#173406`, abertas e sem solução em maio/2026 — só zoom contínuo via `setZoomLevel()`, que clampa em 1.0 no iOS). Replay Buffer também não tem plugin pronto.

A decisão tomada: implementação 100% nativa via bridges Pigeon (ADR-0013), começando por `feat/camera-native-bridge` (Roadmap rm-7, prioridade 1) para validar o pipeline native bridge ponta-a-ponta antes de evoluir para replay_buffer, voice e volume.

Esta spec entrega a **fundação técnica do P05**: viewport ao vivo + alternância 0.5×/1× + tap-to-focus + ajuste de resolução/FPS, fiel à parte do protótipo que depende do bridge. **Não entrega gravação** — gravação precisa do pre-roll do replay_buffer (Seção 5.2 do briefing), então vira spec separada após `feat/replay-buffer-native-bridge`. **Não entrega o HUD completo** do P05 — top bar, REC indicator, timer, buffer bar, hint "DIGA RARO", record button, gallery/settings icons e grad-line são camada UI pura, viram spec `feat/camera-hud` que consome este bridge.

## Sizing (auto-sizing)

- [ ] **Quick**
- [ ] **Medium**
- [x] **Large** — novo bridge nativo iOS (AVFoundation) + Android (CameraX 1.6.1) + ADR-0015 + tela parcial do protótipo. Exige `/new-plan` + atomic tasks TDD + `validator` + `design-fidelity-checker`.

## Q-table

| # | Question | Answer |
|---|----------|--------|
| 1 | Esta spec entrega gravação real (start/stop salvando MP4)? | **Não.** Preview + lens + focus + format apenas. Gravação espera `feat/replay-buffer-native-bridge` para o pre-roll. |
| 2 | iOS — como alternar entre 0.5× e 1×? | **Estratégia híbrida.** `VirtualCameraStrategy` (smooth zoom via `builtInTripleCamera`/`builtInDualWideCamera` + `videoZoomFactor`) quando disponível; `SwapInputStrategy` (begin/commitConfiguration + remove/addInput) como fallback. Selector em runtime. |
| 3 | Android — qual versão do CameraX? | **1.6.1** (latest stable, novo motor CameraPipe — alinhado com Blueprint Seção 2). Risco de regression em OEMs aceito; device test obrigatório em Xiaomi/Samsung antes de declarar Done. |
| 4 | Android PlatformView mode? | **Hybrid composition** — RARO tem HUD Flutter sobre o preview (top bar, chips, focus ring, futuros botões). Custo GPU ~5-10% aceito para MVP. |
| 5 | iOS — controle de resolução/FPS? | **`activeFormat` manual** + `activeVideoMinFrameDuration`/`MaxFrameDuration`. `sessionPreset` insuficiente para garantir 4K@60. |
| 6 | Popup de assinatura do P05 (quando `!subscribed`)? | **Fora desta spec.** Bridge é agnóstico de paywall. Popup overlay vira parte de `feat/paywall`. |
| 7 | Permission flow? | Bridge expõe `requestPermission()`/`hasPermission()` via Pigeon `@async`. UI orquestra pre-flight em P04 (spec futura). Bridge não navega. |
| 8 | Tap-to-focus — coordenadas? | **Normalizado 0..1** em ambas plataformas. Native converte para `CGPoint` (iOS) e `MeteringPoint` (Android). |
| 9 | Enum `LensType` cobre quais? | **v1.0 = `ultraWide` + `wide` apenas.** Tele/2×+ fora do escopo (protótipo só mostra chips 0.5×/1×). |
| 10 | iPad suportado? | **Não.** Bridge retorna `onError(deviceUnavailable)`. Blueprint = iPhone-only. |
| 11 | Erros — exceptions ou enum? | **Enum `CameraErrorCode` + callback `onError`** via FlutterApi. Cruza plataformas limpo, sem `PlatformException` ad-hoc. |
| 12 | Sub-package Kotlin do Pigeon? | **`com.rarocamera.raro_mobile.generated.camera`** (ADR-0013 anti-redeclaration de `FlutterError`). |
| 13 | Rule-of-thirds e grain no viewport? | **Sim**, fiéis ao protótipo (`.viewport-grain` + linhas guides). Implementados em Flutter (`CustomPainter`), não em native — desacoplado do bridge. |
| 14 | Background/foreground? | Bridge resume sessão automaticamente em `applicationDidBecomeActive` / Lifecycle `ON_RESUME`. Goal observável #9. |

## Observable goals (testáveis em device real)

- [ ] **G1** — Bridge inicializa (`start()`) em ≤500ms em iPhone 12 e Pixel 6 (referência).
- [ ] **G2** — `discoverCapabilities()` retorna `[ultraWide, wide]` em iPhone 12 e Pixel 6 Pro; `[wide]` only em Pixel 6a (ou outro single-lens).
- [ ] **G3** — Lens switch 0.5×↔1× sem blackout perceptível (<100ms) em iPhone 12 via `VirtualCameraStrategy`.
- [ ] **G4** — Tap-to-focus mostra focus ring animado em ≤200ms; ring com scale-in + fade 1.2s, fiel à classe `.focus-ring` do protótipo.
- [ ] **G5** — Resolução muda em runtime (1080p→4K) sem reabrir sessão em iPhone 12 e Pixel 6.
- [ ] **G6** — 4K@60fps confirmado via Camera2 metadata (Android `CONTROL_AE_TARGET_FPS_RANGE`) e `activeVideoMinFrameDuration` (iOS) em devices compatíveis.
- [ ] **G7** — `stop()` libera memória — heap pré-start ± 5MB após stop+dispose (medido via Xcode Instruments e Android Memory Profiler).
- [ ] **G8** — Permission denied → `state = Error(permissionDenied)` sem crash; UI exibe fallback.
- [ ] **G9** — Background→foreground retoma sessão sem reabrir manualmente; preview volta em ≤300ms.
- [ ] **G10** — iPad rejeitado: `onError(deviceUnavailable)` antes de qualquer alocação de sessão.
- [ ] **G11** — `bun --filter @raro/mobile run pigeon` idempotente após edits em `pigeons/camera_api.dart`.
- [ ] **G12** — `bun --filter @raro/mobile run analyze` zero issues + `bun --filter @raro/mobile run test` zero regressões + suite `test/contract/` verde após cada commit.
- [ ] **G13** — `bridge_channels_parity_test.dart` valida que namespace canônico `BridgeChannels.camera == 'com.rarocamera/camera'` é o usado em runtime (ADR-0013).
- [ ] **G14** — Goldens `lens_chip_row_golden_test.dart` (alchemist) cobrem estados idle/selected/disabled.

## UI / protótipo (fidelidade ao P05)

**Tela do protótipo:** P05 — Câmera (linhas 825+ do `Prototipo-RARO.html`, funções `screenCamera()` + `renderCameraHud()`).

**Elementos do P05 entregues nesta spec:**

| Elemento P05 | Fidelidade |
|---|---|
| Viewport com `.viewport-grain` (grain overlay sutil) | ✅ Reproduzido via `CustomPainter` em Flutter |
| Rule-of-thirds (linhas guides 1/3) | ✅ `CustomPainter` simples |
| Focus ring animado (`.focus-ring`, scale-in + fade 1.2s) | ✅ `AnimatedContainer` ou `AnimationController` |
| Lens chips `0.5×` / `1×` (estilo do protótipo) | ✅ `lens_chip_row.dart`, esconde chip se lente indisponível em capabilities |
| Tap-to-focus (`onclick="tapFocus(event)"` no protótipo) | ✅ `GestureDetector` envolve `UiKitView`/`AndroidView` |
| Tokens de cor/gradient | ✅ Via `RaroTheme` ThemeExtension (ADR-0013) — `Theme.of(context).extension<RaroColors>()!` |
| Strings de UI | ✅ `.arb` (zero literais inline — gate contract) |

**Elementos do P05 fora desta spec (delegados a specs futuras):**

| Elemento P05 | Spec futura |
|---|---|
| Top bar (close, "RARO" wordmark) | `feat/camera-hud` |
| `Raro Replay` pill (15s/30s) | `feat/replay-buffer-native-bridge` |
| REC indicator + timer | `feat/camera-recording` (após replay_buffer) |
| Buffer bar (`.buffer-bar`) | `feat/replay-buffer-native-bridge` |
| Hint central "DIGA 'RARO' PARA GRAVAR" | `feat/voice-native-bridge` |
| Record button central | `feat/camera-recording` |
| Galeria icon (left) / Settings icon (right) | `feat/camera-hud` |
| `grad-line` bottom | `feat/camera-hud` |
| Subscription popup overlay (`openSubPopup()`) | `feat/paywall` |
| Lock mode P05a | `feat/lock-mode` |

**Copy literal desta spec:** nenhuma string customizada além das chaves canônicas; viewport e lens chips usam apenas tokens visuais. Quando texto entrar (specs futuras de HUD), as 30 dias trial, "MELHOR OFERTA", "DIGA 'RARO' PARA GRAVAR" etc. seguem o protótipo literalmente.

## Out of scope

- Gravação real (start/stop salvando MP4 no app sandbox ou galeria) — depende de replay_buffer
- Replay Buffer (`com.rarocamera/replay_buffer`) — spec separada
- Wake word `"Raro"` (`com.rarocamera/voice`) — spec separada
- Botões físicos de volume (`com.rarocamera/volume`) — spec separada
- HUD completo do P05 — `feat/camera-hud`
- Settings P06 (pickers de resolução/FPS/lens default) — `feat/camera-settings`
- Paywall popup overlay e gate `!subscribed` — `feat/paywall`
- Lock mode P05a
- Galeria P07/P08 — `feat/gallery`
- iPad — Blueprint diz iPhone-only
- Telephoto 2×+ — protótipo só mostra chips 0.5×/1×
- Multi-cam (`AVCaptureMultiCamSession`) — overkill para alternância discreta (memória `raro-pattern-ios-avcapture-multicam-not-needed`)
- Permissões nativas pre-flight (P04) — spec futura
- Tradução em tempo real (descartada no Blueprint Q5)

## Risks

| Risco | Mitigação |
|---|---|
| CameraX 1.6.1 novo motor CameraPipe → regression em OEM (Xiaomi/Samsung) | Device test obrigatório antes de declarar Done. Fallback documentado em ADR-0015: rebaixar para 1.5.x via ADR-update se bloqueado. |
| PlatformView hybrid composition Android overhead GPU 5-10% | Aceito p/ MVP. `flutter-perf-auditor` audita ao final da implementação. Documentado em ADR-0015. |
| AVCaptureSession leak (histórico Flutter#176xxx em camera plugins) | Dispose explícito + KVO invalidate + assert no `deinit`. Goal #7 mede via Instruments. |
| iOS smooth zoom em virtual camera dropa framerate momentâneo (reports em dev forums) | Strategy híbrida + device test iPhone 12. Fallback: forçar `SwapInputStrategy` via ADR-update se inaceitável em produção. |
| Ultra-wide indisponível em alguns Android OEMs apesar de hardware presente | Memória `raro-pattern-android-camerax-ultra-wide-unreliable` — discovery é source of truth, UI esconde chip 0.5× se ausente em capabilities. Sem fallback automático. |
| Pigeon 26.3.4 ainda bloqueado por theme_tailor/riverpod_lint analyzer ^9.0.0 | Mantém pigeon **^26.3.2** (Caso B do ADR-0014). Não escala esta spec. Re-tentativa em spec futura quando deps atualizarem. |
| iPhone 11/SE rejeitando ultra-wide em runtime apesar de hardware presente | Goal #2 cobre. Discovery via `AVCaptureDevice.DiscoverySession` é source of truth — UI confia no resultado. |
| `builtInTripleCamera` muda `activePrimaryConstituent` autonomamente atravessando thresholds | KVO em `activePrimaryConstituent` + callback `onLensSwitched`. UI sincroniza chip selecionado. |
| Permission denied mid-session (usuário revoga em Settings) | Bridge detecta via `AVCaptureSession.runtimeError` notification (iOS) / CameraX `ImageCaptureException` (Android), emite `onError(permissionDenied)`. |
| Pigeon HostApi bloqueando main thread em discovery pesada | Todas ops `@async` + `makeBackgroundTaskQueue()` no plugin binding iOS + Handler/Looper Android. Researcher confirmou pattern. |

## ADRs necessários

- [x] **ADR-0013** (existente) — Pigeon + Theme Tailor + anti-drift gates → referenciado para namespace e sub-package Kotlin.
- [x] **ADR-0014** (existente) — Flutter 3.44 + SPM + iOS 15 → referenciado para pigeon ^26.3.2 (Caso B) e iOS deployment target.
- [ ] **ADR-0015** (novo, criado nesta spec) — Camera native bridge strategy.

**Conteúdo do ADR-0015** (rascunho):

- **Status:** Accepted
- **Decisão:**
  1. Bridge **Pigeon-first** (todas as ops `@async`, enums tipados, FlutterApi callbacks).
  2. **iOS strategy híbrida**: `VirtualCameraStrategy` (`builtInTripleCamera` → `builtInDualWideCamera` + `videoZoomFactor`) quando disponível; `SwapInputStrategy` (begin/commitConfiguration + remove/addInput) como fallback. Selector em runtime via `AVCaptureDevice.DiscoverySession`.
  3. **CameraX 1.6.1** pinado em `apps/mobile/android/app/build.gradle` — latest stable em 2026-05-26, novo motor CameraPipe. Aceito o risco; device test obrigatório em Xiaomi/Samsung pré-RC.
  4. **PlatformView Android = hybrid composition** — `setHybridComposition(true)` em `MainActivity.configureFlutterEngine`. Custo GPU 5-10% documentado e aceito.
  5. **iOS format control via `activeFormat`** + `activeVideoMin/MaxFrameDuration` (não `sessionPreset`) — controle granular obrigatório para Settings (1080p@30 vs 4K@60).
  6. **Threading**: HostApi roda main thread por default; ops pesadas (discovery, format negotiation) via `makeBackgroundTaskQueue()` iOS e `Camera2Interop` callbacks no Looper main Android.
  7. **Sem gravação** nesta spec — boundary explícito com replay_buffer.
- **Consequências:**
  - Bridge testável isoladamente sem replay_buffer
  - 2 strategies iOS introduzem complexidade — mitigada por interface `CameraLensStrategy` e teste unitário por strategy
  - CameraPipe risco aceito
- **Alternativas consideradas:**
  - Plugin oficial `camera` — rejeitado (briefing Seção 6.2)
  - `iris_camera` v1.0.5 — rejeitado (briefing Seção 6.2: baixa adoção, risco de abandono)
  - `AVCaptureMultiCamSession` — rejeitado (overkill para alternância discreta, memória `raro-pattern-ios-avcapture-multicam-not-needed`)
  - CameraX 1.5.x — rejeitado (Blueprint pede latest stable)
  - Texture layer no Android (sem hybrid composition) — rejeitado (HUD Flutter precisa overlay)

## References

- Briefing Seções 5.1 (M01), 6.2 (decisão técnica câmera nativa)
- Blueprint Seções 2.2 (Method Channels via Pigeon), 5 (telas P05), 11 (Roadmap rm-7)
- Protótipo P05 (`docs/briefing/prototype/Prototipo-RARO.html`, `screenCamera()`/`renderCameraHud()`)
- ADRs: 0013 (Pigeon namespace), 0014 (Flutter 3.44 + SPM + iOS 15)
- Spec relacionada: `2026-05-26-api-contract-shared-design.md` (`BridgeChannels.camera`)
- Memórias persistentes aplicadas:
  - `feedback_per_task_harness_validation` — analyze + test + drift checks após cada task antes do commit
  - `feedback_validator_cross_doc_consistency` — auditoria cross-doc antes de Done
  - `raro-pattern-android-camerax-ultra-wide-unreliable` — UI esconde chip 0.5× quando capabilities ausente
  - `raro-pattern-ios-avcapture-multicam-not-needed` — sem MultiCam em v1.0
- Issues externas relevantes:
  - https://github.com/flutter/flutter/issues/91247 (plugin camera sem alternância física iOS)
  - https://github.com/flutter/flutter/issues/173406 (mesma issue, reaberta 2026)
- Docs oficiais (researcher 2026-05-26):
  - https://developer.apple.com/documentation/avfoundation/capture_setup/choosing_a_capture_device
  - https://developer.android.com/media/camera/camerax
  - https://developer.android.com/jetpack/androidx/releases/camera
  - https://docs.flutter.dev/platform-integration/platform-channels
