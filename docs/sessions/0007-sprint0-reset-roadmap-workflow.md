# 0007 — Sprint 0: reset estratégico (master plan v2 + 3 sprint MDs)

- **Data:** 2026-05-29
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `06ec0fb`, `0e17eb9`, `d319847`, `1160c9f` (4 commits, todos `docs(docs)`)

> **Nota de numeração (retroativa):** este log foi criado na **Sprint 1 Task B** (commit `docs(harness)` desta sessão), não na hora. O slot `0007` foi reservado pela sessão [0008](0008-sprint1-task-a-cleanup.md) (FASE 6 do Kickoff) porque cronologicamente o Sprint 0 antecede a Task A — mas a Task A foi logada primeiro (como `0008`). Por isso `0007` aparece **abaixo** de `0008` no INDEX.

## Objetivo

Substituir o modelo de "Fases v1" (bootstrap) por uma estratégia executável de **3 Sprints**, produzindo o master plan e os MDs detalhados que guiam o trabalho a partir de agora. Nenhum código de produção tocado — só planejamento.

## O que foi feito

- **Master plan v2** escrito em `~/.claude/plans/glimmering-dancing-pnueli.md` (fora do repo, plano de trabalho pessoal).
- **3 sprint MDs** criados em `docs/superpowers/plans/` (`06ec0fb`):
  - `sprint-1-foundation-walking-skeleton.md` (cleanup + 12 telas iOS navegáveis)
  - `sprint-2-backend-logic-ios.md` (backend/lógica real iOS)
  - `sprint-3-android-parity-testflight-client.md` (Android + TestFlight + cliente)
- **Prompts copy-paste por sprint** (`0e17eb9` → `d319847` → `1160c9f`): evoluídos de um arquivo único para kickoffs rigorosos self-contained, depois split em `SPRINT-1/2/3-PROMPTS.md` (um por sprint).

## Decisões

- **Estratégia 3-Sprint substitui Fases v1.** 1 sessão = 1 entregável fechado (vira regra não-negociável em CLAUDE.md §6, formalizado na Task B).
- **Cleanup com critério objetivo** (Furos 2 e 4 do master plan): memórias e CLAUDE.md §11 cortados por critério, não por achismo.
- **Riverpod 3 providers** (signature real, implementação mock) em vez de uma classe `MockData` (Furo 3) — Sprint 2 troca a implementação sem mexer na UI.
- **Free Apple ID até Sprint 3.** TestFlight + Apple Developer Program ($99/ano) só quando o cliente entrar (Sprint 3).
- **Xcode terminal-first (§13)** validado por research 2026.

## Entregáveis

- Master plan v2: `~/.claude/plans/glimmering-dancing-pnueli.md`
- 3 sprint MDs em `docs/superpowers/plans/`
- 3 arquivos de prompts: `SPRINT-1-PROMPTS.md`, `SPRINT-2-PROMPTS.md`, `SPRINT-3-PROMPTS.md`

## Próxima sessão

Sprint 1 Kickoff + Task A (cleanup) — logada como [0008](0008-sprint1-task-a-cleanup.md).

## Referências

- Plans: `docs/superpowers/plans/sprint-{1,2,3}-*.md`
- Prompts: `docs/superpowers/plans/SPRINT-{1,2,3}-PROMPTS.md`
- Master plan v2 (externo): `~/.claude/plans/glimmering-dancing-pnueli.md`
