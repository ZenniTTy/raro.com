# Replay Buffer (S2.B) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar a mecânica do replay buffer iOS — um ring de chunks `.mp4` rolando sempre que a câmera está ativa (últimos 15s/30s), com `saveReplay()` que persiste a janela no vault, provider Riverpod reativo, e o `BufferPill` alternando a duração — sobre o pipeline unificado já no lugar.

**Architecture:** Chunked disk-ring (ADR-0003 Addendum 2026-06-05): `ReplayBuffer.swift` mantém uma deque de chunks `.mp4` progressivos curtos (~1s) em `temporaryDirectory`, alimentada por **fan-out** do `captureOutput` do `RecordingPipeline` existente (o mesmo `CMSampleBuffer` vai para o writer de gravação on-demand E para o ring). `saveReplay` concatena os chunks da janela via `AVMutableComposition` + `AVAssetExportSession(passthrough)`. Dart: contrato Pigeon dedicado (`replay_buffer_api.dart`), repository (port), provider Notifier reativo, sink de vault dedicado, `BufferPill` ligado à duração real. **Escopo desta sessão = mecânica isolada; pré-roll-no-REC é fatia seguinte.**

**Tech Stack:** Swift/AVFoundation (`AVAssetWriter`, `AVMutableComposition`, `AVAssetExportSession`, `ProcessInfo.thermalState`), Pigeon, Riverpod 3 codegen, mocktail, XCTest.

---

## Pré-requisitos (rodar uma vez no início)

- [ ] **P0: Confirmar working tree e branch**

Run: `git status && git log --oneline -3`
Expected: branch `feat/camera-native-bridge`, working tree limpo, HEAD = `docs(bridge): adr-0003 addendum chunked disk-ring + spec replay buffer s2.b`.

- [ ] **P1: Ler os documentos canônicos desta sessão**

Ler (não editar): `docs/decisions/0003-replay-buffer-native.md` (Addendum 2026-06-05), `docs/decisions/0020-unified-capture-pipeline-videodataoutput.md`, `docs/superpowers/specs/2026-06-05-replay-buffer-design.md`. Confirmar a estratégia chunked-disk-ring e o escopo fatiado (mecânica, não pré-roll).

- [ ] **P2: Verificar suíte verde antes de tocar nada**

Run: `bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test`
Expected: analyze 0 issues; testes PASS (baseline da sessão 0020 = Dart 255/255).

---

## Mapa de arquivos

**Nativo iOS (Swift):**
- Create: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift` — ring de chunks `.mp4` + save por composition. Lógica determinística do ring extraída numa struct testável `ReplayRing`.
- Create: `apps/mobile/ios/Runner/Native/Camera/ReplayBufferHostApiImpl.swift` — impl do `ReplayBufferHostApi`, delega ao `CameraManager`, entrega callbacks via `ReplayBufferFlutterApi`.
- Modify: `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift` — adiciona `replayConsumer` (fan-out no `captureOutput`).
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` — possui o `ReplayBuffer`, liga o fan-out, expõe `setReplayWindow`/`saveReplay`/`startReplay`/`stopReplay`, `reset()` no `setFormat`/lens físico.
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift` — registra o `ReplayBufferHostApi` no canal `com.rarocamera/replay_buffer`.

**Contrato Pigeon:**
- Modify: `apps/mobile/pigeons/replay_buffer_api.dart` — substitui stubs.
- Will-regenerate: `apps/mobile/lib/core/native_bridges/generated/replay_buffer_api.g.dart`, `apps/mobile/ios/Runner/Native/Generated/ReplayBufferApi.g.swift`, `android/.../generated/replay_buffer/ReplayBufferApi.g.kt`.

**Android (stub):**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/replay/ReplayBufferHostApiImpl.kt` — stub lançando erro `formatUnsupported`.

**Dart:**
- Create: `apps/mobile/lib/features/replay/domain/replay_buffer_state.dart` — sealed state.
- Create: `apps/mobile/lib/features/replay/data/replay_buffer_repository.dart` — abstract port.
- Create: `apps/mobile/lib/features/replay/data/pigeon_replay_buffer_repository.dart` — impl Pigeon.
- Create: `apps/mobile/lib/features/replay/data/replay_buffer_repository_provider.dart` — `@Riverpod(keepAlive: true)`.
- Create: `apps/mobile/lib/features/replay/application/replay_flutter_api_provider.dart` — stream de eventos `ReplayResult`.
- Create: `apps/mobile/lib/features/replay/application/replay_buffer_controller.dart` — `@riverpod` Notifier reativo.
- Create: `apps/mobile/lib/features/replay/application/replay_vault_sink.dart` — sink dedicado vault+thumbnail.
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart` — inicia/reseta buffer, surfa erro, propaga duração.

**Testes:**
- Create: `apps/mobile/ios/RunnerTests/ReplayRingTests.swift` — lógica determinística do ring.
- Create: `apps/mobile/test/features/replay/replay_buffer_state_test.dart`
- Create: `apps/mobile/test/features/replay/replay_buffer_repository_test.dart`
- Create: `apps/mobile/test/features/replay/replay_buffer_controller_test.dart`
- Create: `apps/mobile/test/features/replay/replay_vault_sink_test.dart`
- Create: `apps/mobile/test/features/camera/data/vault_service_race_test.dart` — órfão 1.
- Create: `apps/mobile/test/features/replay/replay_vault_sink_dispose_test.dart` — órfão 2.

---

## Task 1: Contrato Pigeon dedicado

**Files:**
- Modify: `apps/mobile/pigeons/replay_buffer_api.dart`
- Will-regenerate: 3 arquivos gerados (Dart/Swift/Kotlin)

- [ ] **Step 1: Substituir o conteúdo dos `@HostApi`/`@FlutterApi` em `replay_buffer_api.dart`**

Manter o bloco `@ConfigurePigeon(...)` exatamente como está (linhas 1-16). Substituir apenas as classes abstratas (linhas 17-25) por:

```dart
@HostApi()
abstract class ReplayBufferHostApi {
  void enableReplayBuffer(int seconds);
  void disableReplayBuffer();
  void saveReplay();
}

@FlutterApi()
abstract class ReplayBufferFlutterApi {
  void onReplaySaved(String path, int durationMs);
  void onReplayFailed(String code, String? message);
}
```

- [ ] **Step 2: Regenerar Pigeon**

Run: `bun run --filter '@raro/mobile' pigeon`
Expected: regenera sem erro. Conferir que `apps/mobile/lib/core/native_bridges/generated/replay_buffer_api.g.dart` agora tem `ReplayBufferHostApi` com `enableReplayBuffer`/`disableReplayBuffer`/`saveReplay` e `ReplayBufferFlutterApi` com `onReplaySaved`/`onReplayFailed`; idem `ReplayBufferApi.g.swift` e `.g.kt`.

- [ ] **Step 3: Verificar analyze (Dart gerado compila)**

Run: `bun run --filter '@raro/mobile' analyze`
Expected: 0 issues (o `.g.kt` e `.g.swift` ainda não têm impl registrada — isso é Task 2/8, mas o Dart compila).

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/pigeons/replay_buffer_api.dart apps/mobile/lib/core/native_bridges/generated/replay_buffer_api.g.dart apps/mobile/ios/Runner/Native/Generated/ReplayBufferApi.g.swift apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/replay_buffer/ReplayBufferApi.g.kt
git commit -m "feat(replay): contrato pigeon dedicado enable/disable/save + callbacks (adr-0003)"
```

---

## Task 2: `ReplayRing` — lógica determinística do ring (XCTest red-before-green)

A lógica de rotação da deque é uma struct pura (sem `AVAssetWriter`), testável em XCTest sem sessão viva. Guarda descritores de chunk (url + duração), não os writers.

**Files:**
- Create: `apps/mobile/ios/RunnerTests/ReplayRingTests.swift`
- Create: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift` (só a struct `ReplayRing` nesta task)

- [ ] **Step 1: Escrever o teste que falha**

Create `apps/mobile/ios/RunnerTests/ReplayRingTests.swift`:

```swift
import XCTest
@testable import Runner

final class ReplayRingTests: XCTestCase {
  func testCapacityForWindowAndChunkDuration() {
    XCTAssertEqual(ReplayRing.capacity(windowSeconds: 30, chunkSeconds: 1), 31)
    XCTAssertEqual(ReplayRing.capacity(windowSeconds: 15, chunkSeconds: 1), 16)
    XCTAssertEqual(ReplayRing.capacity(windowSeconds: 30, chunkSeconds: 2), 16)
  }

  func testAppendBeyondCapacityKeepsNewestInOrder() {
    var ring = ReplayRing(windowSeconds: 3, chunkSeconds: 1) // capacity 4
    let urls = (0..<6).map { URL(fileURLWithPath: "/tmp/chunk\($0).mp4") }
    var evicted: [URL] = []
    for u in urls { evicted.append(contentsOf: ring.append(Chunk(url: u, durationMs: 1000))) }
    XCTAssertEqual(ring.chunks.map { $0.url.lastPathComponent },
                   ["chunk2.mp4", "chunk3.mp4", "chunk4.mp4", "chunk5.mp4"])
    XCTAssertEqual(evicted.map { $0.lastPathComponent }, ["chunk0.mp4", "chunk1.mp4"])
  }

  func testWindowChunksAreAllRetainedWhenWithinWindow() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1)
    for i in 0..<10 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    XCTAssertEqual(ring.windowChunks().count, 10)
  }

  func testSetWindowRecomputesCapacityAndEvictsExcess() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1) // capacity 31
    for i in 0..<20 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    let evicted = ring.setWindow(seconds: 15) // capacity 16 -> evict oldest 4
    XCTAssertEqual(ring.chunks.count, 16)
    XCTAssertEqual(evicted.count, 4)
    XCTAssertEqual(ring.chunks.first?.url.lastPathComponent, "c4.mp4")
  }

  func testResetClearsAndReturnsAll() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1)
    for i in 0..<5 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    let cleared = ring.reset()
    XCTAssertEqual(cleared.count, 5)
    XCTAssertTrue(ring.chunks.isEmpty)
  }
}
```

- [ ] **Step 2: Adicionar o teste ao target RunnerTests no `project.pbxproj` (4 inserções)**

Memória `raro-pattern-ios-xctest-pbxproj-4-insertions`: o XCTest novo NÃO é auto-descoberto. Editar `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` adicionando `ReplayRingTests.swift` em 4 pontos, espelhando como `CameraManagerCapabilitiesTests.swift` aparece:
  1. `PBXBuildFile` (com fileRef novo).
  2. `PBXFileReference` (`lastKnownFileType = sourcecode.swift; path = ReplayRingTests.swift`).
  3. Membro do `PBXGroup` do RunnerTests.
  4. Entrada na `Sources` build phase do target RunnerTests.

Procedimento: `grep -n "CameraManagerCapabilitiesTests" apps/mobile/ios/Runner.xcodeproj/project.pbxproj` para achar os 4 sítios e replicar com IDs novos (24-hex únicos, ex. sufixo incrementado).

- [ ] **Step 3: Rodar o teste — espera FALHAR (não compila: `ReplayRing`/`Chunk` não existem)**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: FAIL de compilação ("cannot find 'ReplayRing' in scope"). Confirmar no output que o target compila os outros testes (só falha pelo símbolo ausente).

- [ ] **Step 4: Implementar `ReplayRing` + `Chunk` em `ReplayBuffer.swift`**

Create `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift` (só a parte pura nesta task; o resto da classe vem na Task 3):

```swift
@preconcurrency import AVFoundation
import Foundation
import os.log

struct Chunk {
  let url: URL
  let durationMs: Int
}

struct ReplayRing {
  private(set) var chunks: [Chunk] = []
  private(set) var capacityCount: Int
  let chunkSeconds: Int

  init(windowSeconds: Int, chunkSeconds: Int) {
    self.chunkSeconds = chunkSeconds
    self.capacityCount = Self.capacity(windowSeconds: windowSeconds, chunkSeconds: chunkSeconds)
  }

  static func capacity(windowSeconds: Int, chunkSeconds: Int) -> Int {
    guard chunkSeconds > 0 else { return 1 }
    return Int((Double(windowSeconds) / Double(chunkSeconds)).rounded(.up)) + 1
  }

  mutating func append(_ chunk: Chunk) -> [URL] {
    chunks.append(chunk)
    var evicted: [URL] = []
    while chunks.count > capacityCount {
      evicted.append(chunks.removeFirst().url)
    }
    return evicted
  }

  mutating func setWindow(seconds: Int) -> [URL] {
    capacityCount = Self.capacity(windowSeconds: seconds, chunkSeconds: chunkSeconds)
    var evicted: [URL] = []
    while chunks.count > capacityCount {
      evicted.append(chunks.removeFirst().url)
    }
    return evicted
  }

  func windowChunks() -> [Chunk] {
    return chunks
  }

  mutating func reset() -> [URL] {
    let urls = chunks.map { $0.url }
    chunks.removeAll()
    return urls
  }
}
```

- [ ] **Step 5: Rodar o teste — espera PASSAR**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS. Confirmar no output `Test Suite 'ReplayRingTests' started` + 5 testes (memória pbxproj: exit 0 não prova; grep o nome da suíte).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift apps/mobile/ios/RunnerTests/ReplayRingTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(replay): replay ring determinístico (rotação/janela/reset) + xctests"
```

---

## Task 3: `ReplayBuffer` — writer de chunks + save por composition

A classe completa: alimenta um `AVAssetWriter` por chunk, rotaciona via `ReplayRing`, deleta os evictados, e `save` concatena a janela. Sem TDD de integração (precisa de sessão viva → device); o XCTest da Task 2 cobre a lógica determinística. Esta task é implementação device-validated (gate na Task 9).

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift`

- [ ] **Step 1: Adicionar a classe `ReplayBuffer` ao arquivo (abaixo da struct `ReplayRing`)**

```swift
private let replayLog = OSLog(subsystem: "com.rarocamera", category: "replay")

enum ReplayBufferError: Error {
  case thermalThrottled
  case notBuffering
  case noChunks
  case exportFailed(String)

  var code: String {
    switch self {
    case .thermalThrottled: return "thermalThrottled"
    case .notBuffering: return "notBuffering"
    case .noChunks: return "noChunks"
    case .exportFailed: return "exportFailed"
    }
  }
  var message: String? {
    if case let .exportFailed(m) = self { return m }
    return nil
  }
}

final class ReplayBuffer: NSObject, @unchecked Sendable {
  private let queue: DispatchQueue
  private let chunkSeconds: Int
  private var ring: ReplayRing
  private var buffering = false

  private var writer: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var audioInput: AVAssetWriterInput?
  private var chunkStartedAt: CMTime?
  private var sessionStarted = false
  private var chunkIndex = 0
  private var videoSettings: [String: Any]?
  private var audioSettings: [String: Any]?

  var onSaved: ((URL, Int) -> Void)?
  var onFailed: ((ReplayBufferError) -> Void)?

  init(queue: DispatchQueue, windowSeconds: Int = 15, chunkSeconds: Int = 1) {
    self.queue = queue
    self.chunkSeconds = chunkSeconds
    self.ring = ReplayRing(windowSeconds: windowSeconds, chunkSeconds: chunkSeconds)
    super.init()
  }

  func start(videoSettings: [String: Any], audioSettings: [String: Any]?) {
    queue.async {
      guard ProcessInfo.processInfo.thermalState != .serious,
            ProcessInfo.processInfo.thermalState != .critical else {
        os_log("replay start refused — thermalState=%d", log: replayLog, type: .error,
               ProcessInfo.processInfo.thermalState.rawValue)
        DispatchQueue.main.async { self.onFailed?(.thermalThrottled) }
        return
      }
      self.videoSettings = videoSettings
      self.audioSettings = audioSettings
      self.buffering = true
      os_log("replay buffering started", log: replayLog, type: .info)
    }
  }

  func stop() {
    queue.async {
      self.buffering = false
      self.finishCurrentChunk(keep: false)
      for url in self.ring.reset() { try? FileManager.default.removeItem(at: url) }
      os_log("replay buffering stopped", log: replayLog, type: .info)
    }
  }

  func setWindow(seconds: Int) {
    queue.async {
      for url in self.ring.setWindow(seconds: seconds) {
        try? FileManager.default.removeItem(at: url)
      }
    }
  }

  func reset() {
    queue.async {
      self.finishCurrentChunk(keep: false)
      for url in self.ring.reset() { try? FileManager.default.removeItem(at: url) }
    }
  }

  func append(_ sampleBuffer: CMSampleBuffer, isVideo: Bool) {
    // chamado já na queue do RecordingPipeline (mesma serial)
    guard buffering else { return }
    guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
    let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

    if writer == nil { openChunk(at: pts) }
    guard let writer = writer else { return }

    if !sessionStarted {
      guard isVideo else { return }
      writer.startSession(atSourceTime: pts)
      sessionStarted = true
      chunkStartedAt = pts
    }
    if isVideo, let input = videoInput, input.isReadyForMoreMediaData {
      _ = input.append(sampleBuffer)
    } else if !isVideo, let input = audioInput, input.isReadyForMoreMediaData {
      _ = input.append(sampleBuffer)
    }

    if let start = chunkStartedAt {
      let elapsed = CMTimeGetSeconds(CMTimeSubtract(pts, start))
      if elapsed >= Double(chunkSeconds), isVideo {
        rollChunk(nextPts: pts)
      }
    }
  }

  private func openChunk(at pts: CMTime) {
    guard let vSettings = videoSettings else { return }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("raro_replay_\(chunkIndex).mp4")
    try? FileManager.default.removeItem(at: url)
    chunkIndex += 1
    guard let newWriter = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return }
    let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: vSettings)
    vInput.expectsMediaDataInRealTime = true
    if newWriter.canAdd(vInput) { newWriter.add(vInput) }
    var aInput: AVAssetWriterInput?
    if let aSettings = audioSettings {
      let input = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
      input.expectsMediaDataInRealTime = true
      if newWriter.canAdd(input) { newWriter.add(input); aInput = input }
    }
    newWriter.startWriting()
    self.writer = newWriter
    self.videoInput = vInput
    self.audioInput = aInput
    self.sessionStarted = false
  }

  private func rollChunk(nextPts: CMTime) {
    finishCurrentChunk(keep: true)
    openChunk(at: nextPts)
  }

  private func finishCurrentChunk(keep: Bool) {
    guard let writer = writer else { return }
    let url = writer.outputURL
    let durationMs: Int
    if let start = chunkStartedAt {
      durationMs = Int(CMTimeGetSeconds(CMTimeSubtract(CMClockGetTime(CMClockGetHostTimeClock()), start)) * 1000)
    } else {
      durationMs = chunkSeconds * 1000
    }
    videoInput?.markAsFinished()
    audioInput?.markAsFinished()
    writer.finishWriting {}
    self.writer = nil
    self.videoInput = nil
    self.audioInput = nil
    self.chunkStartedAt = nil
    self.sessionStarted = false
    if keep {
      for evicted in ring.append(Chunk(url: url, durationMs: max(durationMs, chunkSeconds * 1000))) {
        try? FileManager.default.removeItem(at: evicted)
      }
    } else {
      try? FileManager.default.removeItem(at: url)
    }
  }

  func save() {
    queue.async {
      guard self.buffering else { DispatchQueue.main.async { self.onFailed?(.notBuffering) }; return }
      self.finishCurrentChunk(keep: true)
      let chunks = self.ring.windowChunks()
      guard !chunks.isEmpty else { DispatchQueue.main.async { self.onFailed?(.noChunks) }; return }
      self.export(chunks: chunks)
    }
  }

  private func export(chunks: [Chunk]) {
    let composition = AVMutableComposition()
    let videoTrack = composition.addMutableTrack(
      withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    let audioTrack = composition.addMutableTrack(
      withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    var cursor = CMTime.zero
    for chunk in chunks {
      let asset = AVURLAsset(url: chunk.url)
      guard let assetVideo = asset.tracks(withMediaType: .video).first else { continue }
      let range = CMTimeRange(start: .zero, duration: asset.duration)
      try? videoTrack?.insertTimeRange(range, of: assetVideo, at: cursor)
      if let assetAudio = asset.tracks(withMediaType: .audio).first {
        try? audioTrack?.insertTimeRange(range, of: assetAudio, at: cursor)
      }
      cursor = CMTimeAdd(cursor, asset.duration)
    }
    let outURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("raro_replay_\(UUID().uuidString).mp4")
    guard let export = AVAssetExportSession(
      asset: composition, presetName: AVAssetExportPresetPassthrough) else {
      DispatchQueue.main.async { self.onFailed?(.exportFailed("no export session")) }
      return
    }
    export.outputURL = outURL
    export.outputFileType = .mp4
    let totalMs = Int(CMTimeGetSeconds(cursor) * 1000)
    export.exportAsynchronously {
      DispatchQueue.main.async {
        if export.status == .completed {
          os_log("replay saved path=%{public}@ durationMs=%d", log: replayLog, type: .info, outURL.path, totalMs)
          self.onSaved?(outURL, totalMs)
        } else {
          let msg = export.error?.localizedDescription ?? "export failed"
          os_log("replay export failed: %{public}@", log: replayLog, type: .error, msg)
          self.onFailed?(.exportFailed(msg))
        }
      }
    }
  }
}
```

- [ ] **Step 2: Verificar que compila (sem regressão de target)**

Run: `cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always flutter build ios --simulator --no-codesign 2>&1 | tail -20`
Expected: `✓ Built`. (Compila o Swift novo; `ReplayBuffer` ainda não está ligado ao `CameraManager` — isso é a Task 4.)

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift
git commit -m "feat(replay): replaybuffer writer de chunks .mp4 + save por avmutablecomposition passthrough (adr-0003)"
```

---

## Task 4: Fan-out no RecordingPipeline + wire no CameraManager

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift`
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`

- [ ] **Step 1: Adicionar `replayConsumer` + expor a `outputQueue` e os settings no RecordingPipeline**

Em `RecordingPipeline.swift`, adicionar propriedade pública (após `var onFailed`):

```swift
  var replayConsumer: ((CMSampleBuffer, Bool) -> Void)?
  var sharedQueue: DispatchQueue { outputQueue }

  func makeReplayVideoSettings() -> [String: Any] {
    var settings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4) ?? [:]
    settings[AVVideoCodecKey] = Self.selectCodec(
      requested: requestedCodec, available: videoOutput.availableVideoCodecTypes)
    return settings
  }

  func makeReplayAudioSettings() -> [String: Any]? {
    return audioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mp4) as? [String: Any]
  }
```

No final do `captureOutput` (depois do bloco que faz append na gravação, antes de fechar o método), adicionar o fan-out:

```swift
    let isVideo = output === videoOutput
    replayConsumer?(sampleBuffer, isVideo)
```

> Nota: o `captureOutput` hoje retorna cedo se `!recording`. O fan-out do replay precisa rodar SEMPRE (buffer é sempre-ativo, independente de gravação). Mover o cálculo `isVideo` + `replayConsumer?(...)` para o TOPO do `captureOutput`, ANTES do `guard recording, let writer = writer...`. Estrutura final:

```swift
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
    let isVideo = output === videoOutput
    replayConsumer?(sampleBuffer, isVideo)

    guard recording, let writer = writer, writer.status == .writing else { return }
    // ... resto inalterado (pts, sessionStarted, append) ...
  }
```

- [ ] **Step 2: Adicionar o `ReplayBuffer` ao CameraManager + wire**

Em `CameraManager.swift`, após `private let recordingPipeline = RecordingPipeline()` (linha 24):

```swift
  private lazy var replayBuffer = ReplayBuffer(queue: recordingPipeline.sharedQueue)
```

Adicionar callbacks expostos (após `var onError`):

```swift
  var onReplaySaved: ((URL, Int) -> Void)? {
    get { replayBuffer.onSaved }
    set { replayBuffer.onSaved = newValue }
  }
  var onReplayFailed: ((ReplayBufferError) -> Void)? {
    get { replayBuffer.onFailed }
    set { replayBuffer.onFailed = newValue }
  }
```

No `startSession`, depois do bloco `withCheckedContinuation` que faz `attach` + `startRunning` (após linha 297), ligar o consumer e iniciar o buffer:

```swift
    recordingPipeline.replayConsumer = { [weak self] buffer, isVideo in
      self?.replayBuffer.append(buffer, isVideo: isVideo)
    }
    replayBuffer.start(
      videoSettings: recordingPipeline.makeReplayVideoSettings(),
      audioSettings: recordingPipeline.makeReplayAudioSettings()
    )
```

No `stopSession`, dentro do `sessionQueue.async` (antes de `self?.session = nil`), adicionar:

```swift
      self?.replayBuffer.stop()
```

Adicionar os métodos públicos de replay (após `func stopRecording()`):

```swift
  func setReplayWindow(seconds: Int) {
    replayBuffer.setWindow(seconds: seconds)
  }

  func saveReplay() throws {
    guard session != nil else { throw CameraNativeError.notRunning }
    guard !isInterrupted else { throw CameraNativeError.sessionInterrupted }
    replayBuffer.save()
  }
```

No `setFormat`, após `session.commitConfiguration()` (linha 418) e a reaplicação de zoom, adicionar (o reset limpa o buffer porque as dimensões mudaram):

```swift
    replayBuffer.reset()
```

No `switchLens`, no caminho de troca física (após `onLensSwitched?(lens)` no final do método, linha 373), adicionar:

```swift
    replayBuffer.reset()
```

- [ ] **Step 3: Verificar build**

Run: `cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always flutter build ios --simulator --no-codesign 2>&1 | tail -20`
Expected: `✓ Built`.

- [ ] **Step 4: Rodar XCTest (sem regressão)**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS — todas as suítes existentes + `ReplayRingTests`.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift apps/mobile/ios/Runner/Native/Camera/CameraManager.swift
git commit -m "feat(replay): fan-out captureoutput para o ring + wire replaybuffer no cameramanager"
```

---

## Task 5: ReplayBufferHostApiImpl + registro no AppDelegate

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Camera/ReplayBufferHostApiImpl.swift`
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Criar a impl do HostApi**

Create `apps/mobile/ios/Runner/Native/Camera/ReplayBufferHostApiImpl.swift`:

```swift
import Flutter
import Foundation

final class ReplayBufferHostApiImpl: NSObject, ReplayBufferHostApi, @unchecked Sendable {
  private let manager: CameraManager
  private let flutterApi: ReplayBufferFlutterApi

  init(manager: CameraManager, messenger: FlutterBinaryMessenger) {
    self.manager = manager
    self.flutterApi = ReplayBufferFlutterApi(binaryMessenger: messenger)
    super.init()
    manager.onReplaySaved = { [weak self] url, durationMs in
      DispatchQueue.main.async {
        self?.flutterApi.onReplaySaved(path: url.path, durationMs: Int64(durationMs)) { _ in }
      }
    }
    manager.onReplayFailed = { [weak self] error in
      DispatchQueue.main.async {
        self?.flutterApi.onReplayFailed(code: error.code, message: error.message) { _ in }
      }
    }
  }

  func enableReplayBuffer(seconds: Int64) throws {
    manager.setReplayWindow(seconds: Int(seconds))
  }

  func disableReplayBuffer() throws {
    manager.setReplayWindow(seconds: 0)
  }

  func saveReplay() throws {
    do {
      try manager.saveReplay()
    } catch let error as CameraNativeError {
      throw PigeonError(code: "\(error.code)", message: error.message, details: nil)
    } catch {
      throw PigeonError(code: "sessionFailed", message: error.localizedDescription, details: nil)
    }
  }
}
```

> Nota de wiring: o `ReplayBufferHostApiImpl` precisa do MESMO `CameraManager` que o `CameraHostApiImpl` usa. Expor o manager: em `CameraHostApiImpl` já existe `var cameraManager: CameraManager { manager }` (linha 44). O AppDelegate passa `hostApi.cameraManager`.

- [ ] **Step 2: Registrar no AppDelegate**

Em `apps/mobile/ios/Runner/AppDelegate.swift`, adicionar uma propriedade e o setup. Após `private var cameraHostApi: CameraHostApiImpl?`:

```swift
  private var replayBufferHostApi: ReplayBufferHostApiImpl?
```

Dentro de `didInitializeImplicitFlutterEngine`, após `registrar.register(factory, withId: "com.rarocamera/camera_preview")` (linha 27):

```swift
    let replayApi = ReplayBufferHostApiImpl(manager: hostApi.cameraManager, messenger: messenger)
    self.replayBufferHostApi = replayApi
    ReplayBufferHostApiSetup.setUp(binaryMessenger: messenger, api: replayApi)
```

- [ ] **Step 3: Adicionar os 2 arquivos novos ao target Runner no pbxproj**

`ReplayBufferHostApiImpl.swift` precisa entrar no target Runner (não RunnerTests). Editar `project.pbxproj` espelhando como `CameraHostApiImpl.swift` aparece (PBXBuildFile + PBXFileReference + PBXGroup + Sources do target Runner). O `ReplayBufferApi.g.swift` gerado também — conferir se o pigeon já o adicionou; se não, adicionar igual.

Run para achar os sítios: `grep -n "CameraHostApiImpl\|CameraApi.g.swift" apps/mobile/ios/Runner.xcodeproj/project.pbxproj`

- [ ] **Step 4: Build**

Run: `cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always flutter build ios --simulator --no-codesign 2>&1 | tail -20`
Expected: `✓ Built`.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/ReplayBufferHostApiImpl.swift apps/mobile/ios/Runner/AppDelegate.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(replay): registra replaybufferhostapi no canal dedicado + bridge para o cameramanager"
```

---

## Task 6: Android stub

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/replay/ReplayBufferHostApiImpl.kt`

- [ ] **Step 1: Criar o stub Kotlin**

Create o arquivo (espelhar como o lado Kotlin da câmera lança erro; o contract test cobre os dois lados do canal):

```kotlin
package com.rarocamera.raro_mobile.replay

import com.rarocamera.raro_mobile.generated.replay_buffer.ReplayBufferHostApi

class ReplayBufferHostApiImpl : ReplayBufferHostApi {
  override fun enableReplayBuffer(seconds: Long) {
    throw UnsupportedOperationException("formatUnsupported: replay buffer is iOS-only until Sprint 3")
  }

  override fun disableReplayBuffer() {
    throw UnsupportedOperationException("formatUnsupported: replay buffer is iOS-only until Sprint 3")
  }

  override fun saveReplay() {
    throw UnsupportedOperationException("formatUnsupported: replay buffer is iOS-only until Sprint 3")
  }
}
```

> Nota: NÃO registrar no MainActivity/Android (Sprint 3 liga). O stub existe para o `.g.kt` ter uma impl compilável e o contract test Dart ter o que verificar. Conferir a assinatura exata gerada em `ReplayBufferApi.g.kt` (pode ser `Long` ou `Int` para seconds) e alinhar.

- [ ] **Step 2: Verificar analyze (Dart inalterado, só confere que nada quebrou)**

Run: `bun run --filter '@raro/mobile' analyze`
Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/replay/ReplayBufferHostApiImpl.kt
git commit -m "feat(replay): stub kotlin replaybufferhostapi (android backlog sprint 3)"
```

---

## Task 7: Dart — domain state + repository (TDD)

**Files:**
- Create: `apps/mobile/lib/features/replay/domain/replay_buffer_state.dart`
- Create: `apps/mobile/lib/features/replay/data/replay_buffer_repository.dart`
- Create: `apps/mobile/lib/features/replay/data/pigeon_replay_buffer_repository.dart`
- Create: `apps/mobile/lib/features/replay/data/replay_buffer_repository_provider.dart`
- Test: `apps/mobile/test/features/replay/replay_buffer_state_test.dart`
- Test: `apps/mobile/test/features/replay/replay_buffer_repository_test.dart`

- [ ] **Step 1: Escrever os testes que falham**

Create `apps/mobile/test/features/replay/replay_buffer_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';

void main() {
  test('idle is the initial sealed variant', () {
    const state = ReplayBufferState.idle();
    expect(state, isA<ReplayIdle>());
  });

  test('buffering carries the window seconds', () {
    const state = ReplayBufferState.buffering(seconds: 30);
    expect((state as ReplayBuffering).seconds, 30);
  });

  test('failed carries the message', () {
    const state = ReplayBufferState.failed(message: 'thermalThrottled');
    expect((state as ReplayFailedState).message, 'thermalThrottled');
  });

  test('saving is a distinct variant', () {
    const state = ReplayBufferState.saving();
    expect(state, isA<ReplaySaving>());
  });
}
```

Create `apps/mobile/test/features/replay/replay_buffer_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/pigeon_replay_buffer_repository.dart';

class _MockHostApi extends Mock implements ReplayBufferHostApi {}

void main() {
  late _MockHostApi api;
  late PigeonReplayBufferRepository repo;

  setUp(() {
    api = _MockHostApi();
    repo = PigeonReplayBufferRepository(api);
  });

  test('enableReplayBuffer delegates with the seconds', () async {
    when(() => api.enableReplayBuffer(any())).thenAnswer((_) async {});
    await repo.enable(30);
    verify(() => api.enableReplayBuffer(30)).called(1);
  });

  test('disableReplayBuffer delegates', () async {
    when(() => api.disableReplayBuffer()).thenAnswer((_) async {});
    await repo.disable();
    verify(() => api.disableReplayBuffer()).called(1);
  });

  test('saveReplay delegates', () async {
    when(() => api.saveReplay()).thenAnswer((_) async {});
    await repo.save();
    verify(() => api.saveReplay()).called(1);
  });
}
```

- [ ] **Step 2: Rodar — espera FALHAR (símbolos não existem)**

Run: `bun run --filter '@raro/mobile' test test/features/replay/`
Expected: FAIL de compilação.

- [ ] **Step 3: Implementar o state**

Create `apps/mobile/lib/features/replay/domain/replay_buffer_state.dart`:

```dart
sealed class ReplayBufferState {
  const ReplayBufferState();

  const factory ReplayBufferState.idle() = ReplayIdle;
  const factory ReplayBufferState.buffering({required int seconds}) =
      ReplayBuffering;
  const factory ReplayBufferState.saving() = ReplaySaving;
  const factory ReplayBufferState.failed({required String message}) =
      ReplayFailedState;
}

class ReplayIdle extends ReplayBufferState {
  const ReplayIdle();
}

class ReplayBuffering extends ReplayBufferState {
  const ReplayBuffering({required this.seconds});
  final int seconds;
}

class ReplaySaving extends ReplayBufferState {
  const ReplaySaving();
}

class ReplayFailedState extends ReplayBufferState {
  const ReplayFailedState({required this.message});
  final String message;
}
```

- [ ] **Step 4: Implementar o repository (port + impl + provider)**

Create `apps/mobile/lib/features/replay/data/replay_buffer_repository.dart`:

```dart
abstract class ReplayBufferRepository {
  Future<void> enable(int seconds);
  Future<void> disable();
  Future<void> save();
}
```

Create `apps/mobile/lib/features/replay/data/pigeon_replay_buffer_repository.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';

class PigeonReplayBufferRepository implements ReplayBufferRepository {
  PigeonReplayBufferRepository(this._api);

  final ReplayBufferHostApi _api;

  @override
  Future<void> enable(int seconds) => _api.enableReplayBuffer(seconds);

  @override
  Future<void> disable() => _api.disableReplayBuffer();

  @override
  Future<void> save() => _api.saveReplay();
}
```

Create `apps/mobile/lib/features/replay/data/replay_buffer_repository_provider.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:raro_mobile/features/replay/data/pigeon_replay_buffer_repository.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_buffer_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ReplayBufferRepository replayBufferRepository(Ref ref) =>
    PigeonReplayBufferRepository(ReplayBufferHostApi());
```

- [ ] **Step 5: Codegen + rodar testes**

Run: `bun run --filter '@raro/mobile' codegen && bun run --filter '@raro/mobile' test test/features/replay/`
Expected: PASS (7 testes: 4 state + 3 repository).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/replay/domain apps/mobile/lib/features/replay/data apps/mobile/test/features/replay/replay_buffer_state_test.dart apps/mobile/test/features/replay/replay_buffer_repository_test.dart
git commit -m "feat(replay): replay buffer state + repository port (tdd)"
```

---

## Task 8: Dart — flutter api stream + controller Notifier (TDD)

**Files:**
- Create: `apps/mobile/lib/features/replay/application/replay_flutter_api_provider.dart`
- Create: `apps/mobile/lib/features/replay/application/replay_buffer_controller.dart`
- Test: `apps/mobile/test/features/replay/replay_buffer_controller_test.dart`

- [ ] **Step 1: Escrever o teste do controller que falha**

Create `apps/mobile/test/features/replay/replay_buffer_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/replay/application/replay_buffer_controller.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository_provider.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';

class _MockRepo extends Mock implements ReplayBufferRepository {}

void main() {
  late _MockRepo repo;
  late StreamController<ReplayResult> events;

  setUp(() {
    repo = _MockRepo();
    events = StreamController<ReplayResult>.broadcast();
  });

  tearDown(() => events.close());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        replayBufferRepositoryProvider.overrideWithValue(repo),
        replayEventsProvider.overrideWithValue(events.stream),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('initial state is idle', () {
    final container = makeContainer();
    expect(container.read(replayBufferControllerProvider), isA<ReplayIdle>());
  });

  test('setWindow enables the buffer and reflects buffering state', () async {
    when(() => repo.enable(any())).thenAnswer((_) async {});
    final container = makeContainer();
    await container.read(replayBufferControllerProvider.notifier).setWindow(30);
    expect(
      container.read(replayBufferControllerProvider),
      isA<ReplayBuffering>().having((s) => s.seconds, 'seconds', 30),
    );
    verify(() => repo.enable(30)).called(1);
  });

  test('save transitions through saving and back to buffering', () async {
    when(() => repo.enable(any())).thenAnswer((_) async {});
    when(() => repo.save()).thenAnswer((_) async {});
    final container = makeContainer();
    final notifier = container.read(replayBufferControllerProvider.notifier);
    await notifier.setWindow(15);
    await notifier.save();
    verify(() => repo.save()).called(1);
    expect(container.read(replayBufferControllerProvider), isA<ReplayBuffering>());
  });

  test('onReplayFailed event sets failed state', () async {
    when(() => repo.enable(any())).thenAnswer((_) async {});
    final container = makeContainer();
    container.read(replayBufferControllerProvider.notifier);
    await container.read(replayBufferControllerProvider.notifier).setWindow(15);
    events.add(const ReplayResult.failed(code: 'thermalThrottled', message: null));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(replayBufferControllerProvider), isA<ReplayFailedState>());
  });
}
```

- [ ] **Step 2: Rodar — espera FALHAR**

Run: `bun run --filter '@raro/mobile' test test/features/replay/replay_buffer_controller_test.dart`
Expected: FAIL de compilação.

- [ ] **Step 3: Implementar o flutter api provider (stream de eventos)**

Create `apps/mobile/lib/features/replay/application/replay_flutter_api_provider.dart`:

```dart
import 'dart:async';

import 'package:raro_mobile/core/native_bridges/generated/replay_buffer_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_flutter_api_provider.g.dart';

sealed class ReplayResult {
  const ReplayResult();

  const factory ReplayResult.saved({
    required String path,
    required int durationMs,
  }) = ReplaySavedResult;

  const factory ReplayResult.failed({
    required String code,
    String? message,
  }) = ReplayFailedResult;
}

class ReplaySavedResult extends ReplayResult {
  const ReplaySavedResult({required this.path, required this.durationMs});
  final String path;
  final int durationMs;
}

class ReplayFailedResult extends ReplayResult {
  const ReplayFailedResult({required this.code, this.message});
  final String code;
  final String? message;
}

@Riverpod(keepAlive: true)
Raw<Stream<ReplayResult>> replayEvents(Ref ref) {
  final controller = StreamController<ReplayResult>.broadcast();
  ReplayBufferFlutterApi.setUp(_ReplayFlutterApi(controller));
  ref.onDispose(() {
    ReplayBufferFlutterApi.setUp(null);
    controller.close();
  });
  return controller.stream;
}

class _ReplayFlutterApi implements ReplayBufferFlutterApi {
  _ReplayFlutterApi(this._sink);

  final StreamController<ReplayResult> _sink;

  @override
  void onReplaySaved(String path, int durationMs) =>
      _sink.add(ReplayResult.saved(path: path, durationMs: durationMs));

  @override
  void onReplayFailed(String code, String? message) =>
      _sink.add(ReplayResult.failed(code: code, message: message));
}
```

- [ ] **Step 4: Implementar o controller Notifier**

Create `apps/mobile/lib/features/replay/application/replay_buffer_controller.dart`:

```dart
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository_provider.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_buffer_controller.g.dart';

@riverpod
class ReplayBufferController extends _$ReplayBufferController {
  @override
  ReplayBufferState build() {
    final events = ref.watch(replayEventsProvider);
    final subscription = events.listen((event) {
      if (event is ReplayFailedResult) {
        state = ReplayBufferState.failed(message: event.message ?? event.code);
      } else if (event is ReplaySavedResult) {
        final current = state;
        if (current is ReplayBuffering) {
          state = current;
        } else if (current is! ReplayIdle) {
          state = const ReplayBufferState.idle();
        }
      }
    });
    ref.onDispose(subscription.cancel);
    return const ReplayBufferState.idle();
  }

  Future<void> setWindow(int seconds) async {
    final repo = ref.read(replayBufferRepositoryProvider);
    await repo.enable(seconds);
    state = ReplayBufferState.buffering(seconds: seconds);
  }

  Future<void> disable() async {
    final repo = ref.read(replayBufferRepositoryProvider);
    await repo.disable();
    state = const ReplayBufferState.idle();
  }

  Future<void> save() async {
    final current = state;
    final repo = ref.read(replayBufferRepositoryProvider);
    state = const ReplayBufferState.saving();
    try {
      await repo.save();
    } finally {
      state = current is ReplayBuffering
          ? current
          : const ReplayBufferState.idle();
    }
  }
}
```

- [ ] **Step 5: Codegen + rodar testes**

Run: `bun run --filter '@raro/mobile' codegen && bun run --filter '@raro/mobile' test test/features/replay/replay_buffer_controller_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/replay/application/replay_flutter_api_provider.dart apps/mobile/lib/features/replay/application/replay_flutter_api_provider.g.dart apps/mobile/lib/features/replay/application/replay_buffer_controller.dart apps/mobile/lib/features/replay/application/replay_buffer_controller.g.dart apps/mobile/test/features/replay/replay_buffer_controller_test.dart
git commit -m "feat(replay): controller notifier reativo + stream de eventos da bridge (tdd)"
```

---

## Task 9: Dart — replay vault sink (TDD)

**Files:**
- Create: `apps/mobile/lib/features/replay/application/replay_vault_sink.dart`
- Test: `apps/mobile/test/features/replay/replay_vault_sink_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

Create `apps/mobile/test/features/replay/replay_vault_sink_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  late Directory tempRoot;
  late File savedReplay;
  late StreamController<ReplayResult> events;
  late _MockCameraRepository repository;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('replay_sink_test_');
    savedReplay = File('${tempRoot.path}/raro_replay_x.mp4')
      ..writeAsBytesSync(List.filled(1024, 7));
    events = StreamController<ReplayResult>.broadcast();
    repository = _MockCameraRepository();
  });

  tearDown(() async {
    await events.close();
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        replayEventsProvider.overrideWithValue(events.stream),
        vaultServiceProvider.overrideWith(
          (ref) async => VaultService(documentsDir: tempRoot),
        ),
        cameraRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('saves the replay video to vault with isReplay true', () async {
    when(() => repository.generateThumbnail(any()))
        .thenAnswer((_) async => '${tempRoot.path}/vault/x.jpg');
    final container = makeContainer();
    container.read(replayVaultSinkProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    events.add(ReplayResult.saved(path: savedReplay.path, durationMs: 15000));

    final vault = VaultService(documentsDir: tempRoot);
    var videos = <VideoEntity>[];
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      videos = await vault.listAll();
      if (videos.isNotEmpty) break;
    }
    expect(videos.single.isReplay, isTrue);
    expect(File(videos.single.filePath!).existsSync(), isTrue);
  });
}
```

- [ ] **Step 2: Rodar — espera FALHAR**

Run: `bun run --filter '@raro/mobile' test test/features/replay/replay_vault_sink_test.dart`
Expected: FAIL de compilação (`replayVaultSinkProvider` não existe).

- [ ] **Step 3: Implementar o sink**

Create `apps/mobile/lib/features/replay/application/replay_vault_sink.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replay_vault_sink.g.dart';

@Riverpod(keepAlive: true)
StreamSubscription<ReplayResult> replayVaultSink(Ref ref) {
  final events = ref.watch(replayEventsProvider);
  final repository = ref.watch(cameraRepositoryProvider);
  final logger = ref.watch(appLoggerProvider);
  final subscription = events.listen((event) async {
    if (event is ReplayFailedResult) {
      logger.e('replay failed code=${event.code} message=${event.message}');
      return;
    }
    if (event is! ReplaySavedResult) return;
    final vault = await ref.read(vaultServiceProvider.future);
    final source = File(event.path);
    final id = _idFromPath(event.path);
    final recordedAt = DateTime.now();
    final metadata = RecordingMetadata(
      id: id,
      name: _nameFor(recordedAt),
      duration: Duration(milliseconds: event.durationMs),
      recordedAt: recordedAt,
      isReplay: true,
      thumbnailHue: _hueFor(id),
    );
    final entity = await vault.save(source, metadata: metadata);
    await _generateThumbnail(repository, logger, vault, id, entity.filePath);
    if (ref.mounted) ref.invalidate(videoListProvider);
  });
  ref.onDispose(subscription.cancel);
  return subscription;
}

Future<void> _generateThumbnail(
  CameraRepository repository,
  Logger logger,
  VaultService vault,
  String id,
  String? videoPath,
) async {
  if (videoPath == null) return;
  try {
    final thumbnailPath = await repository.generateThumbnail(videoPath);
    await vault.attachThumbnail(id, thumbnailPath);
  } on Object catch (error) {
    logger.w('replay thumbnail generation failed id=$id error=$error');
  }
}

String _idFromPath(String path) {
  final fileName = path.split('/').last;
  final dot = fileName.lastIndexOf('.');
  final stem = dot == -1 ? fileName : fileName.substring(0, dot);
  return stem.startsWith('raro_replay_') ? stem.substring(12) : stem;
}

String _nameFor(DateTime at) {
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  return 'Replay $hh:$mm';
}

int _hueFor(String id) => id.hashCode.abs() % 360;
```

- [ ] **Step 4: Codegen + rodar teste**

Run: `bun run --filter '@raro/mobile' codegen && bun run --filter '@raro/mobile' test test/features/replay/replay_vault_sink_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/replay/application/replay_vault_sink.dart apps/mobile/lib/features/replay/application/replay_vault_sink.g.dart apps/mobile/test/features/replay/replay_vault_sink_test.dart
git commit -m "feat(replay): replay vault sink dedicado (vault + thumbnail + isreplay)"
```

---

## Task 10: Wire na camera_screen (buffer sempre-ativo + duração + erro)

**Files:**
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart`

- [ ] **Step 1: Ligar o buffer ao ciclo de vida da câmera + propagar duração + surfa erro**

Em `camera_screen.dart`, no `build` (após `ref.watch(recordingVaultSinkProvider);`, linha 188), adicionar:

```dart
    ref.watch(replayVaultSinkProvider);
    final replayState = ref.watch(replayBufferControllerProvider);
```

Após o bloco `ref.listen(settingsControllerProvider, ...)` (linha 206), adicionar a sincronização da duração do buffer com o shell + o surface de erro:

```dart
    ref.listen(cameraControllerProvider, (_, next) {
      if (next.value is CameraStateReady) {
        ref
            .read(replayBufferControllerProvider.notifier)
            .setWindow(shell.bufferDuration.seconds);
      }
    });

    ref.listen(replayBufferControllerProvider, (_, next) {
      if (next is ReplayFailedState && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_replayErrorMessage(next.message))),
        );
      }
    });
```

Modificar o `onToggleBuffer` (linha 241-243) para propagar a nova duração ao buffer nativo após alternar:

```dart
                      onToggleBuffer: () {
                        final notifier = ref.read(cameraShellProvider.notifier)
                          ..toggleBufferDuration();
                        final next = ref.read(cameraShellProvider).bufferDuration;
                        ref
                            .read(replayBufferControllerProvider.notifier)
                            .setWindow(next.seconds);
                        notifier;
                      },
```

Adicionar o helper de mensagem (no fim do `_CameraScreenState`, após `_onRecTap` ou perto de `dispose`):

```dart
  String _replayErrorMessage(String code) {
    if (code == 'thermalThrottled') {
      return 'Replay pausado: o aparelho está aquecido.';
    }
    return 'Não foi possível salvar o replay.';
  }
```

Adicionar os imports necessários no topo do arquivo:

```dart
import 'package:raro_mobile/features/replay/application/replay_buffer_controller.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';
```

> Nota: `replayState` é lido para forçar o rebuild quando o estado muda (mantém o `ref.watch` ativo). Se o analyze reclamar de variável não usada, prefixar com `_ = replayState;` ou usar `ref.watch(replayBufferControllerProvider);` sem atribuir. Confirmar `CameraStateReady` / `cameraControllerProvider` já importados (já usados na linha 185-186).

- [ ] **Step 2: Analyze + rodar a suíte completa**

Run: `bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test`
Expected: analyze 0; toda a suíte PASS (baseline 255 + novos testes de replay).

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/camera/presentation/camera_screen.dart
git commit -m "feat(replay): liga buffer ao ciclo de vida da câmera + duração via pill + erro via snackbar"
```

---

## Task 11: Órfão 1 — vault sidecar race (regressão, red-before-green)

**Files:**
- Test: `apps/mobile/test/features/camera/data/vault_service_race_test.dart`

- [ ] **Step 1: Escrever o teste de regressão**

Create `apps/mobile/test/features/camera/data/vault_service_race_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

void main() {
  late Directory tempRoot;
  late VaultService vault;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vault_race_test_');
    vault = VaultService(documentsDir: tempRoot);
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  RecordingMetadata meta(String id) => RecordingMetadata(
        id: id,
        name: 'Vídeo $id',
        duration: const Duration(seconds: 5),
        recordedAt: DateTime.now(),
        isReplay: false,
        thumbnailHue: 120,
      );

  test('concurrent save and listAll never throws FormatException', () async {
    final source = File('${tempRoot.path}/src.mp4')
      ..writeAsBytesSync(List.filled(512, 1));
    // semeia um arquivo para haver o que listar durante a escrita
    await vault.save(source, metadata: meta('seed'));

    Object? caught;
    final futures = <Future<void>>[];
    for (var i = 0; i < 40; i++) {
      futures.add(vault.save(source, metadata: meta('id$i')));
      futures.add(() async {
        try {
          await vault.listAll();
        } on FormatException catch (e) {
          caught = e;
        }
      }());
    }
    await Future.wait(futures);
    expect(caught, isNull,
        reason: 'listAll leu um sidecar parcial durante a escrita');
  });

  test('no orphan .json.tmp remains after writes', () async {
    final source = File('${tempRoot.path}/src.mp4')
      ..writeAsBytesSync(List.filled(512, 1));
    for (var i = 0; i < 20; i++) {
      await vault.save(source, metadata: meta('id$i'));
    }
    final vaultDir = Directory('${tempRoot.path}/vault');
    final tmps = vaultDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json.tmp'))
        .toList();
    expect(tmps, isEmpty);
  });
}
```

- [ ] **Step 2: Rodar — DEVE PASSAR (o fix tmp+rename já está no código)**

Run: `bun run --filter '@raro/mobile' test test/features/camera/data/vault_service_race_test.dart`
Expected: PASS. (Este é um teste de regressão "green-locking": o fix `_writeMetaAtomic` já existe — o teste trava o comportamento contra reversão. Se FALHAR, é porque alguém reverteu o tmp+rename — investigar antes de prosseguir.)

> Nota sobre red-before-green: para provar que o teste pega o bug, opcionalmente trocar `_writeMetaAtomic` por `writeAsString` direto em `vault_service.dart` localmente, rodar (deve FALHAR), depois reverter. Não commitar a quebra.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/test/features/camera/data/vault_service_race_test.dart
git commit -m "test(vault): regressão race read-during-write (órfão 1, trava escrita atômica)"
```

---

## Task 12: Órfão 2 — ref após dispose em listener async (regressão)

**Files:**
- Test: `apps/mobile/test/features/replay/replay_vault_sink_dispose_test.dart`

- [ ] **Step 1: Escrever o teste de regressão**

Create `apps/mobile/test/features/replay/replay_vault_sink_dispose_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';

class _MockCameraRepository extends Mock implements CameraRepository {}

void main() {
  test('disposing the container mid-save does not throw ref-after-dispose',
      () async {
    final tempRoot = await Directory.systemTemp.createTemp('replay_dispose_');
    addTearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });
    final saved = File('${tempRoot.path}/raro_replay_y.mp4')
      ..writeAsBytesSync(List.filled(512, 3));
    final events = StreamController<ReplayResult>.broadcast();
    addTearDown(events.close);
    final repository = _MockCameraRepository();
    when(() => repository.generateThumbnail(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return '${tempRoot.path}/vault/y.jpg';
    });

    final container = ProviderContainer(
      overrides: [
        replayEventsProvider.overrideWithValue(events.stream),
        vaultServiceProvider
            .overrideWith((ref) async => VaultService(documentsDir: tempRoot)),
        cameraRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.read(replayVaultSinkProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    events.add(ReplayResult.saved(path: saved.path, durationMs: 15000));
    // dispõe no meio do gap async (save + thumbnail em andamento)
    await Future<void>.delayed(const Duration(milliseconds: 15));
    container.dispose();
    // dá tempo para o callback async terminar; não pode lançar
    await Future<void>.delayed(const Duration(milliseconds: 60));
  });
}
```

- [ ] **Step 2: Rodar — DEVE PASSAR (o fix `if (ref.mounted)` já está no sink)**

Run: `bun run --filter '@raro/mobile' test test/features/replay/replay_vault_sink_dispose_test.dart`
Expected: PASS sem exceção não capturada. (Green-locking: o sink já usa `if (ref.mounted)` antes do `invalidate` e captura deps antes do await. Se FALHAR com "Cannot use Ref after disposed", o guard foi removido.)

> Nota red-before-green: para provar, remover localmente o `if (ref.mounted)` do `replay_vault_sink.dart` → rodar (FALHA) → reverter. Não commitar a quebra.

- [ ] **Step 3: Rodar a suíte de replay em sequência (expõe o bug de lifecycle)**

Run: `bun run --filter '@raro/mobile' test test/features/replay/`
Expected: PASS — todos os testes de replay rodando no mesmo processo, em sequência (o bug ref-after-dispose só aparece em sequência, não isolado).

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/test/features/replay/replay_vault_sink_dispose_test.dart
git commit -m "test(replay): regressão ref-after-dispose em listener async (órfão 2)"
```

---

## Task 13: Suíte completa + build iOS limpo

- [ ] **Step 1: Analyze + suíte Dart completa**

Run: `bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test`
Expected: analyze 0; toda a suíte PASS.

- [ ] **Step 2: XCTest nativo completo**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS — confirmar no output `Test Suite 'ReplayRingTests' started` (memória pbxproj) + as suítes existentes.

- [ ] **Step 3: Build iOS profile para device (gate de device vem na Task 14)**

Run: `cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always flutter build ios --profile 2>&1 | tail -25`
Expected: `✓ Built` + conferir o timestamp do `.app` (memória "exit 0 enganoso" — não confiar só no exit code).

- [ ] **Step 4: Commit (se houver `.g`/format pendente)**

```bash
git add -A && git commit -m "chore(replay): suíte verde + build ios limpo pré-device" || echo "nada a commitar"
```

---

## Task 14: Gate de device (iPhone 12) — NÃO declarar pronto sem isto

Replay buffer toca Method Channel + hot path de câmera + caminho que decide formato gravado. Gate obrigatório em iPhone 12 físico (CLAUDE.md §10, ADR-0021, ADR-0016). XCTest com sample buffers fake é cego ao bug real de entrega.

- [ ] **Step 1: Instalar a build no iPhone 12**

Run (com `<udid>` do device):
```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always xcrun devicectl device install app --device <udid> build/ios/iphoneos/Runner.app && xcrun devicectl device process launch --device <udid> com.rarocamera
```

- [ ] **Step 2: Validar com o usuário (manual no device)** — checklist:
  - Abrir a câmera; o buffer inicia (os_log subsystem `com.rarocamera` category `replay` mostra "replay buffering started").
  - Alternar o pill 15s↔30s; conferir no log que `setWindow` chega ao nativo (sem crash, preview não pisca).
  - Acionar `saveReplay` (via caminho de teste/debug desta sessão — NÃO há UI de produção de save ainda; usar um gatilho temporário OU `/debug/self-test` se existir); confirmar `onReplaySaved` e o replay aparecendo na galeria com thumbnail.
  - Com buffer ativo: `startRecording`→`stopRecording` ainda produz vídeo reproduzível (G1 não regrediu).
  - tap→ring <50ms e tap→focus locked <300ms NÃO regridem com buffer ativo (os_log subsystem `com.rarocamera/focus`).
  - preview ao vivo permanece (não fica preto) ao iniciar buffer / `setWindow` / `saveReplay`.
  - memória/térmico: `ProcessInfo.thermalState` — buffer não estoura jetsam.

- [ ] **Step 3: Prova ffprobe (gate §10/ADR-0021)** — puxar o `.mp4` de replay do vault e provar formato:

```bash
xcrun devicectl device copy from --device <udid> --domain-type appDataContainer --domain-identifier com.rarocamera --source Documents/vault --destination /tmp/raro_vault_dump
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,codec_name /tmp/raro_vault_dump/vault/<replay_id>.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels /tmp/raro_vault_dump/vault/<replay_id>.mp4
```
Expected: dimensões/fps reais coerentes com o formato ativo (passthrough preserva); stream de áudio AAC presente (replay com som). Anexar a saída no PR.

- [ ] **Step 4: Se algo regredir, systematic-debugging com logs reais** (memória `feedback_device_debug_use_real_logs_not_assumptions`) — não inventar workaround sem evidência de log.

---

## Task 15: Fechamento da sessão

- [ ] **Step 1: `/session-end`** — appenda session log em `docs/sessions/`, define objetivo da próxima sessão (pré-roll-no-REC), atualiza `0001-INDEX.md`, commit `docs(docs): close session 0021`.

- [ ] **Step 2: Confirmar 0 `--no-verify` em toda a sessão** (`git log --oneline` da sessão; todos passaram pelos hooks).

---

## Self-review checklist (preenchido pelo autor do plano)

- **Spec coverage:** ReplayBuffer.swift (T2/T3), fan-out (T4), contrato Pigeon (T1), HostApiImpl+registro (T5), Android stub (T6), state+repository (T7), controller Notifier+stream (T8), vault sink dedicado (T9), wire camera_screen (T10), órfãos 1+2 (T11/T12), gates de device+ffprobe (T14). Pré-roll explicitamente OUT (próxima fatia) — coberto na spec §out-of-scope. ✅
- **Placeholder scan:** sem TBD/TODO; todo step com código ou comando concreto. ✅
- **Type consistency:** `ReplayBufferState`/`ReplayIdle`/`ReplayBuffering`/`ReplaySaving`/`ReplayFailedState` consistentes entre T7/T8/T10; `ReplayResult`/`ReplaySavedResult`/`ReplayFailedResult` entre T8/T9/T12; `ReplayBufferRepository.enable/disable/save` entre T7/T8; Swift `ReplayRing`/`Chunk`/`ReplayBuffer`/`ReplayBufferError` entre T2/T3/T4/T5; `enableReplayBuffer(int seconds)` no contrato (T1) ↔ `setReplayWindow(seconds:)` no manager (T4) ↔ `enable(int)` no repo (T7). ✅
- **Duas `BufferDuration`:** o `cameraShellProvider` usa `BufferDuration.fifteenSec/thirtySec` (`.seconds`); o contrato Pigeon recebe `int seconds`. T10 passa `shell.bufferDuration.seconds` (int) ao `setWindow`. Sem cruzar com a `BufferDuration` de `raro_shared` (settings). ✅
