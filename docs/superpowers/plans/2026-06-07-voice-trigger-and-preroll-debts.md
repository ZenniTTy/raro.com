# Voice Trigger + Pré-roll Debts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Limpar os 3 débitos do pré-roll embutido (nome, áudio-priming, DTS nas emendas) e ligar o segundo gatilho do save — a voz ("Raro gravar"/"Raro parar") reusando o MESMO fluxo do botão REC.

**Architecture:** Frente A (débitos) mexe só em `ReplayBuffer.swift` + `RecordingPipeline.swift` + 1 linha Dart, sem contrato Pigeon. Frente B (voz) é greenfield: ADR → contrato Pigeon `voice_api` expandido → `VoiceManager.swift` (SFSpeechRecognizer on-device, restart loop, backoff) → `VoiceController` (Riverpod Notifier reativo) → wiring do `controlMode` (já persistido em `RecordingSettings`) ao listener → feedback UI sempre-visível → plug `onWakeDetected`→`RecordingController.toggle()` (toggle extraído do `_onRecTap`, fonte única). Comandos "gravar"/"parar"; "parar" durante REC decidido por device gate (conflito de mic).

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Riverpod 3 codegen · Pigeon · Swift/AVFoundation · SFSpeechRecognizer (on-device) · mocktail · alchemist.

**Estado já existente (NÃO recriar):** `ControlMode { voice, volume }` em `raro_shared`; `RecordingSettings.controlMode` (`@Default(ControlMode.voice)`) já persistido (codec + `StorageKeys.preferredControlMode`); `SettingsController.setControlMode`; UI `_ControlMode`/`ControlModeCard` em `settings_screen.dart` (já renderiza os 2 cards). `VoiceConfig.wakeWord='Raro'` em `raro_shared`. `Info.plist` já tem `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`. Stub Pigeon `voice_api.dart` (`voicePing`/`voiceReady`).

**Gap real da voz:** nada lê `controlMode` na câmera (grep vazio) → listener nunca liga. O trabalho é construir o motor de voz e ligá-lo a esse setting já existente.

---

## File Structure

### Frente A — débitos (nativo + 1 Dart)
- Modify: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift` (A1 nome final `export()`; A2 trim audio priming; A3 retiming/IDR na composition)
- Modify: `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift:33` (A3 `makeReplayVideoSettings` → `AVVideoMaxKeyFrameIntervalKey`)
- Test: `apps/mobile/ios/RunnerTests/ReplayRingTests.swift` (ou novo `ReplayExportSettingsTests.swift`) — A3 pin dos videoSettings
- (A1 sem mudança Dart: `_idFromPath` já lida com prefixo `raro_`; o id passa a ser o UUID puro)

### Frente B — voz
- Modify: `apps/mobile/pigeons/voice_api.dart` (contrato expandido)
- Generated (codegen): `lib/core/native_bridges/generated/voice_api.g.dart` (gitignored), `ios/Runner/Native/Generated/VoiceApi.g.swift`, `android/.../generated/voice/VoiceApi.g.kt`
- Create: `apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift` (SFSpeechRecognizer + restart loop + backoff + command parsing)
- Create: `apps/mobile/ios/Runner/Native/Voice/VoiceHostApiImpl.swift` (bridge HostApi → VoiceManager)
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift` (registrar VoiceHostApi + FlutterApi)
- Create: `apps/mobile/ios/RunnerTests/VoiceManagerTests.swift` (+ 4 inserções pbxproj)
- Create: `apps/mobile/lib/features/voice/domain/voice_state.dart` (sealed `VoiceState`)
- Create: `apps/mobile/lib/features/voice/domain/wake_command.dart` (enum espelho do Pigeon — ou usar o gerado)
- Create: `apps/mobile/lib/features/voice/application/voice_flutter_api_provider.dart` (stream de eventos, padrão do `camera_flutter_api_provider`)
- Create: `apps/mobile/lib/features/voice/application/voice_controller.dart` (`@riverpod` Notifier)
- Create: `apps/mobile/lib/features/voice/data/voice_repository.dart` + provider (porta sobre VoiceHostApi, mockável)
- Create: `apps/mobile/lib/features/voice/presentation/voice_listening_indicator.dart` (widget feedback)
- Modify: `apps/mobile/lib/features/camera/application/recording_controller.dart` (novo método `toggle(...)`)
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart` (`_onRecTap` chama `toggle`; mostra indicador; escuta wake)
- Modify: `apps/mobile/lib/features/settings/presentation/settings_screen.dart` + `control_mode_card.dart` (Volume desabilitado "em breve")
- Tests: `apps/mobile/test/features/camera/recording_controller_toggle_test.dart`, `apps/mobile/test/features/voice/voice_controller_test.dart`, `apps/mobile/test/features/voice/voice_listening_indicator_test.dart`, `apps/mobile/test/features/settings/control_mode_disabled_test.dart`

---

# FRENTE A — Débitos do pré-roll

## Task A1: Nome do combinado no vault (`raro_<UUID>.mp4`)

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift:329-330`

**Contexto:** hoje `export()` gera `raro_replay_<UUID>.mp4`; o `_idFromPath` Dart strip `raro_` → id `replay_<UUID>` → vault salva `replay_<UUID>.mp4`. O G1 recording já usa o padrão `raro_<sessionId>.mp4` (`RecordingPipeline.makeOutputURL`). Alinhar o combinado a esse padrão = remover o infixo `replay_`. Os chunks intermediários (linha 185, `raro_replay_<index>.mp4`) ficam intactos (são `tmp/` descartáveis e devem permanecer reconhecíveis).

- [ ] **Step 1: Editar o nome do output final**

Em `ReplayBuffer.swift`, linha ~329-330, trocar:

```swift
    let outURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("raro_replay_\(UUID().uuidString).mp4")
```

por:

```swift
    let outURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("raro_\(UUID().uuidString).mp4")
```

- [ ] **Step 2: Verificar que `_idFromPath` continua correto (sem mudança Dart)**

Run: `cd apps/mobile && grep -n "startsWith('raro_')" lib/features/camera/application/camera_flutter_api_provider.dart`
Expected: a linha `return stem.startsWith('raro_') ? stem.substring(5) : stem;` — com o novo nome `raro_<UUID>.mp4` o stem vira `raro_<UUID>`, strip de `raro_` → id `<UUID>` puro. Correto, sem edição.

- [ ] **Step 3: Compilar para simulator (smoke nativo)**

Run:
```bash
cd apps/mobile && flutter build ios --simulator --no-codesign 2>&1 | tail -5
```
Expected: `Xcode build done` sem erro de compilação no `ReplayBuffer.swift`.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift
git commit -m "fix(replay): combinado salva como raro_<uuid>.mp4 (sem infixo replay_)"
```

---

## Task A2: IDR por chunk nos videoSettings do replay (base do A3)

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift:33-38`
- Test: `apps/mobile/ios/RunnerTests/ReplayExportSettingsTests.swift` (novo)

**Contexto:** os chunks de 1s do ring são escritos por writers independentes; sem keyframe garantido no início de cada chunk, a emenda na composition gera DTS não-monotônico (A3) e micro-glitch no 1º frame. Forçar IDR por chunk via `AVVideoMaxKeyFrameIntervalKey=1` (1 keyframe a cada 1 frame no limite, ou alinhado ao chunk) nas compression properties faz cada chunk começar decodável e a emenda ficar limpa.

> **Decisão técnica:** usar `AVVideoMaxKeyFrameIntervalDurationKey = chunkSeconds` garante ≥1 IDR por chunk sem inflar bitrate como `=1` faria. Como o ring usa `chunkSeconds=1`, o valor é `1.0`. Isso é o mínimo que resolve a emenda (Simplicity First).

- [ ] **Step 1: Escrever o teste que falha (pin dos compression properties)**

Criar `apps/mobile/ios/RunnerTests/ReplayExportSettingsTests.swift`:

```swift
import AVFoundation
import XCTest
@testable import Runner

final class ReplayExportSettingsTests: XCTestCase {
  func testReplayVideoSettingsForcesKeyframePerChunk() throws {
    let props = RecordingPipeline.injectKeyframeInterval(
      into: [AVVideoCodecKey: AVVideoCodecType.hevc],
      chunkSeconds: 1
    )
    let compression = props[AVVideoCompressionPropertiesKey] as? [String: Any]
    XCTAssertNotNil(compression, "compression properties must exist")
    let maxKeyFrameDuration =
      compression?[AVVideoMaxKeyFrameIntervalDurationKey as String] as? Double
    XCTAssertEqual(maxKeyFrameDuration, 1.0, "must force ≥1 IDR per 1s chunk")
  }
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `bun run --filter '@raro/mobile' test:ios 2>&1 | grep -E "ReplayExportSettings|error:|Compiling"`
Expected: FALHA de compilação — `injectKeyframeInterval` não existe.

> Se o XCTest novo "sumir" silenciosamente (verde sem rodar), aplicar as 4 inserções no `project.pbxproj` (memória `raro-pattern-ios-xctest-pbxproj-4-insertions`): PBXBuildFile, PBXFileReference, PBXGroup, Sources phase. Confirmar via `Test Suite 'ReplayExportSettingsTests' started` no output.

- [ ] **Step 3: Implementar `injectKeyframeInterval` + usar em `makeReplayVideoSettings`**

Em `RecordingPipeline.swift`, adicionar o helper estático e usá-lo no `makeReplayVideoSettings`:

```swift
  static func injectKeyframeInterval(
    into settings: [String: Any],
    chunkSeconds: Int
  ) -> [String: Any] {
    var result = settings
    var compression = (result[AVVideoCompressionPropertiesKey] as? [String: Any]) ?? [:]
    compression[AVVideoMaxKeyFrameIntervalDurationKey as String] = Double(chunkSeconds)
    result[AVVideoCompressionPropertiesKey] = compression
    return result
  }

  func makeReplayVideoSettings() -> [String: Any] {
    var settings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4) ?? [:]
    settings[AVVideoCodecKey] = Self.selectCodec(
      requested: requestedCodec, available: videoOutput.availableVideoCodecTypes)
    return Self.injectKeyframeInterval(into: settings, chunkSeconds: 1)
  }
```

> Nota: `1` casa com o `chunkSeconds` do ring. Se o ring mudar o tamanho do chunk no futuro, esse `1` deve acompanhar — deixar comentário NÃO (produção sem comentário); o acoplamento fica documentado aqui no plan/ADR.

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `bun run --filter '@raro/mobile' test:ios 2>&1 | grep -E "ReplayExportSettings.*passed|Test Suite 'ReplayExportSettingsTests'"`
Expected: `Test Suite 'ReplayExportSettingsTests' ... passed`.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift apps/mobile/ios/RunnerTests/ReplayExportSettingsTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "fix(replay): força idr por chunk (maxkeyframeintervalduration) p/ emenda limpa"
```

---

## Task A3: Retiming explícito na composition (DTS monotônico) + trim do áudio-priming

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift:298-323` (export composition loop)

**Contexto:** mesmo com IDR por chunk, o `insertTimeRange` usa `asset.duration` por chunk; se um chunk tiver áudio mais curto que o vídeo (priming AAC ~350ms no 1º chunk), o cursor de áudio e vídeo divergem na emenda → DTS warning + o gap inicial de áudio (A2). Mitigação combinada: (1) inserir vídeo e áudio com o MESMO range derivado da trilha de vídeo (fonte de verdade do tempo), e (2) no 1º chunk, alinhar o início do áudio descartando o priming (`CMTimeRange` começando após o priming OU deixar o vídeo mandar e o áudio entrar a partir do seu 1º sample real). A abordagem mínima e robusta: usar a duração da trilha de VÍDEO como range canônico para ambos, evitando o desalinhamento que gera o DTS não-monotônico.

> **Por que isso resolve A2 e A3 juntos:** o áudio-priming e o DTS não-monotônico têm a mesma raiz — trilhas de áudio e vídeo com durações ligeiramente diferentes por chunk, inseridas com ranges independentes. Ancorar ambos no tempo da trilha de vídeo (e clampar o range de áudio ao que existe) elimina o desalinhamento progressivo. O gap de ~350ms no 1º chunk vira no máximo um silêncio curtíssimo no exato início, sem propagar.

- [ ] **Step 1: Reescrever o loop de inserção do `export()` ancorando no tempo do vídeo**

Em `ReplayBuffer.swift`, substituir o bloco do loop (linhas ~303-323) por:

```swift
    var cursor = CMTime.zero
    for chunk in chunks {
      let asset = AVURLAsset(url: chunk.url)
      guard let assetVideo = asset.tracks(withMediaType: .video).first else {
        os_log("replay export skipping chunk without video track: %{public}@",
               log: replayLog, type: .error, chunk.url.lastPathComponent)
        continue
      }
      let videoDuration = assetVideo.timeRange.duration
      let videoRange = CMTimeRange(start: assetVideo.timeRange.start, duration: videoDuration)
      do {
        try videoTrack?.insertTimeRange(videoRange, of: assetVideo, at: cursor)
        if let assetAudio = asset.tracks(withMediaType: .audio).first {
          let audioAvailable = assetAudio.timeRange
          let clampedDuration = CMTimeMinimum(videoDuration, audioAvailable.duration)
          let audioRange = CMTimeRange(start: audioAvailable.start, duration: clampedDuration)
          try audioTrack?.insertTimeRange(audioRange, of: assetAudio, at: cursor)
        }
        cursor = CMTimeAdd(cursor, videoDuration)
      } catch {
        os_log("replay export insert failed for chunk %{public}@: %{public}@",
               log: replayLog, type: .error,
               chunk.url.lastPathComponent, error.localizedDescription)
      }
    }
```

> Mudanças vs original: range ancorado em `assetVideo.timeRange` (não `asset.duration`); áudio clampado ao mínimo entre vídeo e áudio disponível (impede o áudio mais longo/curto de empurrar o cursor); cursor avança pela duração do VÍDEO sempre. Isto mantém a timeline monotônica.

- [ ] **Step 2: Compilar para simulator**

Run: `cd apps/mobile && flutter build ios --simulator --no-codesign 2>&1 | tail -5`
Expected: `Xcode build done` sem erro.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift
git commit -m "fix(replay): retiming ancorado no vídeo na composition — dts monotônico + alinha áudio"
```

- [ ] **Step 4: GATE §10 device (PAUSAR — avisar usuário p/ conectar iPhone 12)**

> ⚠️ **PARAR AQUI e avisar o usuário** que a próxima etapa é manual no iPhone 12. Não prosseguir sem confirmação + device conectado.

Quando autorizado, com `<udid>` do iPhone 12:
```bash
cd apps/mobile && flutter clean && bun run --filter '@raro/mobile' pub:get
GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --profile 2>&1 | tail -8   # conferir "✓ Built" + timestamp do .app
xcrun devicectl device install app --device <udid> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <udid> com.rarocamera
```
Validação manual: armar buffer (pill 30s) → REC → parar (~5s) → puxar o vault:
```bash
xcrun devicectl device copy from --device <udid> --domain-type appDataContainer \
  --domain-identifier com.rarocamera --source Documents/vault/<id>.mp4 --destination /tmp/a3.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate /tmp/a3.mp4
ffmpeg -v warning -i /tmp/a3.mp4 -f null - 2>&1 | grep -i "non monotonically" || echo "DTS OK (sem warning)"
ffprobe -v error -select_streams a:0 -show_entries stream=start_time,duration /tmp/a3.mp4
```
Expected: dims/fps reais do REC; **sem** warning de DTS não-monotônico (A3 fechado); `start_time` do áudio ~0 (A2 mitigado). Anexar saídas ao PR (gate §10/ADR-0021).

---

# FRENTE B — Voz

## Task B0: ADR da voz (gate antes de qualquer codegen)

**Files:**
- Create: `docs/decisions/0022-voice-on-device-sfspeechrecognizer.md`

**Contexto:** a Frente B expande o contrato Pigeon `voice_api.dart` (toca `apps/mobile/pigeons/*.dart` → dispara `warn-adr-drift`). ADR DEVE estar no branch antes do codegen.

- [ ] **Step 1: Escrever o ADR**

Criar `docs/decisions/0022-voice-on-device-sfspeechrecognizer.md` seguindo o formato dos ADRs existentes (cabeçalho Data/Status/Relaciona/Decisores/Contexto; Opções consideradas; Decisão; Consequências; Reversão). Conteúdo-chave a cobrir:
- **Engine:** SFSpeechRecognizer `requiresOnDeviceRecognition=true` (sem lib paga). Justificativa: dump do concorrente (memória `raro-competitor-okcamera-replay-model`) prova que o equivalente nativo Android resolve sem custo recorrente — conflitaria com R$9,90/mês. Porcupine/Whisper = v2.0 atrás de ADR se métricas ruins.
- **Modelo:** selecionável (Voz/Volume), default Voz ON (fiel ao protótipo + ADR-0009), NÃO default-sempre-on-escondido como o concorrente (consertar a "escuta escondida").
- **Ciclo:** restart loop antes do teto de 1 min, backoff exponencial, estado `paused` sempre visível (nunca silencioso).
- **Foreground-only no iOS** (background inviável sem entitlement Apple).
- **Comandos:** "Raro gravar"/"Raro parar"; "parar" durante REC condicionado a device gate (conflito mic).
- **Contrato:** expansão de `voice_api` (start/stop/isAvailable + onWakeDetected(WakeCommand)/onListeningStateChanged).
- **Relaciona:** ADR-0009 (wake word), ADR-0011 (volume = modo alternativo, Sprint 3).

- [ ] **Step 2: Rodar adr-guardian (validação independente)**

Dispatch subagent `adr-guardian` com o diff do ADR + a mudança planejada do `voice_api.dart`. Expected: GO (ADR cobre engine, modelo, contrato, foreground-only, comandos).

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0022-voice-on-device-sfspeechrecognizer.md
git commit -m "docs(voice): adr-0022 voz on-device sfspeechrecognizer (modo selecionável, foreground)"
```

---

## Task B1: Contrato Pigeon `voice_api` expandido + codegen

**Files:**
- Modify: `apps/mobile/pigeons/voice_api.dart`

- [ ] **Step 1: Reescrever o contrato**

Substituir o conteúdo de `apps/mobile/pigeons/voice_api.dart` (preservando o bloco `@ConfigurePigeon`) — trocar o `@HostApi`/`@FlutterApi` por:

```dart
enum WakeCommand { start, stop }

enum VoiceListeningState { idle, listening, paused, unavailable }

@HostApi()
abstract class VoiceHostApi {
  @async
  bool isAvailable();
  void startListening();
  void stopListening();
}

@FlutterApi()
abstract class VoiceFlutterApi {
  void onWakeDetected(WakeCommand command);
  void onListeningStateChanged(VoiceListeningState state);
}
```

> Manter o `@ConfigurePigeon(...)` exatamente como está (paths de saída Dart/Swift/Kotlin).

- [ ] **Step 2: Rodar codegen Pigeon**

Run: `cd apps/mobile && dart run pigeon --input pigeons/voice_api.dart 2>&1 | tail -5`
Expected: regenera `voice_api.g.dart` (gitignored), `VoiceApi.g.swift`, `VoiceApi.g.kt` sem erro.

- [ ] **Step 3: Verificar geração**

Run: `grep -l "WakeCommand\|VoiceListeningState\|onWakeDetected" apps/mobile/ios/Runner/Native/Generated/VoiceApi.g.swift apps/mobile/lib/core/native_bridges/generated/voice_api.g.dart`
Expected: ambos os arquivos listados.

- [ ] **Step 4: Compilar (Dart analyze + simulator)**

Run: `bun run --filter '@raro/mobile' analyze 2>&1 | tail -3 && cd apps/mobile && flutter build ios --simulator --no-codesign 2>&1 | tail -3`
Expected: analyze 0 issues; build done (o Swift gerado compila mesmo sem impl ainda? — não: precisa do registro. Se falhar por símbolo ausente, seguir B2/B3 antes de buildar; rodar só `analyze` neste step).

> Ajuste: neste step rodar **apenas** `bun run --filter '@raro/mobile' analyze` (o build iOS completo vem após B3 quando a impl existe).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/pigeons/voice_api.dart apps/mobile/ios/Runner/Native/Generated/VoiceApi.g.swift apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/voice/VoiceApi.g.kt
git commit -m "feat(voice): contrato pigeon voice_api (start/stop/isavailable + onwake/onstate)"
```

---

## Task B2: Domain Dart — `VoiceState` + porta do repositório

**Files:**
- Create: `apps/mobile/lib/features/voice/domain/voice_state.dart`
- Create: `apps/mobile/lib/features/voice/data/voice_repository.dart`
- Test: `apps/mobile/test/features/voice/voice_state_test.dart`

- [ ] **Step 1: Escrever o teste de `VoiceState` (pin dos estados)**

Criar `apps/mobile/test/features/voice/voice_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';

void main() {
  test('VoiceState tem os 4 estados distintos', () {
    expect(const VoiceIdle(), isA<VoiceState>());
    expect(const VoiceListening(), isA<VoiceState>());
    expect(const VoicePaused(), isA<VoiceState>());
    expect(const VoiceUnavailable(), isA<VoiceState>());
    expect(const VoiceListening() == const VoiceListening(), isTrue);
    expect(const VoiceListening() == const VoiceIdle(), isFalse);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/voice/voice_state_test.dart`
Expected: FAIL — `voice_state.dart` não existe.

- [ ] **Step 3: Implementar `VoiceState`**

Criar `apps/mobile/lib/features/voice/domain/voice_state.dart`:

```dart
sealed class VoiceState {
  const VoiceState();
}

class VoiceIdle extends VoiceState {
  const VoiceIdle();
  @override
  bool operator ==(Object other) => other is VoiceIdle;
  @override
  int get hashCode => (VoiceIdle).hashCode;
}

class VoiceListening extends VoiceState {
  const VoiceListening();
  @override
  bool operator ==(Object other) => other is VoiceListening;
  @override
  int get hashCode => (VoiceListening).hashCode;
}

class VoicePaused extends VoiceState {
  const VoicePaused();
  @override
  bool operator ==(Object other) => other is VoicePaused;
  @override
  int get hashCode => (VoicePaused).hashCode;
}

class VoiceUnavailable extends VoiceState {
  const VoiceUnavailable();
  @override
  bool operator ==(Object other) => other is VoiceUnavailable;
  @override
  int get hashCode => (VoiceUnavailable).hashCode;
}
```

- [ ] **Step 4: Definir a porta do repositório (interface mockável)**

Criar `apps/mobile/lib/features/voice/data/voice_repository.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';

abstract interface class VoiceRepository {
  Future<bool> isAvailable();
  void startListening();
  void stopListening();
}

class PigeonVoiceRepository implements VoiceRepository {
  PigeonVoiceRepository(this._api);
  final VoiceHostApi _api;

  @override
  Future<bool> isAvailable() => _api.isAvailable();
  @override
  void startListening() => _api.startListening();
  @override
  void stopListening() => _api.stopListening();
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/voice/voice_state_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/voice/domain/voice_state.dart apps/mobile/lib/features/voice/data/voice_repository.dart apps/mobile/test/features/voice/voice_state_test.dart
git commit -m "feat(voice): domain voicestate + porta voicerepository"
```

---

## Task B3: Native `VoiceManager.swift` + HostApi impl + registro

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift`
- Create: `apps/mobile/ios/Runner/Native/Voice/VoiceHostApiImpl.swift`
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift`
- Create: `apps/mobile/ios/RunnerTests/VoiceManagerTests.swift` (+ 4 inserções pbxproj)

**Contexto:** SFSpeechRecognizer com `requiresOnDeviceRecognition=true`, `AVAudioEngine` para o tap de áudio, partial results comparados com os comandos. O parsing do comando é puro (testável sem device); a sessão de reconhecimento não. Separar o parser do recognizer para testar o parser em XCTest.

- [ ] **Step 1: Escrever o XCTest do parser de comando (puro, testável)**

Criar `apps/mobile/ios/RunnerTests/VoiceManagerTests.swift`:

```swift
import XCTest
@testable import Runner

final class VoiceManagerTests: XCTestCase {
  func testParserMatchesGravarStart() {
    XCTAssertEqual(VoiceCommandParser.parse("raro gravar", wakeWord: "Raro"), .start)
    XCTAssertEqual(VoiceCommandParser.parse("Raro, começar a gravar", wakeWord: "Raro"), .start)
  }
  func testParserMatchesPararStop() {
    XCTAssertEqual(VoiceCommandParser.parse("raro parar", wakeWord: "Raro"), .stop)
  }
  func testParserIgnoresNonCommand() {
    XCTAssertNil(VoiceCommandParser.parse("que dia raro hoje", wakeWord: "Raro"))
    XCTAssertNil(VoiceCommandParser.parse("gravar sem wake", wakeWord: "Raro"))
  }
}
```

> O enum de retorno do parser deve mapear para o `WakeCommand` do Pigeon (`.start`/`.stop`).

- [ ] **Step 2: Rodar e ver falhar (+ 4 inserções pbxproj se sumir)**

Run: `bun run --filter '@raro/mobile' test:ios 2>&1 | grep -E "VoiceManagerTests|error:|VoiceCommandParser"`
Expected: FALHA — `VoiceCommandParser` não existe. Se a suite "sumir" (verde sem rodar), aplicar 4 inserções pbxproj (memória) p/ `VoiceManagerTests.swift` e confirmar `Test Suite 'VoiceManagerTests' started`.

- [ ] **Step 3: Implementar `VoiceCommandParser` + `VoiceManager`**

Criar `apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift`:

```swift
import AVFoundation
import Speech
import os.log

private let voiceLog = OSLog(subsystem: "com.rarocamera/voice", category: "wake")

enum VoiceCommand {
  case start
  case stop
}

enum VoiceCommandParser {
  static func parse(_ transcript: String, wakeWord: String) -> VoiceCommand? {
    let lower = transcript.lowercased()
    let wake = wakeWord.lowercased()
    guard lower.contains(wake) else { return nil }
    if lower.contains("parar") || lower.contains("encerrar") {
      return .stop
    }
    if lower.contains("gravar") || lower.contains("começar") || lower.contains("comecar") {
      return .start
    }
    return nil
  }
}

final class VoiceManager: NSObject {
  var onCommand: ((VoiceCommand) -> Void)?
  var onStateChanged: ((VoiceListeningStateValue) -> Void)?

  private let wakeWord: String
  private let recognizer: SFSpeechRecognizer?
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var wantsListening = false
  private var backoff: TimeInterval = 0
  private let queue = DispatchQueue(label: "com.rarocamera.voice")

  init(wakeWord: String, locale: Locale = Locale(identifier: "pt-BR")) {
    self.wakeWord = wakeWord
    self.recognizer = SFSpeechRecognizer(locale: locale)
    super.init()
  }

  func isAvailable(_ completion: @escaping (Bool) -> Void) {
    SFSpeechRecognizer.requestAuthorization { status in
      let speechOk = status == .authorized
      let onDevice = self.recognizer?.supportsOnDeviceRecognition ?? false
      AVAudioApplication.requestRecordPermission { micOk in
        completion(speechOk && onDevice && micOk)
      }
    }
  }

  func start() {
    queue.async {
      self.wantsListening = true
      self.beginSession()
    }
  }

  func stop() {
    queue.async {
      self.wantsListening = false
      self.teardown()
      DispatchQueue.main.async { self.onStateChanged?(.idle) }
    }
  }

  private func beginSession() {
    guard wantsListening else { return }
    guard let recognizer = recognizer, recognizer.isAvailable else {
      DispatchQueue.main.async { self.onStateChanged?(.unavailable) }
      scheduleRestart()
      return
    }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.requiresOnDeviceRecognition = true
      request.shouldReportPartialResults = true
      self.request = request

      let input = audioEngine.inputNode
      let format = input.outputFormat(forBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        self?.request?.append(buffer)
      }
      audioEngine.prepare()
      try audioEngine.start()

      self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
        guard let self = self else { return }
        if let result = result,
           let cmd = VoiceCommandParser.parse(result.bestTranscription.formattedString, wakeWord: self.wakeWord) {
          os_log("wake matched: %{public}@", log: voiceLog, type: .info, "\(cmd)")
          DispatchQueue.main.async { self.onCommand?(cmd) }
          self.queue.async { self.restartSession() }
          return
        }
        if error != nil || (result?.isFinal ?? false) {
          self.queue.async { self.restartSession() }
        }
      }
      backoff = 0
      DispatchQueue.main.async { self.onStateChanged?(.listening) }
    } catch {
      os_log("voice session error: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      teardown()
      scheduleRestart()
    }
  }

  private func restartSession() {
    teardown()
    guard wantsListening else { return }
    beginSession()
  }

  private func scheduleRestart() {
    guard wantsListening else { return }
    backoff = min(max(backoff * 2, 1), 60)
    queue.asyncAfter(deadline: .now() + backoff) { [weak self] in
      self?.beginSession()
    }
  }

  private func teardown() {
    task?.cancel(); task = nil
    request?.endAudio(); request = nil
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
  }
}
```

> `VoiceListeningStateValue` é o enum gerado pelo Pigeon (`VoiceListeningState`). Se o nome gerado divergir, ajustar o typealias. A categoria `.playAndRecord` é o ponto de risco do conflito de mic durante REC — o gate B-mic decide.

- [ ] **Step 4: Implementar o HostApi impl que liga VoiceManager ao Flutter**

Criar `apps/mobile/ios/Runner/Native/Voice/VoiceHostApiImpl.swift`:

```swift
import Foundation

final class VoiceHostApiImpl: NSObject, VoiceHostApi {
  private let manager: VoiceManager
  private let flutterApi: VoiceFlutterApi

  init(manager: VoiceManager, flutterApi: VoiceFlutterApi) {
    self.manager = manager
    self.flutterApi = flutterApi
    super.init()
    manager.onCommand = { [weak self] cmd in
      self?.flutterApi.onWakeDetected(command: cmd == .start ? .start : .stop) { _ in }
    }
    manager.onStateChanged = { [weak self] state in
      self?.flutterApi.onListeningStateChanged(state: state) { _ in }
    }
  }

  func isAvailable(completion: @escaping (Result<Bool, Error>) -> Void) {
    manager.isAvailable { ok in completion(.success(ok)) }
  }
  func startListening() throws { manager.start() }
  func stopListening() throws { manager.stop() }
}
```

> As assinaturas exatas (`completion`/`throws`, labels) devem casar com o `VoiceApi.g.swift` gerado — conferir o gerado e ajustar. O `onStateChanged` recebe e repassa o enum gerado diretamente; se `VoiceManager` usa um typealias, alinhar.

- [ ] **Step 5: Registrar no `AppDelegate.swift`**

Em `AppDelegate.swift`, no setup dos channels (seguir o padrão do registro do `CameraHostApi`), adicionar:

```swift
    let voiceFlutterApi = VoiceFlutterApi(binaryMessenger: controller.binaryMessenger)
    let voiceManager = VoiceManager(wakeWord: "Raro")
    let voiceHost = VoiceHostApiImpl(manager: voiceManager, flutterApi: voiceFlutterApi)
    VoiceHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: voiceHost)
```

> Conferir o nome exato do setup gerado (`VoiceHostApiSetup.setUp` vs `setUpVoiceHostApi`) no `VoiceApi.g.swift`. Manter `voiceManager`/`voiceHost` retidos (property do AppDelegate) p/ não serem desalocados.

- [ ] **Step 6: Rodar XCTest do parser + build simulator**

Run: `bun run --filter '@raro/mobile' test:ios 2>&1 | grep -E "VoiceManagerTests.*passed|Test Suite 'VoiceManagerTests'"`
Then: `cd apps/mobile && flutter build ios --simulator --no-codesign 2>&1 | tail -5`
Expected: parser tests passam; build done.

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Voice/ apps/mobile/ios/Runner/AppDelegate.swift apps/mobile/ios/RunnerTests/VoiceManagerTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(voice): voicemanager sfspeechrecognizer on-device + restart loop + hostapi"
```

---

## Task B4: `RecordingController.toggle()` — extrair a fonte única do save

**Files:**
- Modify: `apps/mobile/lib/features/camera/application/recording_controller.dart`
- Test: `apps/mobile/test/features/camera/recording_controller_toggle_test.dart`

**Contexto:** hoje a decisão start-vs-stop + montagem do `RecordingOptions` (com pré-roll quando armado) vive no `_onRecTap` da UI. Extrair para `toggle()` no controller torna botão e voz o mesmo caminho. Pin do comportamento atual ANTES de mover.

- [ ] **Step 1: Escrever os testes do `toggle()` (pin do comportamento)**

Criar `apps/mobile/test/features/camera/recording_controller_toggle_test.dart`. Cobrir: (a) idle → chama `repo.startRecording` com options montadas; (b) active → chama `repo.stopRecording`; (c) options carregam `includeReplayPreroll=true` quando armado, `false` quando não. Usar mocktail no `CameraRepository` (seguir o padrão do `recording_controller_test` existente).

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
// imports do harness de provider do projeto (ver recording_controller_test existente)

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  setUpAll(() => registerFallbackValue(
    RecordingOptions(resolution: Resolution.fullHd1080, fps: Fps.fps60, codec: 'h265', includeReplayPreroll: false),
  ));

  test('toggle a partir de idle inicia gravação com options', () async {
    // arrange controller com repo mockado e replayArmed=false
    // act: await controller.toggle(options: <as do _onRecTap>)
    // assert: verify(() => repo.startRecording(captureAny())) e o captured.includeReplayPreroll == false
  });

  test('toggle com buffer armado passa includeReplayPreroll=true', () async {
    // assert captured.includeReplayPreroll == true
  });

  test('toggle a partir de active para a gravação', () async {
    // arrange estado RecordingActive; act toggle; assert verify(() => repo.stopRecording())
  });
}
```

> Completar o arrange seguindo EXATAMENTE o padrão de `apps/mobile/test/features/camera/recording_controller_test.dart` (ProviderContainer + overrides). O implementer deve abrir esse arquivo e espelhar o setup.

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/camera/recording_controller_toggle_test.dart`
Expected: FAIL — `toggle` não existe.

- [ ] **Step 3: Implementar `toggle()` no controller**

Em `recording_controller.dart`, adicionar (mantendo `start`/`stop` que `toggle` reusa):

```dart
  Future<void> toggle({required RecordingOptions options}) async {
    final current = state;
    if (current is RecordingActive || current is RecordingStarting) {
      await stop();
    } else {
      await start(options);
    }
  }
```

> `toggle` NÃO decide pré-roll — o caller monta `options` (a câmera sabe `_format` e `replayArmed`). Isso mantém o controller agnóstico de UI. A "fonte única" é o toggle start/stop; a montagem de options fica num helper compartilhado (Step 4).

- [ ] **Step 4: Extrair o builder de options para reuso (câmera + voz)**

No `camera_screen.dart`, refatorar `_onRecTap` para usar `toggle` e extrair a montagem de options. Substituir o corpo do `else` (linhas ~155-171) de forma que tanto o tap quanto o wake chamem:

```dart
  RecordingOptions _buildRecordingOptions() {
    final replayState = ref.read(replayBufferControllerProvider);
    final replayArmed = replayState is ReplayBuffering;
    return RecordingOptions(
      resolution: _format.resolution,
      fps: _format.fps,
      codec: Codec.h265.label,
      includeReplayPreroll: replayArmed,
    );
  }

  Future<void> _onRecTap() async {
    final notifier = ref.read(recordingControllerProvider.notifier);
    final phase = ref.read(recordingControllerProvider);
    final wasActive = phase is RecordingActive || phase is RecordingStarting;
    try {
      if (!wasActive) {
        final replayState = ref.read(replayBufferControllerProvider);
        _recordingHadPreroll = replayState is ReplayBuffering;
        _recordingPrerollSeconds =
            replayState is ReplayBuffering ? replayState.seconds : null;
      }
      await notifier.toggle(options: _buildRecordingOptions());
      if (wasActive) {
        _stopElapsedTimer();
      } else {
        _elapsed = Duration.zero;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _elapsed += const Duration(seconds: 1));
        });
      }
    } on PlatformException catch (e) {
      _stopElapsedTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cameraErrorMessage(mapPigeonErrorCode(e.code)))),
      );
    } on Object catch (_) {
      _stopElapsedTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falha ao gravar')));
    }
  }
```

> `toggle` com options ignora options no caso de stop (start não roda) — aceitável (Simplicity First); `_buildRecordingOptions` é barato. O timer/preroll-confirmation continua na UI (efeito colateral de apresentação, não pertence ao controller).

- [ ] **Step 5: Rodar testes (toggle + recording_controller existente, sem regressão)**

Run: `cd apps/mobile && flutter test test/features/camera/recording_controller_toggle_test.dart test/features/camera/recording_controller_test.dart`
Expected: todos PASS (toggle novo verde; os 10 existentes sem regressão).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/camera/application/recording_controller.dart apps/mobile/lib/features/camera/presentation/camera_screen.dart apps/mobile/test/features/camera/recording_controller_toggle_test.dart
git commit -m "refactor(camera): extrai recordingcontroller.toggle como fonte única do save"
```

---

## Task B5: `VoiceController` — Notifier reativo que liga listener ao setting e pluga wake→toggle

**Files:**
- Create: `apps/mobile/lib/features/voice/application/voice_flutter_api_provider.dart`
- Create: `apps/mobile/lib/features/voice/application/voice_controller.dart`
- Create: `apps/mobile/lib/features/voice/data/voice_repository_provider.dart`
- Test: `apps/mobile/test/features/voice/voice_controller_test.dart`

**Contexto:** padrão obrigatório `raro-pattern-flutter-async-native-state-needs-notifier`. O controller escuta o stream do `VoiceFlutterApi` no `build`, expõe `VoiceState`, liga/desliga o recognizer conforme `settingsController.controlMode`, e no `onWakeDetected` chama `RecordingController.toggle`. Cuidado `raro-pattern-riverpod-ref-after-dispose-async-listener`: ler deps síncronas no build, `if (ref.mounted)` após await.

- [ ] **Step 1: Provider do stream do FlutterApi (espelhar `camera_flutter_api_provider`)**

Criar `apps/mobile/lib/features/voice/application/voice_flutter_api_provider.dart` com um `StreamController` que recebe `onWakeDetected`/`onListeningStateChanged` do `VoiceFlutterApi` gerado e expõe dois streams (ou um stream de eventos selados). Seguir EXATAMENTE o padrão de `camera_flutter_api_provider.dart` (classe `_VoiceFlutterApi implements VoiceFlutterApi`, registro via `VoiceFlutterApi.setUp`... — conferir o gerado; no iOS o setUp é nativo, então no Dart o app é o **host** do FlutterApi: o Dart implementa `VoiceFlutterApi` e registra via `VoiceFlutterApi.setUp(binaryMessenger, ...)`).

> Definir um tipo de evento selado `VoiceEvent` = `WakeEvent(WakeCommand)` | `StateEvent(VoiceListeningState)` para um único stream, OU dois providers. Escolha: dois providers (`voiceWakeEventsProvider`, `voiceStateEventsProvider`) — mais simples de testar. O implementer espelha o `recordingEventsProvider`.

- [ ] **Step 2: Escrever o teste do `VoiceController`**

Criar `apps/mobile/test/features/voice/voice_controller_test.dart`. Cobrir: (a) controlMode=voice + isAvailable=true → chama `repo.startListening` e estado vira `VoiceListening` ao receber `onListeningStateChanged(listening)`; (b) controlMode=volume → chama `repo.stopListening`, estado `VoiceIdle`; (c) isAvailable=false → `VoiceUnavailable`, não chama start; (d) `onWakeDetected(start)` → chama `recordingController.toggle`; (e) `onListeningStateChanged(paused)` → estado `VoicePaused`. Mocktail no `VoiceRepository` + override do `settingsController`.

```dart
// padrão: ProviderContainer com overrides de voiceRepositoryProvider (mock),
// settingsControllerProvider (AsyncData com controlMode), e um spy no recordingController.
// Espelhar o setup de voice_state_test + recording_controller_test.
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/voice/voice_controller_test.dart`
Expected: FAIL — `voice_controller.dart` não existe.

- [ ] **Step 4: Implementar `VoiceController`**

Criar `apps/mobile/lib/features/voice/application/voice_controller.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/features/camera/application/recording_controller.dart';
import 'package:raro_mobile/features/voice/application/voice_flutter_api_provider.dart';
import 'package:raro_mobile/features/voice/data/voice_repository_provider.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_controller.g.dart';

@riverpod
class VoiceController extends _$VoiceController {
  @override
  VoiceState build() {
    final repo = ref.watch(voiceRepositoryProvider);

    final wakeSub = ref.watch(voiceWakeEventsProvider.stream).listen((command) {
      _handleWake(command);
    });
    ref.onDispose(wakeSub.cancel);

    final stateSub = ref.watch(voiceStateEventsProvider.stream).listen((s) {
      state = _mapState(s);
    });
    ref.onDispose(stateSub.cancel);

    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.value?.controlMode),
    );
    _syncListening(repo, mode);

    return const VoiceIdle();
  }

  Future<void> _syncListening(VoiceRepository repo, ControlMode? mode) async {
    if (mode != ControlMode.voice) {
      repo.stopListening();
      if (ref.mounted) state = const VoiceIdle();
      return;
    }
    final available = await repo.isAvailable();
    if (!ref.mounted) return;
    if (!available) {
      state = const VoiceUnavailable();
      return;
    }
    repo.startListening();
  }

  void _handleWake(WakeCommand command) {
    ref.read(recordingControllerProvider.notifier);
    // o caller real precisa montar options; ver Step 5 (plug na câmera)
  }

  VoiceState _mapState(VoiceListeningState s) => switch (s) {
    VoiceListeningState.idle => const VoiceIdle(),
    VoiceListeningState.listening => const VoiceListening(),
    VoiceListeningState.paused => const VoicePaused(),
    VoiceListeningState.unavailable => const VoiceUnavailable(),
  };
}
```

> **Decisão de arquitetura do wake→toggle:** o `RecordingController.toggle` precisa de `RecordingOptions` (que dependem de `_format`/`replayArmed` da câmera). O `VoiceController` não conhece isso. Duas saídas: (i) expor um provider `recordingOptionsProvider` que o VoiceController lê e passa ao toggle; (ii) o VoiceController emite um `wakeCommandProvider` que a `camera_screen` escuta e chama `_onRecTap`-equivalente. **Escolha (i)** é mais limpa e mantém a voz funcionando sem a tela montada — mas `_format` vive em `setState` da câmera. **Portanto escolha (i')**: mover `_format` para um provider (`selectedFormatProvider`) OU manter o builder de options num provider que lê replayBuffer + um format provider. Ver Step 5 — esta decisão é resolvida lá com o mínimo de mudança.

- [ ] **Step 5: Plug wake→toggle via provider de options (resolve a dependência de `_format`)**

Como `_format` está em `setState` local da câmera, a opção de menor cirurgia: expor um `Ref`-level callback. Criar em `voice_controller.dart` um provider de "ação de gravação":

```dart
typedef RecordingTrigger = void Function(WakeCommand command);

@riverpod
class VoiceRecordingTrigger extends _$VoiceRecordingTrigger {
  @override
  RecordingTrigger? build() => null;
  void register(RecordingTrigger trigger) => state = trigger;
}
```

E no `_handleWake`:
```dart
  void _handleWake(WakeCommand command) {
    final trigger = ref.read(voiceRecordingTriggerProvider);
    trigger?.call(command);
  }
```

Na `camera_screen` (Task B6), registrar o trigger no `initState`/`build`:
```dart
    ref.read(voiceRecordingTriggerProvider.notifier).register((command) {
      _onVoiceCommand(command);
    });
```
com:
```dart
  Future<void> _onVoiceCommand(WakeCommand command) async {
    final phase = ref.read(recordingControllerProvider);
    final isActive = phase is RecordingActive || phase is RecordingStarting;
    if (command == WakeCommand.start && isActive) return;
    if (command == WakeCommand.stop && !isActive) return;
    await _onRecTap();
  }
```

> Isso mantém a montagem de options na câmera (fonte única via `_onRecTap`→`toggle`) e a voz só sinaliza o comando. `_onRecTap` já é idempotente (toggle). O mapeamento start/stop evita inverter o estado.

- [ ] **Step 6: Repository provider**

Criar `apps/mobile/lib/features/voice/data/voice_repository_provider.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/features/voice/data/voice_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_repository_provider.g.dart';

@riverpod
VoiceRepository voiceRepository(Ref ref) =>
    PigeonVoiceRepository(VoiceHostApi());
```

- [ ] **Step 7: Codegen Riverpod + rodar testes**

Run: `bun run --filter '@raro/mobile' codegen && cd apps/mobile && flutter test test/features/voice/`
Expected: codegen gera `.g.dart`; testes do VoiceController PASS.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/features/voice/ apps/mobile/test/features/voice/voice_controller_test.dart
git commit -m "feat(voice): voicecontroller reativo liga listener ao controlmode + plug wake→toggle"
```

---

## Task B6: Feedback UI (indicador sempre-visível) + ativar o VoiceController na câmera

**Files:**
- Create: `apps/mobile/lib/features/voice/presentation/voice_listening_indicator.dart`
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart`
- Test: `apps/mobile/test/features/voice/voice_listening_indicator_test.dart`

- [ ] **Step 1: Teste do indicador (3 estados rendem diferente, nunca some)**

Criar `apps/mobile/test/features/voice/voice_listening_indicator_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_mobile/features/voice/presentation/voice_listening_indicator.dart';
// + wrapper de tema RaroColors (espelhar outro widget test do projeto)

void main() {
  testWidgets('listening mostra o hint DIGA "RARO"', (tester) async {
    await tester.pumpWidget(_wrap(const VoiceListeningIndicator(state: VoiceListening())));
    expect(find.textContaining('RARO'), findsOneWidget);
  });
  testWidgets('paused mostra estado pausado e NÃO some', (tester) async {
    await tester.pumpWidget(_wrap(const VoiceListeningIndicator(state: VoicePaused())));
    expect(find.byType(VoiceListeningIndicator), findsOneWidget);
    expect(find.textContaining('pausada'), findsOneWidget);
  });
  testWidgets('unavailable convida a ativar', (tester) async {
    await tester.pumpWidget(_wrap(const VoiceListeningIndicator(state: VoiceUnavailable())));
    expect(find.textContaining('Configurações'), findsOneWidget);
  });
  testWidgets('idle não renderiza nada visível', (tester) async {
    await tester.pumpWidget(_wrap(const VoiceListeningIndicator(state: VoiceIdle())));
    expect(find.byType(SizedBox), findsWidgets);
  });
}
```

> `_wrap` deve prover `MaterialApp` + tema com `RaroColors` extension (espelhar `replay_arm_ring` ou `preroll_confirmation` widget tests existentes p/ o helper de tema).

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/voice/voice_listening_indicator_test.dart`
Expected: FAIL — widget não existe.

- [ ] **Step 3: Implementar o indicador**

Criar `apps/mobile/lib/features/voice/presentation/voice_listening_indicator.dart` — um widget que rende por estado: `listening` = chip discreto com ponto pulsando + texto `DIGA "RARO" PARA GRAVAR`; `paused` = chip apagado/cinza + `voz pausada`; `unavailable` = chip + `Ativar voz nas Configurações`; `idle` = `SizedBox.shrink()`. Usar tokens do `RaroColors`/`RaroAccents` (NUNCA `Color(0xFF..)` fora de core/theme — memória `hex-colors-must-live-in-core-theme`). Reusar o estilo do `ReplayArmRing`/hint existente.

- [ ] **Step 4: Rodar e ver passar**

Run: `cd apps/mobile && flutter test test/features/voice/voice_listening_indicator_test.dart`
Expected: PASS.

- [ ] **Step 5: Montar o indicador na câmera + ativar o VoiceController + registrar trigger**

Em `camera_screen.dart`: (a) no `build`, `final voiceState = ref.watch(voiceControllerProvider);` (ativa o Notifier → liga o listener conforme setting); (b) registrar o trigger (Task B5 Step 5) uma vez; (c) posicionar `VoiceListeningIndicator(state: voiceState)` na HUD quando `controlMode==voice` e não-gravando (esconder durante REC — o indicador de gravação assume). Surgical: adicionar ao `Stack` da HUD existente, sem reestruturar.

- [ ] **Step 6: Rodar suite Dart completa (sem regressão) + analyze**

Run: `bun run --filter '@raro/mobile' analyze && cd apps/mobile && flutter test 2>&1 | tail -5`
Expected: analyze 0; todos os testes passam (290 anteriores + novos).

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/lib/features/voice/presentation/ apps/mobile/lib/features/camera/presentation/camera_screen.dart apps/mobile/test/features/voice/voice_listening_indicator_test.dart
git commit -m "feat(voice): indicador de escuta sempre-visível + ativa voicecontroller na câmera"
```

---

## Task B7: Settings — desabilitar Volume ("em breve")

**Files:**
- Modify: `apps/mobile/lib/features/settings/presentation/widgets/control_mode_card.dart`
- Modify: `apps/mobile/lib/features/settings/presentation/settings_screen.dart:356-365`
- Test: `apps/mobile/test/features/settings/control_mode_disabled_test.dart`

- [ ] **Step 1: Teste — card Volume desabilitado não muda o modo**

Criar `apps/mobile/test/features/settings/control_mode_disabled_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/control_mode_card.dart';
// + wrapper de tema

void main() {
  testWidgets('card desabilitado mostra "em breve" e não dispara onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(ControlModeCard(
      badge: 'OFF', title: 'Volume', subtitle: '+ ou −',
      active: false, onTap: () => tapped = true, enabled: false,
    )));
    expect(find.textContaining('em breve'), findsOneWidget);
    await tester.tap(find.byType(ControlModeCard));
    await tester.pump();
    expect(tapped, isFalse);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd apps/mobile && flutter test test/features/settings/control_mode_disabled_test.dart`
Expected: FAIL — `enabled` não existe no `ControlModeCard`.

- [ ] **Step 3: Adicionar `enabled` ao `ControlModeCard`**

Em `control_mode_card.dart`: adicionar `final bool enabled;` (`this.enabled = true` no construtor); quando `!enabled`, `GestureDetector.onTap = null`, aplicar opacidade reduzida e mostrar selo "em breve" no lugar do subtitle (ou abaixo do title).

- [ ] **Step 4: Passar `enabled: false` no card Volume**

Em `settings_screen.dart` (linha ~359-365), no `ControlModeCard` do Volume adicionar `enabled: false` e remover o `onSelected(ControlMode.volume)` efetivo (manter o callback mas o card não chama por estar desabilitado). O card Voz fica intacto.

- [ ] **Step 5: Rodar e ver passar + suite settings**

Run: `cd apps/mobile && flutter test test/features/settings/`
Expected: PASS sem regressão.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/settings/presentation/ apps/mobile/test/features/settings/control_mode_disabled_test.dart
git commit -m "feat(settings): card volume desabilitado com selo em breve (voz = sprint 3 p/ volume)"
```

---

## Task B8: GATE device da voz (PAUSAR — avisar usuário p/ conectar iPhone 12)

**Files:** nenhum (validação)

> ⚠️ **PARAR AQUI e avisar o usuário** — etapa manual no iPhone 12.

- [ ] **Step 1: Build profile + install + launch**

```bash
cd apps/mobile && flutter clean && bun run --filter '@raro/mobile' pub:get
GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --profile 2>&1 | tail -8   # conferir "✓ Built" + timestamp
xcrun devicectl device install app --device <udid> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <udid> com.rarocamera
```

- [ ] **Step 2: Validar permissão + escuta (instrumentar os_log)**

Abrir o app, conceder mic+speech. Com Console.app filtrando `subsystem:com.rarocamera/voice`:
- Câmera aberta + Voz ON → indicador "DIGA RARO"; log `onStateChanged listening`.
- Dizer **"Raro gravar"** → `wake matched start` → gravação inicia (com pré-roll se armado).
- Negar permissão (Settings) → indicador `unavailable`, sem crash.

- [ ] **Step 3: GATE B-mic (decide Q8) — "Raro parar" durante REC**

Gravar, e durante a gravação dizer **"Raro parar"**:
- Se parar E o áudio do `.mp4` ficar limpo → "parar" por voz FICA.
- Puxar o vault e checar áudio:
```bash
xcrun devicectl device copy from --device <udid> --domain-type appDataContainer \
  --domain-identifier com.rarocamera --source Documents/vault/<id>.mp4 --destination /tmp/voice.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,duration /tmp/voice.mp4
# + ouvir o áudio: deve ter voz/ambiente limpos, não mudo/picotado
```
- Se o áudio degradar/mutar → "Raro parar" durante REC vira **Sprint 3**; v1.0 entrega "Raro gravar" + parar por botão (o recognizer pausa no REC). Registrar a decisão.

- [ ] **Step 4: Registrar resultado do gate (memória + session log)**

Documentar no session log da S2.C o veredito do B-mic (parar-por-voz fica ou Sprint 3) com a evidência ffprobe. Atualizar a memória `raro-competitor-okcamera-replay-model` / criar memória do conflito de mic se relevante.

---

## Pós-implementação

- [ ] `/verify-slice` (analyze + test + design-fidelity na tela de voz/settings)
- [ ] `design-fidelity-checker` na tela de Settings (Controle de Gravação) e no hint da câmera vs protótipo
- [ ] `/session-end` (session log append-only + objetivo da próxima)
- [ ] Atualizar `docs/10-CHANGELOG.md`
- [ ] PR #2 segue draft (merge→develop segurado)

---

## Self-Review notes (do autor do plano)

- **Cobertura da spec:** A1/A2/A3 → Tasks A1/A2/A3. Q1 ordem (A antes de B) ✓. Q2 modo selecionável → B7 + controlMode existente ✓. Q3 engine → B0 ADR + B3 ✓. Q4 toggle → B4 ✓. Q5 default voz → já existe (`@Default(ControlMode.voice)`) ✓. Q6 volume Sprint 3 → B7 ✓. Q7 dois comandos → B1 enum + B3 parser ✓. Q8 mic gate → B8 Step 3 ✓. Q9 feedback → B6 ✓. Q10 pausar device → A3 Step 4 + B8 ✓.
- **Riscos da spec → mitigações no plano:** mic durante REC → B8 gate; rate limit → B3 backoff + on-device; falso+ → parser exige wake+verbo; mover toggle → B4 pin antes; A2/A3 encode → A3 Step 4 ffprobe; modo efêmero → usa settingsController persistido; XCTest some → 4 inserções pbxproj notadas em A2/B3.
- **Pontos a confirmar pelo implementer contra o gerado:** nomes exatos do Pigeon Swift (`VoiceHostApiSetup.setUp` vs `setUpVoiceHostApi`; labels `command:`/`state:`; `throws` vs `completion`); direção do FlutterApi no Dart (app é host do FlutterApi → implementa + setUp). Esses são ajustes de assinatura, não de design.
