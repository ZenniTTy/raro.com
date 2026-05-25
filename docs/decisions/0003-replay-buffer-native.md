# 0003 — Replay Buffer 100% nativo (sem plugin Flutter)

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues, Vitor Lopes
- **Contexto:** Briefing Seção 6.2 + 7.4, Blueprint Seção 2.2 + 3.3

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

- iOS: `AVCaptureSession` com `AVCaptureMovieFileOutput` segmentado. Buffer mantido como `CMSampleBuffer` em array circular. Salvamento via `AVAssetWriter` concatenando segmentos.
- Android: `CameraX VideoCapture` com `FileDescriptorOutputOptions`. Buffer em `MediaCodec` com encoding H.264, frames em `ByteBuffer` circular. Concat via `MediaMuxer`.

Estimativa de RAM:
- 15s em 1080p ≈ 70MB
- 30s em 1080p ≈ 140MB
- 15s em 4K ≈ 280MB
- 30s em 4K ≈ 560MB

Pool de buffers reutilizável para minimizar GC pressure.

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
