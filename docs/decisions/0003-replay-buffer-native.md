# 0003 — Replay Buffer 100% nativo (sem plugin Flutter)

- **Data:** 2026-05-25 (decisão original) · **Addenda:** 2026-06-04 (impl iOS), 2026-06-05 (chunked disk-ring), 2026-06-06 (gate térmico), 2026-06-07 (pré-roll no REC)
- **Status:** Accepted — **seção de implementação iOS revisada em 2026-06-04** (ver Addendum). A decisão estratégica (replay 100% nativo, sem plugin) permanece; a implementação iOS original era tecnicamente inviável e foi corrigida. **Addendum 2026-06-07** adiciona o modo de export combinado pré-roll-no-REC (`includeReplayPreroll`, não-default).
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Briefing Seção 6.2 + 7.4, Blueprint Seção 2.2 + 3.3. **Revisão 2026-06-04:** pré-flight da S2.B (sessão 0018) + ADR-0020 (pipeline de captura unificado).

## Contexto

O Raro Replay (feature core do produto) precisa manter um buffer circular em RAM dos últimos 15 ou 30 segundos de vídeo, e ao receber o comando de gravação, prepend esse buffer ao stream contínuo. Pesquisa em maio/2026 não retornou nenhum plugin Flutter pronto para este caso.

## Opções consideradas

1. **Implementação 100% nativa (iOS Swift + Android Kotlin)**
   - Prós: controle total sobre `CMSampleBuffer` (iOS) / `MediaCodec` (Android), performance previsível.
   - Contras: 2 implementações nativas a manter, RAM management exige cuidado.
2. **FFI + buffer em Dart**
   - Prós: uma única implementação.
   - Contras: cópia de frames entre native/Dart heap = jank garantido em 4K.
3. **Stream contínuo gravando 24/7 e cortar retroativamente**
   - Prós: simples.
   - Contras: drena bateria, escreve constantemente em disco, não atende ao requisito.

## Decisão

**Opção 1.** Implementação nativa via Method Channel `com.rarocamera/replay_buffer`.

> ⚠️ **A implementação iOS descrita originalmente abaixo é tecnicamente inviável e foi substituída — ver Addendum 2026-06-04.** O texto original é preservado (append-only) apenas como registro histórico; **não implementar conforme ele.**

- iOS (~~original, inviável~~): `AVCaptureSession` com `AVCaptureMovieFileOutput` segmentado. Buffer mantido como `CMSampleBuffer` em array circular. Salvamento via `AVAssetWriter` concatenando segmentos. *(Por que é inviável: `AVCaptureMovieFileOutput` não vende `CMSampleBuffer`, logo não pode alimentar um array circular de sample buffers; "MovieFileOutput segmentado" não é API; e MovieFileOutput não coexiste com VideoDataOutput — ADR-0020.)*
- Android: `CameraX VideoCapture` com `FileDescriptorOutputOptions`. Buffer em `MediaCodec` com encoding H.264, frames em `ByteBuffer` circular. Concat via `MediaMuxer`. *(Android segue como backlog de Sprint 3 — não revisado aqui; a memória `raro-pattern-android-mediacodec-buffer-management` já registra que MediaCodec é pool-based.)*

Estimativa de RAM ~~original~~ (assume frames CRUS — anti-padrão, ver Addendum):
- ~~15s em 1080p ≈ 70MB · 30s em 1080p ≈ 140MB · 15s em 4K ≈ 280MB · 30s em 4K ≈ 560MB~~

~~Pool de buffers reutilizável para minimizar GC pressure.~~

## Consequências

- **Positivas:**
  - Feature core funciona em qualidade de produção
  - Sem dependência externa
  - Performance previsível
- **Negativas:**
  - 30s em 4K consome 560MB de RAM (gate de hardware)
  - 2 implementações a manter
  - Bugs nativos exigem device físico para reproduzir
- **Como reverter:** se um plugin Flutter de qualidade aparecer, abrir novo ADR

## Referências

- [07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md) — contrato JSON do Method Channel
- [0002-camera-native-bridge.md](0002-camera-native-bridge.md)
- [0020-unified-capture-pipeline-videodataoutput.md](0020-unified-capture-pipeline-videodataoutput.md) — pipeline de captura unificado (revisão de implementação iOS)

---

## Addendum 2026-06-04 — Implementação iOS revisada (pipeline unificado)

A implementação iOS original (acima) era tecnicamente inviável. A pesquisa de pré-flight da S2.B (Apple Developer Forums, docs Apple, código React Native Vision Camera) e o ADR-0020 fixaram o caminho correto de 2026. A **decisão estratégica deste ADR não muda** (replay 100% nativo, sem plugin Flutter, buffer dos últimos 15s/30s); só a forma de implementar no iOS.

### iOS — decisão de implementação

O replay buffer compartilha o **pipeline de captura unificado** do ADR-0020: **um único `AVCaptureVideoDataOutput`** (+ `AVCaptureAudioDataOutput`) alimenta o caminho de gravação **e** o ring buffer de replay, no mesmo `captureOutput(_:didOutput:from:)`. **Não** há `AVCaptureMovieFileOutput` no caminho de vídeo, e **não** há um segundo output só para o replay.

**Buffer encoded, não raw.** O ring buffer mantém vídeo **já encodado**, não array de `CMSampleBuffer` crus. Duas estratégias idiomáticas 2026 (decisão final na implementação / refresh do plano, ambas válidas):

- **(A) Fragmented MP4 em memória** — `AVAssetWriter(contentType: .mp4)` com `preferredOutputSegmentInterval` ~1-2s + `AVAssetWriterDelegate.didOutputSegmentData` entregando `Data` por segmento. Mantém uma **deque circular de segmentos** (cada segmento já inicia em keyframe → concat trivial, sem corromper GOP). Ao "Salvar replay", concatena os segmentos da janela. **Preferida** — concat seguro, footprint baixo.
- **(B) Ring de `CMSampleBuffer` retidos** (`CFRetain` dos últimos N segundos) drenado para um `AVAssetWriter` com `startSession(atSourceTime:)` ancorado no PTS do primeiro buffer. Mais simples conceitualmente, mas retém buffers (custo de memória maior) — usar só se (A) se mostrar complexa.

**Descartado explicitamente:** "2 `AVAssetWriter` rotativos + concat de arquivos finalizados" (frágil — keyframe boundaries, PTS reset, áudio sync no corte); `AVCaptureMultiCamSession` (overkill single-cam, não permite MovieFileOutput em paralelo); reter `CMSampleBuffer` crus + `CVPixelBufferPool` no passthrough captura→writer (anti-idiomático — anexar o `CMSampleBuffer` direto via `append(sampleBuffer:)` é o certo; `CVPixelBufferPool` só se houver render/overlay).

**Checklist técnico obrigatório:**
- `expectsMediaDataInRealTime = true` nos `AVAssetWriterInput`.
- **Dispatch queue dedicada** para o delegate do `VideoDataOutput` (NÃO a `sessionQueue` serial — competiria com `focusAtAsync`, regredindo tap-to-focus, gate §10).
- `startSession(atSourceTime:)` ancorado no PTS do primeiro `CMSampleBuffer`; reancorar na rotação/`setFormat`/lens switch físico.
- **Áudio:** `AVCaptureAudioDataOutput` → `AVAssetWriterInput` de áudio no mesmo writer (replay com som; cuidar do priming AAC ~48ms + sync de PTS). Sem isso, replay sai mudo (mesma classe do bug de gravação na S2.A).
- `finishWriting(completionHandler:)` é **assíncrono** → path entregue por callback `@FlutterApi` `onReplaySaved`, nunca retorno síncrono.
- `setFormat` (troca de resolução/fps) e lens switch **físico** recriam/reancoram o writer (mudam dimensões dos sample buffers); tratados como evento que limpa o buffer de replay.
- Container final: **`.mp4` real** (`AVFileType.mp4`), coerente com o ADR-0020.

### Estimativa de RAM revisada (iPhone 12 — A14, 4GB, jetsam ~2GB hard)

A tabela original assumia frames **crus** (anti-padrão). Com buffer **encoded** (H.264/HEVC), o footprint é ~4× menor:

| Janela | Encoded (real, ~) | Raw (anti-padrão, NÃO usar) |
|---|---|---|
| 30s @ 1080p30 | ~30–37 MB | ~140–150 MB |
| 30s @ 4K | ~170 MB | ~560 MB |

**Gate de hardware:** monitorar `ProcessInfo.thermalState`; sob `.serious`/`.critical`, degradar (baixar fps/resolução do buffer) ou suspender o replay. Limitar a janela a N segundos. O dimensionamento exato é validado em **iPhone 12 físico** (não Simulator), via harness E2E (ADR-0016).

### Consequências adicionais (sobre as originais)

- A gravação contínua (G1) compartilha o mesmo writer/output — qualquer mudança no replay re-valida a gravação em device.
- O preview ao vivo compartilha o **mesmo** objeto `AVCaptureSession` (`previewLayer.session`); reconfigurar a sessão para o replay re-valida o preview (memória `raro-pattern-ios-platformview-camera-preview-black`).
- Android replay permanece backlog Sprint 3; nada da revisão iOS o altera.

### Referências do addendum

- ADR-0020 (pipeline unificado): [0020-unified-capture-pipeline-videodataoutput.md](0020-unified-capture-pipeline-videodataoutput.md)
- Apple docs: `AVAssetWriter`, `AVAssetWriterDelegate.assetWriter(_:didOutputSegmentData:segmentType:)`, `preferredOutputSegmentInterval`, `startSession(atSourceTime:)`, `AVCaptureVideoDataOutput`, `AVCaptureAudioDataOutput`
- Apple Developer Forums: thread/14323, thread/679250, thread/73800, thread/688973 (jetsam iPhone)
- React Native Vision Camera (prova de existência): github.com/mrousavy/react-native-vision-camera
- Memórias: `raro-pattern-ios-cvpixelbufferpool`, `raro-pattern-ios-avcapture-multicam-not-needed`, `raro-pattern-ios-platformview-camera-preview-black`, `raro-pattern-flutter-async-native-state-needs-notifier`, `raro-pattern-android-mediacodec-buffer-management`

---

## Addendum 2026-06-05 — Estratégia iOS revisada: chunked disk-ring (`.mp4` progressivo)

- **Status:** Accepted — **substitui a estratégia "(A) Fragmented MP4 em memória" do Addendum 2026-06-04 como caminho PREFERIDO.** A decisão estratégica do ADR (replay 100% nativo, sem plugin, buffer encoded dos últimos 15s/30s, save assíncrono) permanece intacta; muda só a forma de manter o buffer encoded no iOS.
- **Decisores:** Eduardo Rodrigues
- **Contexto:** S2.B (sessão de implementação do replay). Pesquisa de fonte primária durante o design (Apple docs do modo segmento do `AVAssetWriter`; artigo "Delaying camera feed with AVFoundation"; código da React Native Vision Camera; padrão `RPScreenRecorder.startClipBuffering` do ReplayKit, WWDC21) expôs dois gaps na estratégia A.

### Por que (A) Fragmented MP4 foi rebaixada

1. **Artefato divergente.** O modo segmento do `AVAssetWriter` exige `outputFileTypeProfile = .mpeg4AppleHLS` e produz **fragmented MP4** (init segment + media segments `.m4s`), **não** um `.mp4` progressivo. Isso diverge do artefato `.mp4` progressivo que a gravação contínua (S2.A/B0) já produz e que o ADR-0020 fixou (ponto 2: "Container `.mp4` real"). Galeria, preview (`video_player`), share sheet e o `ffprobe` do gate §10/ADR-0021 tratam fMP4 de forma menos uniforme; a janela fica granular ao segmento.
2. **Granularidade e dois writers ativos.** A estratégia A roda um segundo `AVAssetWriter` em modo HLS continuamente, em paralelo ao de gravação — mais estado, mais energia contínua, e formato de saída diferente do resto do app.

A estratégia "(B) ring de `CMSampleBuffer` retidos" também é rejeitada como caminho principal: a `AVCaptureVideoDataOutput` entrega frames **descomprimidos** (`CVPixelBuffer`, ex. `yuv-420`); reter N segundos disso estoura RAM e pressiona o pool de `IOSurface` da connection (anti-padrão `raro-pattern-ios-cvpixelbufferpool`), podendo degradar a entrega de frames da gravação G1.

### Decisão revisada: chunked disk-ring de `.mp4` progressivos

> **Revoga o "Descartado explicitamente: '2 `AVAssetWriter` rotativos + concat de arquivos finalizados'" do Addendum 2026-06-04.** A fonte primária nova mostra que esse é, na prática, o padrão idiomático ("disk-based circular queue of encoded video chunks") e que os 3 riscos que motivaram o descarte são mitigáveis por construção (abaixo).

- **`ReplayBuffer.swift`** mantém uma **deque circular de chunks `.mp4` progressivos** já encodados, escritos em `temporaryDirectory`. Cada chunk é produzido por um `AVAssetWriter(fileType: .mp4)` curto (`chunkDuration` ≈ 1s). Ao fechar um chunk, abre o próximo e **deleta o chunk mais antigo** que cai fora da janela. Teto fixo `K = ceil(N / chunkDuration) + 1` (folga de 1 chunk para cobrir a janela inteira).
- **Vídeo E áudio** em cada chunk (`AVAssetWriterInput` de vídeo + áudio, `expectsMediaDataInRealTime = true`), alimentados pelo **mesmo `captureOutput`** do pipeline unificado (ADR-0020) via **fan-out**: o `CMSampleBuffer` da `AVCaptureVideoDataOutput`/`AudioDataOutput` vai para (a) o writer de gravação on-demand [já existe] e (b) `replayBuffer.append(...)`. Append do mesmo `CMSampleBuffer` em dois inputs distintos é seguro porque RARO faz passthrough puro (nenhum writer modifica o buffer; cada input retém/libera o seu — Apple `AVAssetWriterInput.append(_:)`).
- **`saveReplay()`** concatena os chunks da janela via **`AVMutableComposition`** (`insertTimeRange` nas tracks de vídeo e áudio, em ordem) exportado por **`AVAssetExportSession` com `AVAssetExportPresetPassthrough`** → `.mp4` progressivo final em `temporaryDirectory`. **Passthrough não re-encoda** → preserva dimensões/fps/codec dos chunks (evita o fallback silencioso de formato que o gate §10/ADR-0021 existe para pegar). Finalização **assíncrona** → path entregue por `onReplaySaved(path, durationMs)`, nunca síncrono.

### Por que os 3 riscos antes "descartados" ficam mitigados

| Risco do descarte 2026-06-04 | Mitigação na chunked disk-ring |
|---|---|
| **keyframe boundaries** (concat corromper GOP) | Cada chunk inicia em keyframe **por construção** (`AVAssetWriter` novo = novo GOP/IDR). A fronteira de concat é sempre keyframe-aligned. |
| **PTS reset** | A concatenação é por `AVMutableComposition.insertTimeRange` (a composition recompõe o timeline), **não** corte/append cru de GOP. PTS é resolvido pela composition. |
| **áudio sync no corte** | O boundary de chunk é um ponto de sync limpo (chunk fechado tem vídeo+áudio coerentes); a composition insere as duas tracks em paralelo preservando duração. |

### Footprint revisado (substitui a tabela de RAM do Addendum 2026-06-04)

A tabela "Encoded em memória ~30-37MB/30s@1080p" do Addendum 2026-06-04 **não se aplica** a esta estratégia: o buffer **não fica em RAM**, fica em **disco** (encoda direto). O custo passa a ser:

| Recurso | Custo |
|---|---|
| RAM | Apenas os paths dos chunks + buffers em trânsito do `AVAssetWriter` (mínimo). Sem retenção de frames. |
| Disco | ~30-37MB rotativos para 30s@1080p (teto `K` chunks); deque deleta o mais antigo. Não acumula (≠ "stream 24/7" da opção 3 original). |
| I/O | Escrita sequencial contínua enquanto habilitado; fechar/abrir/deletar chunk fora do append crítico, na `outputQueue` serial (não na `sessionQueue` de focus — gate §10). |

**Gate de hardware mantido:** `ProcessInfo.thermalState` — sob `.serious`/`.critical`, `enableReplayBuffer` recusa habilitar e emite `onReplayFailed`. Validado em iPhone 12 físico (não Simulator).

### Contrato Pigeon final (substitui os stubs `replayBufferPing`/`replayBufferReady`)

Canal dedicado `com.rarocamera/replay_buffer` em `apps/mobile/pigeons/replay_buffer_api.dart` (NÃO no `camera_api.dart`):

```
@HostApi    ReplayBufferHostApi:
  void enableReplayBuffer(int seconds)   // 15 ou 30 — BufferDuration.value de raro_shared
  void disableReplayBuffer()
  void saveReplay()                       // path entregue ASSÍNCRONO via onReplaySaved

@FlutterApi ReplayBufferFlutterApi:
  void onReplaySaved(String path, int durationMs)
  void onReplayFailed(String code, String? message)  // nome simbólico, nunca rawValue (hook block-pigeon-error-rawvalue)
```

A forma do contrato já estava antecipada por este ADR (linha 78: callback `onReplaySaved` assíncrono) e pelo ADR-0020 (ponto 7); esta seção apenas a materializa. **Não** requer ADR próprio (Simplicity First).

### Coexistência e re-validação (reforço das Consequências originais)

- `setFormat` (resolução/fps) e lens switch **físico** (4K60 ↔ virtual) mudam as dimensões dos `CMSampleBuffer` → chamam `replayBuffer.reset()` (limpa a deque e reabre o chunk com as novas dimensões). Tratados como evento que zera o buffer de replay.
- Replay e gravação G1 compartilham o output unificado (ADR-0020) → qualquer mudança no replay **re-valida a gravação contínua em iPhone 12 físico** (XCTest/Simulator não basta — gate §10 + memória `feedback_device_debug_use_real_logs_not_assumptions`).
- O `.mp4` de replay salvo é puxado do vault (`devicectl copy from appDataContainer`) e validado por **`ffprobe`** (dimensões/fps/codec reais), conforme o gate §10/ADR-0021 — o `saveReplay` é "caminho que decide formato gravado".

### Referências do addendum 2026-06-05

- Apple docs: `AVMutableComposition.insertTimeRange`, `AVAssetExportSession` (`AVAssetExportPresetPassthrough`), `AVAssetWriterInput.append(_:)`, `AVCaptureVideoDataOutput` (frames descomprimidos), `ProcessInfo.thermalState`
- Artigo "Delaying camera feed with AVFoundation Framework" (Emanuel Luayza, Medium) — disk-based circular queue of encoded chunks
- ReplayKit `RPScreenRecorder.startClipBuffering` (WWDC21 "Discover rolling clips with ReplayKit") — rolling buffer descarta samples > N segundos
- IMG.LY / Scott Logic — concat de `.mp4` via `AVMutableComposition` + `AVAssetExportSession`
- ADR-0020 (pipeline unificado), ADR-0021 (4K60 / gate §10 prova de formato)
- Veredito adr-guardian (S2.B design): `ADR_AMEND_REQUIRED 0003` — este Addendum atende

---

## Addendum 2026-06-06 — Gate térmico: bloquear só em `.critical`, não em `.serious`

- **Status:** Accepted — retifica o gate térmico do Addendum 2026-06-05 (linha "sob `.serious`/`.critical`, recusa habilitar e emite `onReplayFailed`").
- **Contexto:** Gate de device da S2.B (sessão de implementação). Bug device-validated: o replay emitia `thermalThrottled` ("Replay pausado: o aparelho está aquecido") **a cada cold-start da sessão** (reabrir app, voltar de Settings — ambos recriam a `CameraController` autoDispose → `startSession` nativo → `replayBuffer.start()`), com o iPhone 12 **frio**. Pelo pill na câmera não dava erro porque o pill só chama `setWindow` (não recria a sessão, não re-executa o gate).
- **Causa-raiz:** o gate tratava `.serious` como bloqueio. No iPhone 12 (A14), `.serious` é um estado **comum e transitório** sob câmera + carga moderada (e o build profile de ~19min imediatamente anterior deixou o device sob gestão térmica ativa — confirmado no `idevicesyslog`: `thermalmonitord`/`ApplePPMCPMS` ajustando "Thermal Budget" continuamente). `.serious` **não é perigo** — a recomendação Apple para `.serious` é *degradar carga*, e só `.critical` justifica *pausar + avisar o usuário*. Bloquear o replay inteiro + erro alarmante em `.serious` é agressivo e mostra um susto falso a cada abertura.
- **Decisão:** O gate térmico do `ReplayBuffer.start()` bloqueia **apenas em `.critical`**. Em `.serious`, `.fair`, `.nominal` o buffer roda normalmente. (Degradar fps/resolução do buffer sob `.serious` — o ideal do Addendum 2026-06-05 — fica como melhoria futura, NÃO bloqueante; a janela de N segundos já limita o footprint.) Mantém `onReplayFailed(thermalThrottled)` só para `.critical` (perigo real).
- **Consequências:**
  - Remove o erro falso recorrente a cada cold-start no device frio/morno.
  - `.critical` (raro, perigo real) ainda suspende o replay + avisa — comportamento correto preservado.
  - Re-validar em iPhone 12: cold-start (reabrir app + voltar de Settings) NÃO mostra mais o erro térmico com o device em uso normal.
- **Referências:** Apple `ProcessInfo.ThermalState` (`.serious` = reduzir carga; `.critical` = pausar/avisar); WWDC19 422 "Designing for Adverse Network and Temperature Conditions"; gate de device S2.B (este bug).

---

## Addendum 2026-06-07 — Pré-roll embutido no REC (`includeReplayPreroll`, modo não-default)

- **Status:** Accepted — adiciona um **modo de export combinado** que reusa toda a mecânica do replay (chunked disk-ring + composition + export passthrough das Addenda 2026-06-05/06). Não altera a mecânica existente do `saveReplay()` isolado; adiciona um caminho paralelo atrás de uma flag default-`false`.
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Fatia seguinte da S2.B (sessão de implementação do gatilho de produto). A mecânica do buffer fechou (validada no iPhone 12), mas nenhum gatilho de UI consome o replay — o pill só troca a janela. Esta cláusula liga o primeiro gatilho real: **apertar REC embute os últimos N segundos do buffer no início do arquivo gravado**, copiando a mecânica do concorrente "Ok Câmera" (memória `raro-competitor-okcamera-replay-model`) e consertando o feedback silencioso que o tornou confuso. Decisão de produto travada pelo dono; estratégia técnica validada por websearch (modelo dashcam/GoPro HindSight de pré-buffer) + Context7 + o dump ADB real do concorrente, **não** por memória de treino.

### Decisão

Um novo modo de gravação combina o pré-roll do buffer de replay com o clipe de gravação contínua (G1) num **único `.mp4` progressivo**, atrás da flag `RecordingOptions.includeReplayPreroll` (**default `false`** — Simplicity First; o caminho de gravação puro não muda quando a flag está desligada).

**Semântica do pré-roll = N segundos ANTES do trigger (modelo de pré-buffer da indústria), sequencial com a gravação — sem overlap.**

> **Correção da estratégia que a memória `raro-preroll-rec-design-s2c` registrou.** O desenho inicial dizia "snapshot dos chunks no STOP + append da G1". Ao cruzar com o código real, isso produz **trecho duplicado**: o fan-out (`RecordingPipeline.swift:205`) alimenta o ring **e** o writer da G1 com os mesmos `CMSampleBuffer` durante a gravação, então `windowChunks()` no STOP cobre os últimos N s *antes do stop* — que já estão dentro da G1. Websearch (DashCamTalk, GoPro HindSight, "Video Buffer" iOS) confirma a semântica canônica de pré-buffer: *"the camera records all the time but does not write to memory; if something happens it releases what it has buffered (up to ~N seconds before the event) and continues to record."* Pré-roll = pré-trigger; gravação = pós-trigger; **concatenados em sequência, não sobrepostos.**

**Fluxo correto:**

1. **REC tap (trigger):** `recordingPipeline.start()` (G1 grava, igual hoje) **+** o `CameraManager` captura **AGORA** `replayBuffer.snapshotChunks()` (cópia thread-safe dos paths dos chunks da janela atual = os N s *antes* do REC) e **pausa o append do ring** durante a gravação. Pausar (não continuar enchendo) é deliberado: a G1 já cobre o tempo gravado, manter o ring rodando só duplicaria footage e gastaria disco/energia — coerente com o concorrente (embute o pré-roll e segue gravando um stream só) e com o "não dreno escondido" da memória de design.
2. **STOP:** a G1 finaliza `raro_<id>.mp4` (assíncrono, via `finishWriting`); o `CameraManager` espera os chunks do snapshot **e** a G1 finalizarem, então — se `includeReplayPreroll` — compõe `[snapshot chunks..., G1]` via o `export()` já existente do `ReplayBuffer` (`AVMutableComposition.insertTimeRange` com cursor + `AVAssetExportSession` passthrough), produzindo o `.mp4` único. O append do ring volta a rodar. `onRecordingFinished` emite o path do arquivo **combinado**.
3. **Sem `includeReplayPreroll`:** nada disso roda; `onRecordingFinished` emite o G1 puro (comportamento atual intacto).

### Coordenação no `CameraManager` (não no `RecordingPipeline`)

A composição vive no `CameraManager.swift`, onde `recordingPipeline` e `replayBuffer` coexistem (são independentes; a única ponte é `replayConsumer`). O `RecordingPipeline` device-validated da G1 **não** ganha referência ao replay — fica cirúrgico (Surgical Changes). Reusa-se:
- `ReplayBuffer.snapshotChunks() -> [Chunk]` (novo) — `queue.sync`, finaliza o chunk corrente p/ não perder o frame mais recente, copia os paths da janela, **não** esvazia o ring (o snapshot é uma cópia; o ring é pausado à parte). Pausa via flag interna que faz `append(_:)` virar no-op até `resumeAppending()`.
- `ReplayBuffer.export(chunks:)` (já existe, `ReplayBuffer.swift:246`) — aceita `[Chunk]`; o chunk da G1 entra como um `Chunk(url: g1URL, durationMs:)` ao fim da lista.

### Formato divergente = descarta o pré-roll (coerente ADR-0021)

Trocar resolução/fps/lente física durante o estado "armado" muda as dimensões dos `CMSampleBuffer` → os chunks do snapshot ficam incompatíveis com a G1 na composition. A mitigação **já existe**: `setFormat` e `switchLens` físico chamam `replayBuffer.reset()` (`CameraManager.swift:469`/`402`), e `setFormat` é bloqueado durante a gravação (`CameraManager.swift:409`). **Decisão de produto:** se o snapshot ficar vazio/incompatível no STOP, o export combinado é abortado e o `onRecordingFinished` entrega a **G1 pura** (degradação graciosa, nunca arquivo corrompido). Coerente com ADR-0021 (UI nunca entrega o impossível; falhar para o caminho honesto, não para o silencioso).

### Contrato (toca Pigeon — por isso este addendum vem ANTES do codegen)

- `apps/mobile/pigeons/camera_api.dart` — `RecordingOptions` ganha `bool includeReplayPreroll` (default `false` no construtor Dart). Tocar `RecordingOptions` dispara o hook `warn-adr-drift` (cobre `pigeons/`) → este addendum é o ADR que o satisfaz.
- `CameraFlutterApi` ganha `onRecordingStarted(String sessionId)` — **fix do bug catalogado** `raro-pattern-flutter-async-native-state-needs-notifier`: hoje `RecordingController.start` promove `RecordingActive` no retorno do `await` (estado otimista, pode dessincronizar do nativo). Com o callback, o nativo emite quando o writer **de fato** começou e o controller promove o estado por ele. É mudança de natureza separada do pré-roll, mas compartilha o mesmo codegen (Simplicity First — um regen, não dois).

### Gate §10 (obrigatório — pré-roll é "caminho que decide formato gravado")

`ffprobe` no `.mp4` **combinado** puxado do vault (`devicectl copy from appDataContainer`) provando **dimensões + fps reais do REC** (não do buffer) — o passthrough não re-encoda, então o combinado tem que bater com o format da G1. Validar também no device: emenda sem glitch no 1º frame da junção + áudio sincronizado na junção (priming AAC ~48ms, Addendum 2026-06-04). XCTest/Simulator não basta (memória `feedback_device_debug_use_real_logs_not_assumptions`).

### Referências do addendum 2026-06-07

- Websearch (semântica de pré-buffer da indústria): DashCamTalk (pre-buffering "releases what it has buffered up to ~N s before the event, continues recording"); GoPro HERO9 HindSight (pre-record automático); "Video Buffer Cam" (App Store, buffer retroativo iOS); confirma pré-roll = pré-trigger sequencial, não overlap.
- Modelo do concorrente: memória `raro-competitor-okcamera-replay-model` (dump ADB real — "grava 15/30s antes do comando/botão", embutido implícito sem feedback).
- Desenho da fatia (corrigido por este addendum): memória `raro-preroll-rec-design-s2c`.
- Mecânica reusada: Addendum 2026-06-05 (chunked disk-ring + composition + export passthrough), `ReplayBuffer.swift:246` (`export(chunks:)`).
- ADR-0020 (pipeline unificado), ADR-0021 (4K60 / gate §10 prova de formato), ADR-0013 (Pigeon `errorClassName` por contrato).
