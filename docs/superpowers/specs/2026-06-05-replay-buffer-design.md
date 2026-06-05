# Spec — Replay Buffer (S2.B) · Design

- **Data:** 2026-06-05
- **Sessão:** S2.B (Sprint 2 Task B — replay buffer, IMPLEMENTAÇÃO)
- **Branch:** `feat/camera-native-bridge`
- **Status:** Approved (design validado com o usuário; ADR-0003 Addendum 2026-06-05 mergeado antes do código)
- **ADRs:** ADR-0003 (Addendum 2026-06-05 — chunked disk-ring), ADR-0020 (pipeline unificado), ADR-0021 (gate §10 prova de formato), ADR-0016 (harness E2E híbrido)

## Modelo do produto (fonte de verdade)

O **Raro Replay** é um buffer rotativo **sempre ativo** enquanto a câmera está aberta: mantém os últimos N segundos (15s ou 30s) de vídeo+áudio. O protótipo (`Prototipo-RARO.html` linhas 601, 766-769, 940-942) fixa:

- O buffer está **sempre ativo** (não há liga/desliga manual). O `BufferPill` na câmera **só alterna a duração** (15s ↔ 30s).
- O fluxo final do produto é **pré-roll embutido na gravação**: ao apertar REC (ou, no futuro, dizer "Raro"), o vídeo salvo inclui os últimos N segundos do buffer + a gravação contínua, num `.mp4` único. ("salva automaticamente os últimos 15 ou 30 segundos... basta apertar REC.")

Padrão validado em apps consolidados (dashcam/replay buffer / OBS): buffer cíclico contínuo; ao acionar, persiste o buffer + a captura do momento em diante. Referência mental conferida em app de mercado (sem citar marca — wake word/marca do RARO é "Raro", ADR-0009).

## Escopo desta sessão (fatia B — decisão do usuário)

**Esta sessão entrega a MECÂNICA do buffer isolada, não o fluxo pré-roll completo.** Razão: o pré-roll-no-REC acopla o replay à gravação G1 (concatenar buffer + gravação com sync de áudio na junção). Empilhar duas integrações nativas não-validadas no mesmo gate de device dificulta isolar a causa de uma falha (memória `feedback_device_debug_use_real_logs_not_assumptions`). Fatiar valida o ring buffer como fundação sólida antes de amarrá-lo à gravação — espelha a B0 (pipeline) ter sido pré-requisito validado.

**Entregável fechado desta sessão =**
- (a) `ReplayBuffer.swift`: ring de chunks `.mp4` rolando **sempre que a câmera está ativa** (chunked disk-ring, ADR-0003 Addendum 2026-06-05).
- (b) Contrato Pigeon dedicado (`replay_buffer_api.dart`) + bridge registrado.
- (c) Provider `@riverpod` Notifier reativo escutando o stream da bridge.
- (d) `BufferPill` alterna 15s/30s ligado ao estado real (já existe o toggle de duração em `cameraShellProvider`/settings — esta sessão o conecta à duração efetiva do buffer nativo).
- (e) `saveReplay()` persiste **só a janela do buffer** (últimos N segundos) num `.mp4` no vault → galeria com thumbnail, `isReplay: true`, reproduz. **Validação isolada da mecânica do ring em device (ffprobe).**
- (f) Gravação G1 não regride; testes não regridem; órfãos 1+2 cobertos red-before-green.

**Diferido para a sessão seguinte (explícito):** o **pré-roll-no-REC** (concatenar buffer + gravação contínua num clipe, com foco em áudio sync na junção). Nesta sessão, `saveReplay` é uma ação de mecânica/validação que grava a janela isoladamente — **não** é o gatilho final do produto. O `BufferPill` ainda não dispara save (sem gesto de save no protótipo); o `saveReplay` é exercido pelo gate de device e por um caminho de teste, não por UI de produção definitiva. A UI final de acionar replay = pré-roll no REC, próxima fatia.

## Princípio de design

Buffer **encoded em disco**, rotativo com teto fixo — não frames em RAM, não fragmented MP4. Reusa o `AVAssetWriter` `.mp4` progressivo já validado em device. Estratégia fixada no ADR-0003 Addendum 2026-06-05 (chunked disk-ring), após pesquisa de fonte primária que rebaixou a estratégia A do Addendum anterior.

---

## Arquitetura

### Nativo iOS

**`ReplayBuffer.swift` (novo)** — deque circular de chunks `.mp4` progressivos:
- `AVAssetWriter(fileType: .mp4)` curto por chunk (`chunkDuration ≈ 1s`), vídeo + áudio (`expectsMediaDataInRealTime = true`), em `FileManager.default.temporaryDirectory`.
- Ao completar `chunkDuration`: `finishWriting` do chunk atual, abre o próximo, **deleta o mais antigo** além da janela. Teto `K = ceil(seconds / chunkDuration) + 1`.
- `start(seconds:)` / `stop()` / `save(completion:)` / `reset()` / `setWindow(seconds:)` — toda manipulação na **`outputQueue` serial** do `RecordingPipeline` (sem nova race com `focusAtAsync` na `sessionQueue`).
- `start` consulta `ProcessInfo.processInfo.thermalState`; sob `.serious`/`.critical` recusa e sinaliza falha (`thermalThrottled`).
- `save`: concat dos chunks da janela via **`AVMutableComposition`** (`insertTimeRange` vídeo + áudio, em ordem) → **`AVAssetExportSession(presetPassthrough)`** → `.mp4` final → callback assíncrono. Passthrough = sem re-encode (preserva formato → gate §10).
- `reset`: limpa a deque + reabre chunk (chamado em `setFormat`/lens físico, pois dimensões mudam).
- `setWindow`: ajusta a janela 15↔30s sem perder os chunks já bufferizados (recalcula `K`).

**`RecordingPipeline.swift` (modificar)** — fan-out no `captureOutput`:
- Adiciona `var replayConsumer: ((CMSampleBuffer, Bool) -> Void)?` (closure leve; `isVideo` flag).
- No `captureOutput`, após o caminho de gravação existente, chama `replayConsumer?(sampleBuffer, isVideo)`. **Sem alterar o comportamento da gravação** — fan-out aditivo. Append do mesmo buffer em dois inputs é seguro (passthrough, não modifica — Apple `AVAssetWriterInput.append`).

**`CameraManager.swift` (modificar)** — possui um `ReplayBuffer`; o buffer é iniciado **junto com a sessão** (sempre-ativo) e parado no `stopSession`; expõe `setReplayWindow(seconds:)`/`saveReplay()`; liga `recordingPipeline.replayConsumer` ao `replayBuffer.append`; chama `replayBuffer.reset()` no `setFormat` (após reconfiguração) e no lens switch físico; guard `isInterrupted` no `saveReplay` (espelha `startRecording`/`setFormat`).

**`ReplayBufferHostApiImpl.swift` (novo)** — registra `ReplayBufferHostApi` no `AppDelegate` (canal `com.rarocamera/replay_buffer`); recebe referência ao **mesmo** `CameraManager` que o `CameraHostApiImpl` usa (um manager por sessão de câmera — decisão de wiring no plano); delega `enableReplayBuffer`(= setWindow + garante ativo) / `disableReplayBuffer` / `saveReplay`; entrega `onReplaySaved`/`onReplayFailed` via `ReplayBufferFlutterApi`.

> Nota: o contrato expõe `enableReplayBuffer/disableReplayBuffer` (forma genérica do canal), mas no modelo do produto o buffer é sempre-ativo com a câmera; `enable` na prática fixa a janela e garante o buffer rodando. O liga/desliga existe no contrato para Android/futuro e para teste, não como toggle de produto.

### Contrato Pigeon (`replay_buffer_api.dart`, substitui stubs)

```dart
@HostApi()
abstract class ReplayBufferHostApi {
  void enableReplayBuffer(int seconds); // 15/30 — BufferDuration.value de raro_shared
  void disableReplayBuffer();
  void saveReplay();                     // path entregue ASSÍNCRONO via onReplaySaved
}

@FlutterApi()
abstract class ReplayBufferFlutterApi {
  void onReplaySaved(String path, int durationMs);
  void onReplayFailed(String code, String? message); // nome simbólico, nunca rawValue (hook block-pigeon-error-rawvalue)
}
```
Re-codegen Dart + Swift + Kotlin. Kotlin = stub lançando `formatUnsupported` (Android backlog Sprint 3).

### Dart

**`replay_buffer_repository.dart` + provider (novo)** — abstração testável sobre `ReplayBufferHostApi` (mock em teste, igual `CameraRepository`).

**`replay_flutter_api_provider.dart` (novo)** — stream de eventos `ReplaySaved`/`ReplayFailed` (espelha `camera_flutter_api_provider`), `@Riverpod(keepAlive: true)`, `setUp(null)` + `controller.close()` no `onDispose`.

**`replay_buffer_provider.dart` (novo)** — `@riverpod` Notifier reativo:
- Estado `ReplayBufferState` (sealed): `idle` / `buffering(seconds)` / `saving` / `failed(message)`. O save volta a `buffering` (não há estado "saved" terminal — o vídeo salvo é evento do `replayVaultSink`).
- Escuta o stream de `ReplayFlutterApi` no `build`; `ref.onDispose(subscription.cancel)`; lê deps síncronas no `build`; `if (ref.mounted)` após `await`; `try/finally` nas transições. Espelha `recording_controller.dart` + memórias `raro-pattern-flutter-async-native-state-needs-notifier` e `raro-pattern-riverpod-ref-after-dispose-async-listener`.
- Métodos: `setWindow(BufferDuration)`, `save()` delegando ao repository.

**`replay_vault_sink` (novo provider, keepAlive)** — escuta o stream de `ReplaySaved`, faz `vault.save(..., isReplay: true)` + `generateThumbnail` + `invalidate(videoListProvider)`. Sink **dedicado** (single responsibility — Riverpod 3 docs validadas via Context7/WebSearch), reusa `VaultService` e o gerador de thumbnail. NÃO mistura com `recordingVaultSink` (canais Pigeon distintos).

**`buffer_pill.dart` / `camera_screen.dart` (modificar)** — `BufferPill` reflete a duração real do buffer (15s/30s); `onToggleBuffer` alterna a duração via `cameraShellProvider` E propaga para o buffer nativo (`replay_buffer_provider.setWindow`); `camera_screen` inicia o buffer ao montar a câmera pronta e o reseta ao sair; surfa `failed` via SnackBar.

---

## Fluxo de dados (escopo desta sessão)

```
câmera pronta → buffer inicia (sempre-ativo)
captura (VideoDataOutput + AudioDataOutput, outputQueue)
  → RecordingPipeline.captureOutput
       ├─ writer de gravação (on-demand) [já existe, intocado]
       └─ replayConsumer → ReplayBuffer.append → chunk .mp4 atual
                                                  (deque rotativa, deleta o antigo)

pill alterna 15s/30s → setWindow (recalcula K, mantém chunks)

saveReplay (mecânica/gate de device nesta sessão)
  → ReplayBuffer.save: AVMutableComposition(chunks da janela) → ExportSession(passthrough) → .mp4
  → onReplaySaved(path, durationMs) [async]
  → replay_flutter_api stream → replay_buffer_provider (volta a buffering)
                              → replayVaultSink → vault.save(isReplay:true) + thumbnail + invalidate(videoList)
  → galeria mostra o replay
```

## Tratamento de erro

- `start`/`enable` sob `.serious`/`.critical` térmico → `onReplayFailed("thermalThrottled", ...)` → provider `failed` → SnackBar.
- `saveReplay` sem chunks / export falha → `onReplayFailed(code, message)` (nome simbólico, nunca rawValue — hook `block-pigeon-error-rawvalue`).
- `isInterrupted` (sessão em background) → `saveReplay` recusa com erro distinto (espelha Bug 2 da sessão 0020).
- Sem swallow de erro silencioso (CLAUDE.md §11); todo caminho de falha loga via `logger` ou propaga.

## Testing

**TDD lógica pura (Dart, red-before-green):**
- `replay_buffer_state` transições (idle→buffering→saving→buffering / →failed).
- `replay_buffer_repository` delegação (1 teste por método — memória `feedback_tdd_pin_behavior_not_type`).
- Provider Notifier: estado reflete eventos do stream; reset ao dispose.

**XCTest nativo (RunnerTests, lógica determinística do ring):**
- Rotação da deque: append além de `K` chunks → mantém só os `K` mais recentes, na ordem.
- Cálculo de `K` por (seconds, chunkDuration).
- Recorte da janela ao salvar (quais chunks entram). **Não** assertar "duração ~30s do arquivo final" com sample buffers fake (entrega real = device).
- 4 inserções no `project.pbxproj` por arquivo de teste novo (memória `raro-pattern-ios-xctest-pbxproj-4-insertions`); confirmar `Test Suite started` no output.

**Órfãos 1+2 (red-before-green, regressão):**
- **Vault-race:** `save()` + `listAll()` concorrentes N vezes (`Future.wait`) → nunca lança `FormatException`; nenhum `.json.tmp` órfão. (Relevância: replay grava mais arquivos → mesma janela de race.)
- **Ref-after-dispose:** dispose do `ProviderContainer` no meio de um listener async do replay → sem "Cannot use Ref after disposed"; rodar a suíte de providers em sequência no mesmo processo.

## Gates desta sessão (CLAUDE.md §10)

1. **ADR-0003 Addendum mergeado antes do código.** ✅ (feito no início da sessão.)
2. **Tocou contrato Pigeon → adr-guardian ANTES.** ✅ (rodado no design — veredito `ADR_AMEND_REQUIRED 0003` atendido pelo Addendum.)
3. **Tocou Method Channel → contract test do bridge.** iOS + Android (Android = stub `formatUnsupported`; contract test cobre os dois lados). Registrar no PR que paridade Android é Sprint 3.
4. **Tocou caminho que decide formato gravado → prova ffprobe no iPhone 12.** Salvar 1 replay, puxar o `.mp4` do vault (`devicectl copy from appDataContainer`), `ffprobe` provando dimensões/fps/codec reais (passthrough preserva o formato dos chunks). Anexar saída no PR.
5. **Breaking change interno → re-validar G1 em device.** Com buffer ativo: `startRecording`→`stopRecording` ainda produz vídeo reproduzível; preview não fica preto ao iniciar/resetar o buffer; tap→ring <50ms / tap→focus <300ms não regridem.
6. **XCTest nativo NÃO roda em CI → validar em device é obrigatório** (não opcional).
7. **Build iOS terminal-first** + 2 git overrides SPM; `flutter build ios --profile` + `devicectl` (debug não roda standalone); conferir `✓ Built` + timestamp (exit 0 enganoso). Reconfigurar device reseta `videoZoomFactor` → reaplicar `applyVirtualLensZoom`.

## Invariantes travados (não tocar)

Wake word "Raro" · trial **30 dias** (NÃO os 15 do app de referência) · planos R$ 9,90 / R$ 89,90 · bundle `com.rarocamera`.

## Out of scope (não nesta sessão)

- **Pré-roll-no-REC** (concat buffer + gravação contínua, áudio sync na junção) — **próxima fatia da S2.B**, é o fluxo final do produto.
- Android replay (Sprint 3 — só o stub Kotlin para o build não quebrar).
- Wake word / volume button / RevenueCat / share (Sprint 2 sessões seguintes).
- Órfãos 3 (Notifier reativo — cumprido pela própria implementação do provider) e 4 (device gate no `/verify-slice` — decisão de processo separada).
- Gap estrutural "XCTest em CI" (decisão de processo).
- Limpeza de `.mov` antigos do vault (ADR-0020 "vault novo").

## Em palavras simples

O app vai guardar, o tempo todo enquanto a câmera está aberta, os últimos 15 ou 30 segundos — como uma câmera de carro que mantém só o pedaço recente em rotação. Tecnicamente, ele grava pedacinhos de ~1 segundo no disco e vai jogando fora os antigos, mantendo só a janela escolhida.

**Nesta sessão** eu entrego e provo essa "engrenagem" funcionando: o buffer rolando, o botão que troca 15s↔30s, e um caminho que salva esses últimos segundos num vídeo na galeria (com som), validado no iPhone de verdade. **O que fica para a próxima vez** é juntar isso com a gravação normal — ou seja, quando você apertar REC, o vídeo já começar com os segundos anteriores ao toque. Decidimos separar porque juntar buffer + gravação + som no mesmo arquivo é a parte mais delicada (sincronizar o áudio na emenda), e fazer isso com a engrenagem já testada é muito mais seguro do que tudo de uma vez. Como é código de câmera nativo, só o iPhone físico prova que funciona.
