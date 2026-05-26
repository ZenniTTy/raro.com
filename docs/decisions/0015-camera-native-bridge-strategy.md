# 0015 — Camera native bridge strategy

- **Data:** 2026-05-26
- **Status:** Accepted
- **Spec:** docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
- **Supersedes:** —
- **Decisores:** Eduardo Rodrigues (Elovision)

## Contexto

Briefing Seção 6.2 e Blueprint Seção 2.2 exigem implementação 100% nativa da câmera (plugin oficial `camera` não suporta alternância 0.5×/1×, issues flutter#91247 + #173406). Esta é a primeira spec do Roadmap rm-7 (bridges nativos), valida o pipeline ponta-a-ponta antes de evoluir para replay_buffer/voice/volume.

## Decisão

1. **Pigeon-first contract**. Todas as ops `@async`. Enums tipados (`LensType`, `Resolution`, `Fps`). FlutterApi para callbacks. Sub-package Kotlin `com.rarocamera.raro_mobile.generated.camera` (ADR-0013 anti-redeclaration).
2. **iOS — VirtualCameraStrategy única.** `builtInTripleCamera` → `builtInDualWideCamera` + `videoZoomFactor` (smooth zoom). YAGNI: iPhones com 0.5× sempre expõem virtual camera. `SwapInputStrategy` documentada como rollback acionável via ADR-update se device test futuro revelar exceção.
3. **Android — CameraX 1.6.1** pinado (latest stable em 2026-05-26, novo motor CameraPipe). Device test obrigatório em Xiaomi/Samsung antes de RC.
4. **Android PlatformView — hybrid composition.** Necessário para HUD Flutter sobre preview. Custo GPU 5-10% aceito.
5. **iOS format control via `activeFormat`** + `activeVideoMinFrameDuration`/`MaxFrameDuration`. `sessionPreset` insuficiente para garantir 4K@60.
6. **Threading**: HostApi main thread por default; ops pesadas (discovery, format negotiation) via `makeBackgroundTaskQueue()` iOS / Looper main Android. Callbacks Flutter sempre na main thread.
7. **Sem gravação** nesta ADR — boundary explícito com replay_buffer.
8. **Telemetria via camada Flutter apenas.** Bridge nativa não chama Firebase direto. Eventos canônicos em `AnalyticsEvents` (extensão de `api-contract-shared`): `cameraStarted`, `cameraStopped`, `cameraFocusTapped`, `cameraPermissionDenied`, `cameraError` + reuso de `lensSwitched`, `resolutionChanged`, `fpsChanged`.

## Consequências

**Positivas:**
- Bridge testável isoladamente sem replay_buffer
- Strategy única iOS reduz código e teste
- CameraX latest alinha com Blueprint
- Boundary com Firebase preserva testabilidade da bridge

**Negativas:**
- CameraX 1.6 CameraPipe novo — risco de regression em OEMs (mitigado por device test)
- Hybrid composition Android tem custo GPU
- Smooth zoom em virtual camera pode dropar framerate momentâneo (mitigado por device test + rollback documentado)

**Como reverter:** novo ADR substituindo, com revert dos commits desta spec.

## Alternativas consideradas

- Plugin oficial `camera` — rejeitado (briefing 6.2)
- `iris_camera` v1.0.5 — rejeitado (briefing 6.2: baixa adoção)
- `AVCaptureMultiCamSession` — rejeitado (overkill para alternância discreta)
- CameraX 1.5.x — rejeitado (Blueprint pede latest)
- Texture layer Android — rejeitado (HUD precisa overlay)
- 2 strategies iOS (Virtual + Swap) — rejeitado (YAGNI confirmado por matriz hardware)

## Referências

- Spec: docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
- ADRs predecessores: 0013, 0014
- Apple AVFoundation Capture Setup: https://developer.apple.com/documentation/avfoundation/capture_setup/choosing_a_capture_device
- CameraX docs: https://developer.android.com/media/camera/camerax
- CameraX releases: https://developer.android.com/jetpack/androidx/releases/camera
- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels
- Issues: flutter/flutter#91247, flutter/flutter#173406
