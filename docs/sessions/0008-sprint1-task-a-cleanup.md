# 0008 — Sprint 1 Kickoff + Task A (cleanup)

- **Data:** 2026-05-29
- **Duração:** ~2h (audit FASE 1–4 + Task A)
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `7608c59`, `4f9085e`

> **Nota de numeração:** esta sessão é `0008` por decisão explícita do Kickoff Sprint 1 (FASE 6). O slot `0007` fica **reservado** para o log retroativo do Sprint-0 reset (master plan v2 + 3 sprint MDs, commits `06ec0fb`..`1160c9f`), a ser criado na Task B4 — cronologicamente o Sprint 0 antecede esta Task A.

## Objetivo

Executar a seção "1.0 — Kickoff" de `docs/superpowers/plans/SPRINT-1-PROMPTS.md` do começo ao fim, respeitando as 6 FASES: contextualização → audit mecânico → audit best-practices 2026 → consolidação + gate → execução Task A (cleanup) → closure.

## Contexto inicial

- Branch `feat/camera-native-bridge` em `1160c9f` (não `3b79021` como o MD descrevia — 4 commits Sprint-0 de docs landed depois, +4 unpushed).
- 33 memórias em `~/.claude/projects/.../memory/` + MEMORY.md (50 linhas). 6 memórias da sessão 0006 com prefixo `raro_mem_` → links quebrados no índice.
- CLAUDE.md §8 listava 6 hooks de evento; `.claude/hooks/` tem 9 `.sh` e `settings.json` registra 8 (faltavam `block-forbidden-terms` + `block-pigeon-error-rawvalue` na doc).

## O que foi feito

- **FASE 1–3 (audit):** `/prime` + leitura completa (Blueprint, CLAUDE.md, 3 sprint MDs, INDEX, session 0006). 2 agentes Explore em paralelo: audit mecânico (file paths, shell, placeholders, refs, cross-MD, goals) + audit best-practices 2026 (26 deps/APIs/padrões via Context7 + WebSearch). Todas as ~20 deps pinadas confirmadas CURRENT em maio 2026.
- **FASE 4 (gate):** consolidado em BLOQUEANTES/WARNINGS/INFORMATIVE. **Corrigi 2 afirmações erradas dos agentes** via verificação direta no disco (§8 NÃO tinha 9 hooks; A5 era necessária). Gate aprovado pelo usuário: "corrigir MD + Task A".
- **FASE 5a — MD audit fixes (`7608c59`):** 3 holes corrigidos em `sprint-1-foundation-walking-skeleton.md` — B1 (video_player ausente do pubspec/Blueprint §2 → pré-requisito ADR explícito na Task G1), B2 (G6/exit-state referenciavam CLAUDE.md §15 inexistente → roadmap vive no Blueprint §11), W3 (nota SharedPreferences.getInstance() legado em 2026).
- **FASE 5b–d — Task A (`4f9085e`):**
  - A1: backup íntegro em `memory-backup-2026-05-29/`.
  - A2: auditoria por critério objetivo de 33 memórias.
  - A3/A4: **6 memórias renomeadas** (removido prefixo `raro_mem_`) → consertou 6 links quebrados do MEMORY.md + wikilinks + refs do §11. Validação: 0 links quebrados.
  - A5: CLAUDE.md §8 atualizada de 6 → 8 hooks registrados (+ verify-task utilitário = 9), batendo com `settings.json`.
  - A6: commit `docs(harness)` (scope `cleanup` do MD não existe no commitlint-enum).

## O que NÃO foi feito (e por quê)

- **Deleção de memórias DELETE/MERGE não executada.** A lista de candidatos do MD super-deletava:
  - `raro-pattern-ios-avcapture-multicam-not-needed` **mantida** — deletar quebraria refs em 5 docs versionados (`04-ROADMAP.md`, `04-ROADMAP-SPECS/block-bridges.md`, spec camera-native-bridge); conteúdo já no ADR-0015. Usuário condicionou execução a "zero breaking change".
  - As 6 `raro_mem_*` **mantidas (não deletadas)** por decisão do usuário (gate: "memória é o home") — a Task B2 depende delas existindo para então cortar o §11. Deletá-las agora seria circular.
  - `cvpixelbufferpool`, `camerax-ultra-wide` etc. **mantidas** — load-bearing p/ Sprint 2/3; critério não justifica delete.
- **Contagem final: 33 memórias** (não ≤25). A3 permite "outro número justificado" — justificativa acima. A faxina real do §11 acontece na Task B2.
- **Branch não pushed.** +6 commits unpushed em `feat/camera-native-bridge` (4 do Sprint 0 + 2 desta sessão). Push é ação outward — aguarda pedido.

## Aprendizados / surpresas

- **Conflito de plano Task A ⇄ Task B2:** A manda deletar as 6 memórias "porque estão no §11"; B2 manda cortar o §11 "porque está em memória". Circular. Resolvido mantendo memória como home (decisão do usuário).
- **Links de memória quebrados silenciosamente:** os 6 arquivos `raro_mem_*` tinham filename divergente do `name:` no frontmatter e dos links do índice/wikilinks. Rename alinhou tudo.
- **Audit de agente precisa de verificação cruzada:** o agente FASE 2 afirmou "§8 já tem 9 hooks / A5 redundante" — falso. Verificação no disco mostrou §8 com 6, A5 necessária. Não confiar em conclusão de subagent sem checar o load-bearing.
- **iOS 26 JIT (W2):** claim de que iOS 26 bloqueia debug em device físico contradiz as sessões 0004–0006 (rodaram debug no iPhone 12 dias atrás). Tratar como incerteza a verificar no início da Task C, não como fato.
- **commitlint scope-enum não tem `cleanup` nem `session`** — Kickoff/skill propõem esses scopes mas falhariam. Usar `harness`/`docs`.

## Próximos passos

- **Sprint 1 Task B (workflow refactor)** — sessão dedicada. CLAUDE.md §6 simplify + §11 anti-patterns critério-cortada (aí sim, com as 6 memórias como destino) + Blueprint §11 roadmap 3-sprint (criar do zero — §11 atual é "Próximos passos após aprovação") + criar session **0007** (Sprint-0 reset retroativo) + atualizar INDEX "próxima sessão" (hoje aponta stale p/ "Sessão 2 — validação perceptual").
- **Antes da Task G:** abrir micro-ADR `0017-video-player-preview` (dep nova).
- **No início da Task C:** confirmar `flutter run` no iPhone 12 (resolver incerteza iOS 26 W2 com log real).

## Referências

- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` (audit fixes em `7608c59`)
- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1.0 — Kickoff"
- CLAUDE.md §8 (alinhada em `4f9085e`)
- ADR-0015 (multicam), ADR-0016 (E2E harness)
- Backup memórias: `~/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory-backup-2026-05-29/`
