# 0021 — S2.B: mecânica do replay buffer (chunked disk-ring) + fix do gate térmico no device + pesquisa do pré-roll-no-REC

- **Data:** 2026-06-05 → 2026-06-07
- **Duração:** ~3 sessões de contexto (work longo, 2 compactações)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `cb4f857`, `dac5d16`, `45bc7bc`, `fff7911`, `7dfdc0a`, `c6aefa2`, `24d8f3d`, `5a60296`, `416c05e`, `6a40ef1`, `a09d4a0`, `2160829`, `2424c5b`, `b14a6e7`, `9f5d4a2`, `28aeaf9`, `d9ca3ea`, `bd415a1`, `d26ee52`, `d178582`, `b751bf8`, `2e67c82`, `c8dadc3` (23 commits)

## Objetivo

Entregar a **mecânica do replay buffer** (Sprint 2 Sessão S2.B): gravar continuamente os últimos N segundos (15s/30s) num buffer enquanto a câmera está ativa, com salvamento na galeria, atop o pipeline unificado (`VideoDataOutput`+`AVAssetWriter`) migrado na 0019. Escopo **fatiado por decisão do usuário**: mecânica do buffer nesta sessão; pré-roll-no-REC (o REC embute os últimos N s no arquivo) postergado para a fatia seguinte.

## Contexto inicial

Pré-flight (0018) corrigiu a planta; Task B0 (0019) migrou a gravação G1 para o pipeline unificado; 0020 fechou 3 bugs de câmera validados no device. ADR-0020 (pipeline unificado) e ADR-0003 (replay buffer) já existiam. Decisão arquitetural pendente: estratégia do ring (RAM raw vs encoded vs disco).

## O que foi feito

**Decisão de estratégia do ring (validada por websearch, não memória):** chunked disk-ring — deque de chunks `.mp4` progressivos curtos (~1s) em `temporaryDirectory`, concatenados no save via `AVMutableComposition` + `AVAssetExportSession` passthrough. Bate ambos os anti-padrões (MP4 fragmentado puro e retenção de `CMSampleBuffer` em RAM). **ADR-0003 Addendum 2026-06-05** (`dac5d16`) documenta; revoga o "descartado: 2 AVAssetWriter rotativos" do addendum anterior.

**Contrato Pigeon dedicado** (`fff7911`): `replay_buffer_api.dart` com `ReplayBufferHostApi` (`enableReplayBuffer`/`disableReplayBuffer`/`saveReplay`) + `ReplayBufferFlutterApi` (`onReplaySaved`/`onReplayFailed`). **Colisão `PigeonError`** descoberta no build da Task 5: cada `.g.swift` emite `final class PigeonError` com nome idêntico/internal → 2 no mesmo módulo Swift colidem. Resolvido via `SwiftOptions(errorClassName:)` **único nos 4 contratos** (Camera/ReplayBuffer/Voice/Volume), não só replay, p/ não reintroduzir em S2.C/S2.D. **ADR-0013 Addendum 2026-06-06** retifica a afirmação factualmente errada do ADR original ("Pigeon usa scoping prefixado") + adr-guardian `ADR_AMEND_REQUIRED 0013`.

**Nativo iOS:** `ReplayRing` determinístico (rotação/janela/reset, capacity=ceil(window/chunk)+1) + XCTests (`7dfdc0a`); `ReplayBuffer.swift` writer-por-chunk + save por composition + `finalizationGroup` gating do export (`c6aefa2`, `5a60296`); fan-out em `RecordingPipeline.swift:205` (`replayConsumer?(sampleBuffer, isVideo)` ANTES do guard de gravação, G1 preservada byte-a-byte) + wire no `CameraManager` (`6a40ef1`).

**Android stub** Kotlin (backlog Sprint 3, `b14a6e7`).

**Dart (TDD):** domain state sealed + repository port (`9f5d4a2`); stream de eventos + controller `@riverpod` autoDispose Notifier reativo (`28aeaf9`); replay vault sink dedicado com `isReplay:true` + thumbnail + `ref.mounted` guard (`d9ca3ea`); wire na `camera_screen` (`d26ee52`, 275/275 verde, autoDispose mantido vivo via `ref.watch`).

**2 testes órfãos red-before-green** (catalogados na 0018): race read-during-write do sidecar (`d178582`) + ref-after-dispose em listener async (`b751bf8`). **Subagents pegaram drafts tautológicos** (passavam com OU sem o fix) → corrigidos para red-before-green real (`2e67c82`).

**Bug do gate térmico (device-validated):** após o build, o usuário reportou "Replay pausado: o aparelho está aquecido" a cada cold-start (reabrir app / voltar de Settings) com o iPhone 12 **frio**, mas NÃO pelo pill. Causa-raiz (systematic-debugging): o gate de `ReplayBuffer.start()` bloqueava em `.serious` igual a `.critical`; `.serious` é estado comum/transitório no A14 (e o build de 19min deixou o device sob gestão térmica). Pelo pill não dava erro pois `setWindow` não recria a sessão. Fix: bloquear **só em `.critical`** (`c8dadc3`) + **ADR-0003 Addendum 2026-06-06**. **Confirmado no device pelo usuário: erro sumiu.**

**Gate de device (§10):** build profile `✓ Built Runner.app 47.1MB`, instalado no iPhone 12 via `devicectl`, validação manual do usuário (cold-start sem erro térmico).

**Investigação do concorrente "Ok Câmera"** (a pedido do usuário): dump ADB real no Galaxy M54 (uiautomator + screencap + navegação via `adb input`). Mapeado o modelo "OkReplay" das próprias palavras dele: *"grava 15/30s antes do comando de voz ou do botão"* — pré-roll embutido implícito, sem feedback (a causa da confusão que o usuário sentiu). Background "voz e vídeo" persistente. Trial 15d (RARO=30). Salvo em memória `raro-competitor-okcamera-replay-model`.

**Pesquisa + validação do pré-roll-no-REC** (decisão do usuário de copiar o concorrente, mas só após validar boas práticas): workflow multi-frente (eng AVFoundation, UX, Riverpod) + sonda no código real. **GO técnico com correção** — a sonda errou (Opção "writer único via insertTimeRange" não compila: `append()` só aceita `CMSampleBuffer`); estratégia correta = concatenação no STOP reusando `export()` existente. Desenho completo salvo em memória `raro-preroll-rec-design-s2c`.

## O que NÃO foi feito (e por quê)

- **Pré-roll-no-REC (REC embute os últimos N s):** postergado por decisão do usuário — esta sessão entregou a mecânica do buffer; o gatilho de produto é a fatia seguinte. Já pesquisado e desenhado (memória `raro-preroll-rec-design-s2c`), mas NÃO implementado.
- **Gatilho de UI para `saveReplay`:** o `saveReplay` existe no nativo + controller, mas NENHUM botão na tela o chama ainda. Por isso o replay "só muda o texto" no pill hoje — gravando em background sem forma de pegar o trecho. É a próxima fatia.
- **Android nativo do replay:** só stub (backlog Sprint 3).
- **Correção do bug catalogado** `RecordingController.start` setar `RecordingActive` no await em vez de por callback nativo (`raro-pattern-flutter-async-native-state-needs-notifier`): identificado, mas é mudança separada — fica para a fatia do pré-roll.
- **Degradar fps/resolução do buffer sob `.serious`** (ideal do addendum 2026-06-05): não-bloqueante, fica como melhoria futura; a janela de N s já limita o footprint.
- **Merge `feat/camera-native-bridge` → `develop`:** segurado (gates G1/G7 perf + Android M54 + goldens abertos).

## Aprendizados / surpresas

- **`.serious` ≠ `.critical` no gate térmico.** Apple: `.serious` = degradar carga; `.critical` = pausar+avisar. Tratar `.serious` como bloqueio = susto falso a cada cold-start no device frio. **Só pega em device real** — teste de widget/XCTest não simula thermalState transitório. Memória implícita no ADR-0003 Addendum 2026-06-06.
- **Assimetria pill vs cold-start revelou a causa.** O pill só chama `setWindow` (não recria sessão); cold-start recria a `CameraController` autoDispose → `startSession` → `replayBuffer.start()` → re-executa o gate. A assimetria do sintoma foi a pista.
- **Subagents pegaram 2 drafts de teste tautológicos** (passavam sem o fix) — validação independente por task funcionou exatamente como deveria.
- **Dump ADB de concorrente Android é viável e poderoso** (uiautomator + screencap + `adb input tap`); iOS bloqueia isso p/ apps de terceiros (`devicectl` só vê apps com dev profile). Memória `raro-competitor-okcamera-replay-model` documenta o how-to.
- **O concorrente é a prova viva do anti-padrão de UX:** modelo de replay 100% implícito/silencioso (Nielsen heurística #1, "hidden system state") = exatamente a confusão que o usuário sentiu. Reforça a estratégia RARO: copiar a mecânica, consertar o feedback.
- **Verificação adversarial pegou erro da própria sonda arquitetural** antes de virar plano (`AVAssetWriterInput.append()` só aceita `CMSampleBuffer`, não tracks de composition). Validar antes de planejar evitou desenho impossível.
- **`PigeonError` colide entre `.g.swift` no mesmo módulo** — premissa errada do ADR-0013 original mascarou até o build. `errorClassName` único por contrato resolve (análogo ao sub-package Kotlin do `FlutterError`).

## Próximos passos

- **Fatia seguinte (pré-roll-no-REC):** ADR-0003 addendum (cláusula `includeReplayPreroll`, modo não-default) ANTES do codegen Pigeon → `snapshotChunks()` no `ReplayBuffer` + `export()` reusável com chunk G1 ao fim → coordenação no `CameraManager` no stop → flag em `RecordingOptions` (Pigeon) → wire Dart. Feedback de UI (anel no REC enchendo + micro-confirmação "+Ns"). Gate §10: `ffprobe` no `.mp4` combinado. Detalhes em memória `raro-preroll-rec-design-s2c`.
- **Aproveitar a fatia p/ corrigir** `RecordingController.start` (estado por callback nativo, não no await) — mudança separada.
- **Decisão de produto a confirmar:** trocar formato durante "armado" = descartar pré-roll (coerente ADR-0021).
- **Backlog Sprint 2:** wake word ("Raro" aciona o mesmo save, camada por cima do botão), volume button, RevenueCat sandbox, share, analytics. Android nativo do replay = Sprint 3.

## Referências

- **Specs/plans:** `docs/superpowers/plans/2026-06-05-replay-buffer-s2b.md` (15 tasks, com débitos rastreados)
- **ADRs:** ADR-0003 Addendum 2026-06-05 (chunked disk-ring) + Addendum 2026-06-06 (gate térmico só `.critical`); ADR-0013 Addendum 2026-06-06 (`errorClassName` único por contrato)
- **Memórias novas:** `raro-competitor-okcamera-replay-model` (modelo do concorrente via dump ADB); `raro-preroll-rec-design-s2c` (desenho validado da próxima fatia)
- **Harness:** `cb4f857` (warn-adr-drift cobre `pigeons/` + gate §10 prova ffprobe de formato)
- **PRs:** nenhum (branch não mergeada)
