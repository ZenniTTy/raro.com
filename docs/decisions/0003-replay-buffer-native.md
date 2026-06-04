# 0003 — Replay Buffer 100% nativo (sem plugin Flutter)

- **Data:** 2026-05-25 (decisão original) · **Addendum de implementação:** 2026-06-04
- **Status:** Accepted — **seção de implementação iOS revisada em 2026-06-04** (ver Addendum). A decisão estratégica (replay 100% nativo, sem plugin) permanece; a implementação iOS original era tecnicamente inviável e foi corrigida.
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
