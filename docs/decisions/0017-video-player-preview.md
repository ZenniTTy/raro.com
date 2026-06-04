# 0017 — video_player para a tela Preview (P08)

- **Data:** 2026-06-02
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sprint 1 Task G (walking skeleton). A tela Preview (`AppScreen.p08Preview`, rota `/preview/:id`) exige reprodução de vídeo. `video_player` **não** estava no `apps/mobile/pubspec.yaml` nem na stack pinada do Blueprint §2. CLAUDE.md §3: "Atualizar dep = abrir ADR. Sem exceção."

## Contexto

O protótipo (P08) mostra um player com viewport de vídeo, botão play central, scrubber com timecodes e card de metadata (tamanho/duração/codec). O walking skeleton do Sprint 1 entrega a tela navegável com um clipe de teste bundlado; a leitura real do vault (`path_provider`) é Sprint 2.

Reproduzir vídeo em Flutter exige um plugin nativo. O plugin oficial do Flutter Team é `video_player` (texture-based, iOS AVPlayer / Android ExoPlayer). Alternativas (`chewie`, `better_player_plus`, `media_kit`) adicionam camadas de UI/recursos (HLS/DRM/playlists) que o escopo v1.0 não pede — o protótipo tem controles próprios (play central + scrubber + actions), então a UI é custom de qualquer forma.

## Opções consideradas

1. **`video_player` (oficial Flutter Team)**
   - Prós: mantido pelo Flutter Team, texture-based, API mínima (`asset`/`network`/`file`), `VideoProgressIndicator` com `allowScrubbing` nativo, sem deps transitivas pesadas. Migra direto pra leitura de arquivo do vault no Sprint 2 (`VideoPlayerController.file`).
   - Contras: sem UI pronta (precisamos compor controles) — mas o protótipo já define UI custom, então não é perda.
2. **`chewie` (wrapper de UI sobre video_player)**
   - Prós: controles prontos.
   - Contras: a UI dele não bate com o protótipo RARO; teríamos de sobrepor/desabilitar a UI dele. Dep a mais sem ganho.
3. **`media_kit` / `better_player_plus`**
   - Prós: HLS/DASH/DRM, playlists.
   - Contras: overkill — v1.0 toca arquivos locais MP4 H.264/H.265, sem streaming nem DRM. Deps transitivas e binários maiores.

## Decisão

**Adotar `video_player: ^2.11.1`** (latest em 2026-03-10, validado via pub.dev API + Context7 `/websites/pub_dev_video_player`). Requisito do plugin: Flutter `>=3.38.0` — compatível com nosso `>=3.44.0` (Blueprint §2.1, ADR-0014). Sem migration obrigatória pendente.

**Padrão de uso (best practice 2026, validado Context7 + Riverpod docs):**
- `VideoPlayerController.asset(...)` + `initialize()`; loading via `value.isInitialized`.
- Ciclo de vida via **provider Riverpod `autoDispose`** com `ref.onDispose(controller.dispose)` — em vez de dispose manual espalhado em `StatefulWidget`. Resolve idiomaticamente o histórico de leak do `video_player` (memória `raro-pattern-flutter-video-player-disposal`): `dispose()` rigoroso garantido pela destruição do provider quando a tela sai da árvore.
- Scrubber via `VideoProgressIndicator(controller, allowScrubbing: true, colors: ...)` (seek nativo por toque) OU barra custom com `seekTo` — a UI segue o protótipo.

**Asset de teste:** 1 clipe sintético `assets/sample_videos/sample_preview.mp4` (H.264 baseline, 720×1280 9:16, 3s, sem áudio, ~0.5MB, gerado localmente via ffmpeg). É walking-skeleton mock; Sprint 2 substitui por leitura do vault.

## Consequências

- **Positivas:**
  - Player oficial, texture-based, com caminho de migração direto pro Sprint 2 (`.file` lendo do vault).
  - Sem deps de UI redundantes (controles são custom conforme protótipo).
  - Padrão `autoDispose` + `ref.onDispose` elimina classe de bug de leak conhecida do projeto.
- **Negativas:**
  - 1 asset binário (~0.5MB) entra no repo (mock de teste; removível no Sprint 2).
  - `video_player` exige config nativa iOS (já coberta — sem entitlement extra para asset local).
- **Como reverter:** remover `video_player` do `pubspec.yaml` + o asset + a tela Preview real (volta ao stub). Nenhuma outra feature depende.

## Referências

- [Blueprint §2 — adendo 2.7.1 video_player](../Blueprint.md)
- [CLAUDE.md §3 — atualizar dep = abrir ADR](../../CLAUDE.md)
- [Sprint 1 plan §Task G](../superpowers/plans/sprint-1-foundation-walking-skeleton.md)
- pub.dev: `video_player` 2.11.1 (Flutter `>=3.38.0`, publicado 2026-03-10)
- Context7 `/websites/pub_dev_video_player` — `VideoPlayerController.asset`/`dispose`/`VideoProgressIndicator`
- Riverpod 3 docs — `autoDispose` + `ref.onDispose` lifecycle
- Memória `raro-pattern-flutter-video-player-disposal`
