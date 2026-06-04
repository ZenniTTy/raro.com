# 0019 — Thumbnail estático de vídeo via AVAssetImageGenerator

- **Data:** 2026-06-04
- **Status:** Accepted
- **Extends:** ADR-0015 (bridge de câmera), ADR-0018 (artefato `.mov` de origem)
- **Reverte parcialmente:** decisão de design "thumbnail por gradiente HSL, sem PNG" (Sprint 1 / Blueprint §5 galeria / sessão 0013) — para vídeos reais do vault. O gradiente HSL permanece como **fallback** (ver Decisão item 5).
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sprint 2 S2.A — a galeria (P07) deve exibir o 1º frame real de cada vídeo do vault em vez do gradiente colorido. Toca o contrato Pigeon do bridge de câmera (`apps/mobile/pigeons/camera_api.dart`), mesmo gatilho de ADR que originou ADR-0018.

## Contexto

A galeria (P07) renderiza hoje cada célula como um gradiente HSL derivado de `VideoEntity.thumbnailHue` — decisão deliberada da Sprint 1 (Blueprint §5; sessão 0013 "thumbnails são gradientes HSL gerados, não PNGs"; plano S2.A "YAGNI on a thumbnail package... matches Sprint 1 design"). Isso vale tanto para os 6 vídeos mock quanto para os vídeos reais gravados na S2.A: mesmo um `.mov` real aparece como retângulo colorido porque ninguém extrai um frame dele.

Com a S2.A entregando gravação real (ADR-0018, `.mov` via `AVCaptureMovieFileOutput`), o gradiente deixa de fazer sentido para vídeos reais — o usuário espera ver uma prévia do que gravou, como em qualquer galeria (iOS Fotos, YouTube). Esta ADR registra a virada de produto e a estratégia técnica para gerar essa prévia.

Constraints do projeto:

- **Offline-ready, sem HTTP em runtime** (Blueprint). A geração precisa ser local.
- **Histórico de leak em `video_player`** (memória `raro-pattern-flutter-video-player-disposal`). Extrair frame montando um `VideoPlayerController` na árvore reabriria esse risco, ainda mais numa galeria com N capas → descartado.
- **Adicionar dependência ao `pubspec.yaml` exige ADR de dependência** (CLAUDE.md §3 + gate §10). A solução escolhida **não** adiciona dependência — usa AVFoundation, já presente.
- **Paridade Android é Sprint 3** (roadmap `sprint-3-android-parity-testflight-client.md`). iOS-only nesta ADR, Android como stub explícito.

## Opções consideradas

1. **Nativo próprio via Pigeon — `AVAssetImageGenerator`**
   - Prós: zero dependência nova; mesma família AVFoundation que ADR-0018 já usa para gravar; lê o container QuickTime `.mov` com codecs HEVC/H264 nativamente; `appliesPreferredTrackTransform` resolve orientação; código que o projeto já domina (RecordingPipeline.swift). Geração 1x no save → galeria lê imagem pronta, scroll fluido.
   - Contras: ~40 linhas de Swift + método Pigeon + teste a manter; Android fica como stub até Sprint 3.
2. **Dependência `fc_native_video_thumbnail: ^3.0.0`**
   - Prós: cross-platform de graça (iOS+Android); menos código nosso; usa o mesmo `AVAssetImageGenerator` por baixo no iOS.
   - Contras: adiciona dependência ao `pubspec.yaml` → ADR de dependência + pin de versão; lib com cadência rápida de major bumps (1.0→3.0 em ~10 semanas) e adoção modesta (41 likes); acoplamento a manutenção de terceiro para uma operação de ~40 linhas que já sabemos escrever.
3. **Extrair frame via `video_player` já presente**
   - Prós: zero dependência nova.
   - Contras: `VideoPlayerController` não tem API oficial de captura de frame; exigiria montar o widget na árvore + `RepaintBoundary.toImage()`, com timing frágil de render; reabre o anti-pattern de leak documentado, multiplicado por N capas na galeria. Gambiarra.
4. **Status quo (gradiente HSL para tudo)**
   - Prós: nenhum trabalho.
   - Contras: vídeo real do usuário aparece como retângulo colorido sem relação com o conteúdo.

## Decisão

**Opção 1 — `AVAssetImageGenerator` nativo via Pigeon, sem dependência nova.**

1. **Contrato Pigeon.** Novo método `@async` na `CameraHostApi`:
   ```dart
   @async
   String generateThumbnail(String videoPath);
   ```
   Retorna o caminho absoluto do `.jpg` gerado. É `@async` porque a extração de frame do `AVAsset` é assíncrona por natureza (carregamento de tracks + `copyCGImage`), análogo ao reconhecimento de ADR-0018 de que finalização de mídia não é síncrona. Em caso de falha, lança `PigeonError` com `CameraErrorCode` simbólico (sem `String(enum.rawValue)` — hook `block-pigeon-error-rawvalue.sh`).

2. **Momento da geração — no save.** A thumbnail é gerada **uma vez**, logo após o vídeo ser persistido no vault (no `recordingVaultSink`, após o `VaultService.save` do `.mov`), não sob demanda na galeria. A galeria lê apenas o `.jpg` pronto → abre instantâneo, scroll sem latência nem estado de loading por célula. Trade-off aceito: ~100–300ms extras no fluxo de finalização da gravação (já assíncrono, imperceptível).

3. **iOS — `AVAssetImageGenerator`.** Sobre o `.mov` produzido por ADR-0018:
   - `appliesPreferredTrackTransform = true` (respeita orientação/rotação gravada — frame não sai deitado).
   - `requestedTimeToleranceBefore/After = .zero` (frame exato no timestamp pedido).
   - Frame no timestamp `0s` (1ª imagem / capa).
   - `CGImage` → JPEG (qualidade 0.8) → salvo como `<id>.jpg` ao lado do `<id>.mov` no vault.
   - Erro de decode (ex: arquivo ainda não finalizado) → lança; nunca silencia (anti-pattern §11).

4. **Android — stub no-op explícito.** A implementação Kotlin de `generateThumbnail` retorna string vazia / lança `notImplemented` até Sprint 3 (paridade Android). Boundary registrado, igual ADR-0018 fez com replay buffer.

5. **Fallback gracioso na galeria.** `VideoEntity` ganha `thumbnailPath` (nullable). A célula da galeria mostra `Image.file(thumbnailPath)` quando o `.jpg` existe; **cai de volta no gradiente HSL** (`thumbnailHue`, já presente) quando não há thumbnail — cobrindo Android pré-Sprint 3 e qualquer vídeo sem `.jpg`. `thumbnailHue` é mantido em `RecordingMetadata` como fallback, não removido.

6. **Mocks removidos.** Os 6 `VideoEntity` mock de `videoListProvider` são removidos: a galeria passa a refletir só o vault real. Galeria vazia até a 1ª gravação (decisão de produto confirmada). Isso simplifica `videoList` para `vault.listAll()` direto, sem o branch `if (real.isNotEmpty) ... else _mockVideos()`.

## Consequências

- **Positivas:**
  - Zero dependência nova → sem ADR de dependência, sem pin a vigiar, sem manutenção de terceiro.
  - Mesmo motor AVFoundation de ADR-0018 → consistência e confiança no manejo de `.mov`/HEVC/H264.
  - Geração no save → galeria com scroll fluido, sem leak de `video_player` (1 `AVAssetImageGenerator` efêmero por vídeo, no save, não N controllers).
  - Fallback HSL preserva a galeria funcional em Android e em vídeos sem thumbnail.

- **Negativas / riscos conhecidos:**
  - **Android sem thumbnail real até Sprint 3** — cai no gradiente. Aceito (paridade Android é Sprint 3).
  - **`.jpg` órfão / `.jpg` faltante.** Se o vídeo existe mas o `.jpg` falhou ou foi deletado, a galeria cai no gradiente (não quebra). `VaultService.delete` deve remover o `.jpg` junto com `.mov` + `.json` (robustez de cleanup).
  - **Vídeos gravados ANTES desta mudança** não têm `.jpg` → caem no gradiente. Não há migração retroativa (aceito; baixo impacto, vault novo).
  - **JPEG não tem alpha** — irrelevante para capa de galeria (frame opaco).

- **Como reverter:** novo ADR substituindo, com revert do método Pigeon `generateThumbnail`, do `thumbnailPath` em `RecordingMetadata`/`VaultService`/`VideoEntity`, e do `Image.file` em `VideoThumbnail` (volta ao gradiente puro). A decisão de remover os mocks pode ser revertida independentemente restaurando `_mockVideos()`.

## Referências

- ADR-0015 (bridge de câmera, ADR-mãe): [0015-camera-native-bridge-strategy.md](0015-camera-native-bridge-strategy.md)
- ADR-0018 (artefato `.mov` de origem): [0018-recording-pipeline-mp4.md](0018-recording-pipeline-mp4.md)
- ADR-0013 (mecanismo Pigeon / anti-drift): [0013-pigeon-theme-tailor-and-anti-drift-gates.md](0013-pigeon-theme-tailor-and-anti-drift-gates.md)
- Apple docs: `AVAssetImageGenerator`, `appliesPreferredTrackTransform`, `copyCGImage(at:actualTime:)`
- Memória `raro-pattern-flutter-video-player-disposal` (por que não extrair frame via video_player)
- Memória `raro-pattern-pigeon-enum-rawvalue-boundary` (erro Pigeon sem `String(rawValue)`)
- Sessão 0013 / Blueprint §5 (decisão original de gradiente HSL, revertida aqui para vídeos reais)
