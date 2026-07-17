# Spec — Tap-to-focus Android (gesto nativo + ring) — Fatia 2/4 pré-APK

> Data: 2026-07-17 · Status: design aprovado pelo dono
> Contexto: no M54 o toque de foco não funciona. O backend nativo JÁ existe; falta o gesto e o feedback visual.

## 1. Estado atual (mapeado 2026-07-17)

- Contrato Pigeon pronto: `focusAt(FocusPoint)` + `CameraFlutterApi.onFocusChanged(point, locked)` ([pigeons/camera_api.dart](../../../apps/mobile/pigeons/camera_api.dart)).
- Backend Android pronto: [CameraManager.kt:152](../../../apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt) usa `SurfaceOrientedMeteringPointFactory(1f,1f)` + `FocusMeteringAction` + `startFocusAndMetering`.
- Falta: nenhum touch listener no `CameraPlatformView.kt`; nenhum ring; `CameraHostApiImpl.focusAt` reporta `locked=true` imediatamente (mentira otimista).
- Referência iOS: `CameraPlatformView.swift` (UITapGestureRecognizer → showFocusRing → focusAtAsync) + `FocusRingConfig`.

## 2. Design

1. **Toque capturado NO NATIVO** (`CameraPlatformView.kt`): `setOnTouchListener` no `PreviewView` (ACTION_UP). Lição permanente do iOS: com `EagerGestureRecognizer` o tap é entregue à view nativa; `GestureDetector` Flutter pai nunca dispara (memória `raro-pattern-flutter-platformview-tap-must-be-native`, hook de aviso ativo).
2. **MeteringPoint correto**: trocar `SurfaceOrientedMeteringPointFactory(1f,1f)` por **`previewView.meteringPointFactory`** — o factory do próprio PreviewView já compensa rotação, crop e scale type (recomendação oficial CameraX). O `focusAt` do Pigeon (coordenadas normalizadas vindas do Dart, se algum caller Dart usar) converte via fator equivalente.
3. **Ring de foco nativo Android**: View overlay leve adicionada ao FrameLayout do PlatformView (círculo com stroke na cor de acento, animação scale+fade via `ViewPropertyAnimator`, some sozinha ~0.9s) espelhando timing/estilo do `FocusRingConfig` iOS. Nativo porque o toque é nativo — desenhar no ponto exato sem roundtrip.
4. **`onFocusChanged` honesto**: usar o `ListenableFuture<FocusMeteringResult>` de `startFocusAndMetering` — reportar `locked = result.isFocusSuccessful` quando o foco CONCLUIR (e `locked=false` em cancel/fail), em vez do `true` imediato atual.

## 3. Fora de escopo

- Zoom por pinça, exposure slider, foco contínuo custom.
- Qualquer mudança de contrato Pigeon ou `.swift`.
- Ultra-wide (memória `raro-pattern-android-camerax-ultra-wide-unreliable` — inalterado).

## 4. Erros

- `startFocusAndMetering` pode falhar (câmera fechada, foco não suportado): capturar, `Log.w`, reportar `locked=false` — nunca swallow.
- Toque durante `not-ready`: ignorar silenciosamente é aceitável AQUI (câmera nem está na tela) — sem crash.

## 5. Validação (DoD)

1. M54: tap → ring visível no ponto tocado; foco muda perceptivelmente (perto/longe).
2. Kit adb: screencap com ring visível (TextureView COMPATIBLE já permite captura).
3. `onFocusChanged` chega no Dart com `locked` verdadeiro só após conclusão (log adb).
4. Tap funciona em toda a área livre do full-bleed; sobre os controles, o controle tem prioridade (comportamento atual do Stack preservado — sem foco "vazando" por baixo de botão).
5. `analyze` + suíte verdes; sem regressão nos goldens full-bleed.
