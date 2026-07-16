# docs/index.md — mapa de documentação RARO

> Mapa parseável de toda a documentação do projeto. Sem este arquivo, é difícil encontrar coisas. Atualize a cada novo doc.

## Raiz

- [../AGENTS.md](../AGENTS.md) — thin redirect para agentes AI
- [../CLAUDE.md](../CLAUDE.md) — manual autoritativo para Claude Code

## Briefing (imutável)

- [briefing/original-briefing.md](briefing/original-briefing.md) — briefing original aprovado
- [briefing/prototype/Prototipo-RARO.html](briefing/prototype/Prototipo-RARO.html) — protótipo navegacional (fonte de verdade visual + funcional)
- [briefing/prototype/assets/raro-logo.png](briefing/prototype/assets/raro-logo.png) — logo oficial

## Blueprint (autoritativo)

- [Blueprint.md](Blueprint.md) — decisões arquiteturais aprovadas

## Wiki numerada (01–11)

- [01-PROJECT.md](01-PROJECT.md) — visão de produto e contexto
- [02-ARCHITECTURE.md](02-ARCHITECTURE.md) — topologia técnica de alto nível
- [03-CONVENTIONS.md](03-CONVENTIONS.md) — conversões de código e processo
- [04-ROADMAP.md](04-ROADMAP.md) — ordem sugerida de specs
- [05-FEATURES.md](05-FEATURES.md) — mapa funcional v1.0
- [06-SCREENS.md](06-SCREENS.md) — mapa de telas e modais
- [07-NATIVE-BRIDGES.md](07-NATIVE-BRIDGES.md) — contratos dos Method Channels
- [08-RELEASE.md](08-RELEASE.md) — processo de release nas lojas
- [09-DOD.md](09-DOD.md) — Definition of Done v1.0
- [10-CHANGELOG.md](10-CHANGELOG.md) — append-only log de versões
- [11-SYSTEM-DESIGN.md](11-SYSTEM-DESIGN.md) — desenho de sistema client-only (dados/vault, gargalos, evolução)

## Decisions (ADRs)

- [decisions/0000-template.md](decisions/0000-template.md) — template ADR
- [decisions/0001-stack-decisions.md](decisions/0001-stack-decisions.md) — stack tecnológica inicial fixada
- [decisions/0002-camera-native-bridge.md](decisions/0002-camera-native-bridge.md) — native bridge custom para câmera
- [decisions/0003-replay-buffer-native.md](decisions/0003-replay-buffer-native.md) — Replay Buffer 100% nativo
- [decisions/0004-client-only-architecture.md](decisions/0004-client-only-architecture.md) — arquitetura client-only
- [decisions/0005-state-management-riverpod3.md](decisions/0005-state-management-riverpod3.md) — Riverpod 3 com codegen
- [decisions/0006-commit-conventions.md](decisions/0006-commit-conventions.md) — Conventional Commits + lefthook + commitlint
- [decisions/0007-lock-mode-vs-battery-profile.md](decisions/0007-lock-mode-vs-battery-profile.md) — Lock mode em vez de perfis por fabricante
- [decisions/0008-scope-exclusions.md](decisions/0008-scope-exclusions.md) — itens fora de escopo v1.0
- [decisions/0009-wake-word-raro.md](decisions/0009-wake-word-raro.md) — wake word é "Raro"
- [decisions/0010-dual-subscription-plans.md](decisions/0010-dual-subscription-plans.md) — modelo dual mensal + anual
- [decisions/0011-volume-control-not-bluetooth.md](decisions/0011-volume-control-not-bluetooth.md) — controle por botões de volume
- [decisions/0012-xiaomi-onboarding-hybrid.md](decisions/0012-xiaomi-onboarding-hybrid.md) — onboarding Xiaomi híbrido
- ADRs continuam de **0013 a 0024** em [decisions/](decisions/) (camera bridge strategy, e2e harness, recording pipeline, 4k60, voz SFSpeech/ONNX/toggle único etc.) — a lista vai até 0024, não para em 0012.
- [decisions/0025-firebase-bootstrap-strategy.md](decisions/0025-firebase-bootstrap-strategy.md) — bootstrap Firebase (init eager + Crashlytics 3 handlers + pins gradle)
- [decisions/0026-system-design-client-only.md](decisions/0026-system-design-client-only.md) — system design client-only single-node; vault filesystem como store canônico

## Sessions (log append-only)

- [sessions/0000-template.md](sessions/0000-template.md) — template de session log
- [sessions/0001-INDEX.md](sessions/0001-INDEX.md) — fonte atualizada de sessions (mais recente no topo, sessões até 0029) — consultar este índice, não as referências congeladas abaixo
- [sessions/0001-bootstrap.md](sessions/0001-bootstrap.md) — bootstrap do projeto (Fases 1–5 + 3 sprints de fixes)

## Specs e plans (TLC Spec-Driven)

- [superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md](superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md) — **roadmap vigente até entrega** (6 blocos; supersede o DAG de 20 specs em 04-ROADMAP.md)
- [superpowers/specs/0000-template.md](superpowers/specs/0000-template.md) — template canônico de spec
- [superpowers/plans/0000-template.md](superpowers/plans/0000-template.md) — template canônico de plan com 7 execution rules + Phase 0 pre-flight + atomic tasks
- `superpowers/specs/<YYYY-MM-DD>-<slug>-design.md` — specs por feature (criadas via `/new-spec`)
- `superpowers/plans/<YYYY-MM-DD>-<slug>.md` — plans por feature (criados via `/new-plan`)

## Roadmap detalhado por bloco

- [04-ROADMAP-SPECS/README.md](04-ROADMAP-SPECS/README.md) — índice dos 5 arquivos, 20 specs, 100 µ-sprints
- [04-ROADMAP-SPECS/spec-001-api-contract-shared.md](04-ROADMAP-SPECS/spec-001-api-contract-shared.md) — spec bloqueante (api contract)
- [04-ROADMAP-SPECS/block-infra.md](04-ROADMAP-SPECS/block-infra.md) — firebase, revenuecat, theme, fontes (specs 002-005)
- [04-ROADMAP-SPECS/block-bridges.md](04-ROADMAP-SPECS/block-bridges.md) — camera, replay, voice (specs 007-009)
- [04-ROADMAP-SPECS/block-features.md](04-ROADMAP-SPECS/block-features.md) — volume, paywall, checkout, gallery, preview, lock (specs 010-016)
- [04-ROADMAP-SPECS/block-polish.md](04-ROADMAP-SPECS/block-polish.md) — splash, i18n, permissions, onboarding, xiaomi, settings (specs 006, 012, 017-020)

## Harness Claude Code (`.claude/`)

Não fica em `docs/`, mas é parte da documentação operacional. Referência:

- [../.claude/README.md](../.claude/README.md) — visão geral do harness
- [../.claude/settings.json](../.claude/settings.json) — permissions + hooks registrados
- [../.claude/slice-checklist.md](../.claude/slice-checklist.md) — gates contextuais antes de PR/merge
- `../.claude/agents/` — 7 subagents (implementer, validator, adr-guardian, researcher, flutter-test-author, flutter-perf-auditor, design-fidelity-checker)
- `../.claude/commands/` — 8 slash commands (`/commit`, `/session-end`, `/docs-lint`, `/prime`, `/new-spec`, `/new-plan`, `/verify-slice`, `/ingest-source`)
- `../.claude/hooks/` — 7 shell scripts (6 registrados em settings.json + `verify-task.sh` como utilitário manual)

Detalhes em [CLAUDE.md](../CLAUDE.md) Seções 7, 8, 9.
