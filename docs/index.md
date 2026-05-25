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

## Wiki numerada (01–10)

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

## Sessions (log append-only)

- [sessions/0000-template.md](sessions/0000-template.md) — template de session log
- [sessions/0001-INDEX.md](sessions/0001-INDEX.md) — índice de sessions (mais recente no topo)
- [sessions/0001-bootstrap.md](sessions/0001-bootstrap.md) — bootstrap do projeto (Fases 1–3)

## Specs e plans (Fase 5 Spec-Driven)

- superpowers/specs/ — specs por feature (escritos a partir da primeira feature)
- superpowers/plans/ — plans por feature
