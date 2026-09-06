# 0033 — Botão de volume como gatilho de gravação (contrato Pigeon + estratégias nativas)

- **Data:** 2026-09-05
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues
- **Tags:** architecture, native, volume, pigeon
- **Extends:** [0011-volume-control-not-bluetooth.md](0011-volume-control-not-bluetooth.md), [0013-pigeon-theme-tailor-and-anti-drift-gates.md](0013-pigeon-theme-tailor-and-anti-drift-gates.md)

## Contexto

O Settings já persiste `ControlMode.volume`, mas o Pigeon `volume_api.dart` só tem `volumePing()` / `volumeReady()` — handshake vazio. Não existe `VolumeHostApiImpl` em nenhuma plataforma. O card Volume está `enabled: false` ("em breve"): a UI promete o modo e não entrega.

ADR-0011 já decidiu capturar `+`/`−` (não Bluetooth custom). Esta ADR fecha o **contrato**, a **estratégia por plataforma** e o **risco de review** antes de ampliar o schema Pigeon (hook `warn-adr-drift`).

Pesquisa em fonte primária (2026-09-05), não memória de treino:

| Fonte | Achado |
|---|---|
| [AVAudioSession.outputVolume](https://developer.apple.com/documentation/avfaudio/avaudiosession/outputvolume) | Propriedade **read-only**. "Only the user can directly set the system volume." KVO é documentado para *observar*. **Não existe `setOutputVolume`.** |
| Memória `raro-pattern-ios-volume-button-kvo-app-store-review` | Pattern antigo com `session.setOutputVolume(initialVolume)` — **API inventada**. Restaurar volume exigiria `MPVolumeView` (hack de `UISlider` interno) ou API privada. |
| [App Review 2.5.9](https://developer.apple.com/app-store/review/guidelines/) | "Apps that alter or disable the functions of standard switches, such as the Volume Up/Down … will be rejected." |
| [AVCaptureEventInteraction](https://developer.apple.com/documentation/avkit/avcaptureeventinteraction) | API **pública** (iOS 17.2, `API_AVAILABLE(ios(17.2))`) para mapear botões físicos a captura. Só envia eventos com câmera ativa. `isEnabled = false` devolve o volume ao sistema. WWDC25: primary = Volume− / Action / Camera Control; secondary = Volume+. |
| [Activity.onKeyDown](https://developer.android.com/reference/android/app/Activity#onKeyDown(int,%20android.view.KeyEvent)) / `KeyEvent.KEYCODE_VOLUME_UP/DOWN` | API pública. `return true` consome o evento (volume do sistema não muda). Só funciona com a Activity em foco. |

O deployment target do app é iOS 15. `AVCaptureEventInteraction` exige 17.2+.

## Opções consideradas

1. **KVO em `outputVolume` + restore (memória / spec-010)**
   - Prós: funcionaria no iOS 15.
   - Contras: sem API pública para restaurar volume; viola o espírito de 2.5.9; a memória cita método inexistente; briga com `playAndRecord` da câmera/voz (categoria ambient).
2. **Esconder Volume em todo o iOS**
   - Prós: zero risco de review.
   - Contras: perde a feature no iPhone (o dono pediu implementar; o iPhone 12 de teste roda iOS atual).
3. **`AVCaptureEventInteraction` no iOS 17.2+; esconder abaixo; Android via `dispatchKeyEvent`**
   - Prós: API oficial de captura; review-safe; `isEnabled` liga/desliga o sequestro; sem mexer em `AVAudioSession`; Android é API pública e consome o evento.
   - Contras: iOS 15–17.1 sem o modo (paridade honesta).

## Decisão

**Decision (one sentence):** Ampliar o Pigeon `volume` com ciclo start/stop + evento de tecla; Android consome `KEYCODE_VOLUME_*` só enquanto escuta; iOS usa `AVCaptureEventInteraction` (17.2+); abaixo disso o card Volume some da UI.

**Detail:**

### Contrato Pigeon (`volume_api.dart`)

Espelha a voz (ADR-0022), sem handshake vazio:

```dart
enum VolumeDirection { up, down }

@HostApi()
abstract class VolumeHostApi {
  @async
  bool isAvailable();
  void startListening();
  void stopListening();
}

@FlutterApi()
abstract class VolumeFlutterApi {
  void onVolumePressed(VolumeDirection direction);
}
```

- `isAvailable()`: Android = `true`. iOS = `true` só em iOS 17.2+.
- Dart mapeia `up` → start e `down` → stop (ADR-0011) e chama o **mesmo** `_onRecTap` da voz / botão REC. Não é um pipeline novo.
- Escuta só com `ControlMode.volume` **e** câmera visível em foreground. `stopListening` ao sair da câmera / background / trocar o modo. Settings → câmera usa `go` (a tela é disposta).

### Android

`MainActivity.dispatchKeyEvent`: se escutando e `KEYCODE_VOLUME_UP/DOWN` em `ACTION_DOWN` com `repeatCount == 0`, emite o evento e **consome** (`true`). Senão, `super` — o volume do sistema volta ao normal. Só faz sentido com a Activity em foco (não há captura em background; não é pedido).

### iOS

`AVCaptureEventInteraction` no `UIView` do Flutter (`addInteraction`), `isEnabled` ligado só em `startListening`. Primary (Volume−) → `down`; secondary (Volume+) → `up`. Agir em `phase == .ended`. Sem KVO, sem `MPVolumeView`, sem mudar categoria de áudio.

iOS < 17.2: `isAvailable() == false` → card Volume **não renderiza**. Se `ControlMode.volume` estiver persistido, a escuta não liga (no-op). Intro dos Settings cai no texto só-voz.

### Fora desta fatia

- Modal M03 "Controle conectado" (AirPods): ADR-0011 ainda vale como produto; não bloqueia o gatilho. Sem API para distinguir BT vs botão físico no Android; no iOS 26 o stem do AirPods já chega de graça no mesmo `AVCaptureEventInteraction`.
- Voz/Vosk, 16 KB, keystore, replay, gating.

| What | Choice |
|---|---|
| Bridge | Pigeon `volume` (já fixado ^26.3.2) |
| Android | `dispatchKeyEvent` + consume |
| iOS 17.2+ | `AVCaptureEventInteraction` |
| iOS 15–17.1 | UI esconde o modo |

## Consequences

### Positive

- Promessa do Settings deixa de ser falsa no Android e no iOS atual.
- Review iOS usa API que a Apple documenta para câmera (exceção implícita a 2.5.9 para captura).
- Sem conflito de `AVAudioSession` com voz/gravação.

### Negative

- iOS 15–17.1 sem Volume (paridade honesta).
- Android não captura volume com a tela apagada / outra Activity — limite da API, aceito.

### Neutral / open

- `+` inicia e `−` para (não é toggle nos dois botões). Idle+`−` e gravando+`+` são no-op, igual à voz.
- Blueprint §2.2: o channel `volume` passa a carregar evento de tecla, não só o handshake.

## Alternatives considered

### Alternative: KVO + restore de volume

**Why rejected:** `outputVolume` é read-only (doc Apple 2026). Restore sem API pública. Guideline 2.5.9. A memória do projeto descreve `setOutputVolume`, que não existe.

**What we lose:** suporte iOS 15–17.1.

### Alternative: esconder Volume em todo o iOS

**Why rejected:** a API oficial existe e o device de prova iOS roda versão nova. Esconder tudo seria render o iPhone sem a última feature de produto sem necessidade.

**What we lose:** zero risco 2.5.9 (já mitigado pela API oficial).

### Alternative: plugin Flutter de volume button

**Why rejected:** dep nova = ADR de pacote; o projeto implementa bridges nativos (câmera, voz, replay, gallery).

## Implementation notes

- Files: `pigeons/volume_api.dart`, `VolumeHostApiImpl.{kt,swift}`, `MainActivity.dispatchKeyEvent`, `AppDelegate` registro, feature Dart `lib/features/volume/`, Settings card condicional, 3 `.arb`.
- `VolumeApi.g.swift` precisa entrar no `pbxproj` (hoje o `.g.swift` existe e o parity test ignora `Generated/`; sem Sources o Impl não linka).
- Debounce nativo curto no Android contra `repeat` do key hold; iOS só `phase == .ended`.

## Validation

- M54: modo Volume → `+` grava, `−` para; `ffprobe` no vault. Modo voz → volume do sistema. Sair da câmera → volume do sistema.
- iOS 17.2+: mesmo comportamento **ou** card oculto se `isAvailable` for false.
- `flutter analyze` limpo; suíte verde; `flutter build ios --debug --no-codesign`.

## References

- https://developer.apple.com/documentation/avkit/avcaptureeventinteraction
- https://developer.apple.com/documentation/avfaudio/avaudiosession/outputvolume
- https://developer.apple.com/videos/play/wwdc2025/253/
- https://developer.apple.com/app-store/review/guidelines/ (2.5.9)
- https://developer.android.com/reference/android/view/KeyEvent#KEYCODE_VOLUME_UP
- ADR-0011, ADR-0013, Blueprint §1 divergência #4, Blueprint §2.2

## Supersedes / Superseded by

- Supersedes: cláusula tática da spec-010 / memória KVO como implementação iOS
- Extends: ADR-0011 (produto) + ADR-0013 (Pigeon)
