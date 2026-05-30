# 0009 — Sprint 1 Task B (workflow refactor)

- **Data:** 2026-05-29
- **Duração:** ~1h
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `8292ded`, `8442dea`

## Objetivo

Executar a Sprint 1 Task B (seção "1 — Sessão de execução" de `SPRINT-1-PROMPTS.md`): simplificar `CLAUDE.md` §6, cortar `CLAUDE.md` §11 por critério objetivo, reescrever `Blueprint.md` §11 como roadmap 3-Sprint, e criar o session log retroativo `0007` (Sprint-0). Docs-only — nenhum código de produção tocado.

## Contexto inicial

- Branch `feat/camera-native-bridge` em `500b496` (close da sessão 0008), working tree limpa, +7 commits unpushed.
- Plano `sprint-1-foundation-walking-skeleton.md` escrito antes da sessão 0008 existir → Task B continha referências stale.
- §11 do CLAUDE.md tinha **29** anti-patterns (plano dizia 23).

## O que foi feito

- **Mini-audit (5 holes mecânicos no plano) + fix (`8292ded`)** — `docs(docs): sprint 1 task b md fixes`:
  - §11 são 29 (não 23) anti-patterns; alvo do corte 29 → 11.
  - Linha 0007 entra **abaixo** de 0008 no INDEX (Sprint 0 antecede Task A), não no topo.
  - Lista de commits do 0007 corrigida pros 4 reais (`06ec0fb`..`1160c9f`).
  - Scope `refactor(workflow)` → `docs(harness)` (`workflow` ∉ scope-enum).
- **B1 — CLAUDE.md §6 (`8442dea`):** substituído pela versão "1 sessão = 1 entregável fechado" (4 regras não-negociáveis) + refs aos Sprint MDs. Removida tabela auto-sizing. Exemplo de commit de close corrigido (`chore(session)` → `docs(docs)`).
- **B2 — CLAUDE.md §11 (`8442dea`):** cortado **29 → 11**. KEEP os broad/non-recuperáveis; DROP 18 hyper-específicos já cobertos por memória/hook. Criada a única memória faltante (`raro-pattern-pigeon-enum-rawvalue-boundary`) + indexada em MEMORY.md.
- **B3 — Blueprint §11 (`8442dea`):** roadmap 3-Sprint com checkbox por tela/feature, substituindo "Próximos passos após aprovação". Checkboxes de cleanup refletem estado real (Sprint 0 / Task A / Task B done; Task C + 12 telas pendentes). Footer de status alinhado.
- **B4 — session 0007 (`8442dea`):** criado log retroativo do Sprint-0 + linha no INDEX abaixo de 0008.

## O que NÃO foi feito (e por quê)

- **Push não feito** — +9 commits unpushed em `feat/camera-native-bridge`. Push é ação outward; aguarda pedido explícito.
- **Memória + MEMORY.md fora do commit do repo** — vivem em `~/.claude/projects/.../memory/` (fora do git do projeto). Criadas, mas não versionadas no repo.
- **`flutter analyze`/`flutter test` não rodados** — Task B é docs-only (0 arquivos `.dart`/`lib/`). O gate relevante (integridade de links/markdown) foi checado manualmente; analyze/test seriam ruído.
- **Task A "≤25 memórias" continua não atingido** — 33 mantidas com justificativa (sessão 0008). Refletido honestamente no checkbox do Blueprint §11 em vez de marcar uma meta falsa.

## Aprendizados / surpresas

- **Plano stale por antecedência:** B4 foi escrito antes do 0008 existir → assumia 0007 no topo e listava commits errados. Lição reforçada: planos referenciando numeração de sessão envelhecem; auditar contra `git log` real antes de executar.
- **Subject-case do commitlint pega maiúscula no meio:** `task B` falhou (`subject must be lower-case`); fix foi `task b`. Subjects com `§6`/`§11` passam (sem letras cased).
- **Desvios de qualidade vs. verbatim:** segui a estrutura do template, mas corrigi 3 coisas pra não propagar drift no manual autoritativo — exemplo de commit `chore(session)` inválido, checkboxes do Blueprint refletindo realidade, footer de status. G6 (docs aligned com estado real) exige isso.

## Próximos passos

- **Sprint 1 Task C — Camera merge.** Validação perceptual no iPhone 12 (tap-to-focus <50ms ring / <300ms settle após os 5 fixes da sessão 0006) → marcar spec `2026-05-28-camera-task-19-closure-design.md` Done → ADR-0015 addendum I → merge `feat/camera-native-bridge` → `develop`.
- No início da Task C: confirmar `flutter run` no iPhone 12 (resolver incerteza iOS 26 W2 com log real).

## Referências

- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1 — Sessão de execução"
- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` (Task B, audit fixes em `8292ded`)
- CLAUDE.md §6 + §11 (`8442dea`), Blueprint §11 (`8442dea`)
- Session log retroativo: `docs/sessions/0007-sprint0-reset-roadmap-workflow.md`
- Memória nova: `raro-pattern-pigeon-enum-rawvalue-boundary` (fora do repo)
