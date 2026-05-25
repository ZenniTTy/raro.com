# 07-NATIVE-BRIDGES — RARO

> 4 Method Channels Dart ↔ Swift/Kotlin. Contratos JSON-serializáveis. Cada bridge tem spec dedicada na Fase 5 antes da implementação. Detalhe técnico em [Blueprint Seção 2.2 e 3.3](Blueprint.md).

## `com.rarocamera/camera`

Responsabilidade: discovery de lentes físicas, alternância 0.5×/1×, resolução, FPS, controles de captura.

| Método (Dart → Native) | Args | Retorno |
|---|---|---|
| `discoverLenses()` | — | `List<{label, focalLengthMm, available}>` |
| `setLens(label)` | `'0.5x'` ou `'1x'` | `void` |
| `setResolution(res)` | `'720p'` / `'1080p'` / `'4K'` / `'4K60'` | `void` |
| `setFps(fps)` | `30` / `60` | `void` |
| `startCapture()` | — | `{recordingId}` |
| `stopCapture()` | — | `{recordingId, filePath, duration}` |

| Evento (Native → Dart) | Payload |
|---|---|
| `onFocusChanged` | `{x, y}` (coords no viewport) |
| `onError` | `{code, message}` |

iOS: `AVCaptureDevice.DiscoverySession` com `builtInUltraWideCamera` + `builtInWideAngleCamera`. `AVCaptureSession` + `AVAssetWriter`.
Android: `CameraSelector.Builder().addCameraFilter()` filtrando por `LENS_INFO_AVAILABLE_FOCAL_LENGTHS`. `MediaCodec` + `MediaMuxer`.

## `com.rarocamera/replay_buffer`

Responsabilidade: buffer circular em RAM dos últimos N segundos. Permite "começar a gravar" com pré-roll.

| Método | Args | Retorno |
|---|---|---|
| `setBufferDuration(seconds)` | `15` ou `30` | `void` |
| `startBuffering()` | — | `void` |
| `stopBuffering()` | — | `void` |
| `saveWithPreroll()` | — | `{recordingId, filePath, prerollSeconds}` |

Estimativa RAM: 15s/1080p ≈ 70MB · 30s/4K ≈ 560MB. Pool de buffers reutilizável para minimizar GC.

## `com.rarocamera/voice`

Responsabilidade: detecção on-device do wake word `"Raro"`.

| Método | Args | Retorno |
|---|---|---|
| `startListening()` | — | `void` |
| `stopListening()` | — | `void` |
| `setWakeWord(word)` | `'Raro'` | `void` |

| Evento | Payload |
|---|---|
| `onWakeDetected` | `{confidence, timestamp}` |
| `onSessionRestart` | `{reason}` (iOS, limite 1min) |
| `onError` | `{code, message}` |

iOS: `SFSpeechRecognizer` configurado para on-device. Android: `SpeechRecognizer` com `EXTRA_PREFER_OFFLINE` (API 31+).

**Privacidade:** áudio nunca sai do device. Privacy Manifest iOS declara uso de speech.

## `com.rarocamera/volume`

Responsabilidade: captura de eventos de botões físicos de volume (modo "Volume OFF" em Settings) + detecção de fones BT que reportam como volume.

| Método | Args | Retorno |
|---|---|---|
| `startVolumeObserver()` | — | `void` |
| `stopVolumeObserver()` | — | `void` |

| Evento | Payload |
|---|---|
| `onVolumeUp` | `{source: 'device' \| 'bluetooth_headphone'}` |
| `onVolumeDown` | `{source}` |
| `onBluetoothControlConnected` | `{deviceName}` (dispara modal M03) |

iOS: observer em `AVAudioSession.outputVolume`, restaura ao valor anterior.
Android: `dispatchKeyEvent(KEYCODE_VOLUME_UP/DOWN)` + `MediaSession`.

## Spec dedicada por bridge

Antes da implementação, cada bridge tem:
- `apps/mobile/lib/core/native_bridges/<bridge>_contract.md` com contrato JSON
- `docs/superpowers/specs/<YYYY-MM-DD>-<bridge>-design.md` com plano

Contract tests em ambas plataformas via `integration_test`.
