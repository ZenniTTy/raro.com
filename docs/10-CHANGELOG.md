# 10-CHANGELOG — RARO

> Append-only. Header `## [YYYY-MM-DD] — version` para cada entry. Versões seguem semver.

## [2026-05-25] — 0.1.0 (bootstrap)

### Adicionado

- Briefing imutável em `docs/briefing/original-briefing.md`
- Protótipo navegacional em `docs/briefing/prototype/Prototipo-RARO.html` + asset `raro-logo.png`
- Blueprint aprovado em `docs/Blueprint.md` com versões fixadas via Context7 + pub.dev
- Monorepo Bun + Turborepo + Biome
- `apps/mobile` Flutter 3.41 com Riverpod 3 codegen, go_router 17, RevenueCat 10, Firebase 4/12/5, alchemist + mocktail
- `packages/shared` Dart puro com constantes, enums, event names
- lefthook + commitlint (Conventional Commits, scope-enum derivado do Blueprint)
- `setup.sh` idempotente
- `AGENTS.md` + `CLAUDE.md` (manual autoritativo, 13 seções, Karpathy 4 princípios)
- `docs/01-PROJECT.md` até `09-DOD.md` (wiki base)

### Decidido

- Wake word `"Raro"` (não `"OkCamera"`)
- Free trial 30 dias
- Planos: Mensal R$ 9,90 + Anual R$ 89,90 com badge "MELHOR OFERTA"
- Native bridges custom (sem plugin `camera` oficial)
- Replay Buffer 100% nativo
- Client-only (sem backend próprio)
- Controle por botões de volume implementado; controle BT customizado fora
- Tradução em tempo real fora de escopo v1.0
- Onboarding Xiaomi híbrido (auto MIUI + manual em Settings)

### Adicionado (continuação)

- 13 ADRs em `docs/decisions/` (0000 template + 0001-0012)
- 1 session log: `docs/sessions/0001-bootstrap.md` + 0001-INDEX
- Harness completo em `.claude/`:
  - 7 subagents com `tools:` allowlist (implementer, validator,
    adr-guardian, researcher, flutter-test-author, flutter-perf-auditor,
    design-fidelity-checker)
  - 8 slash commands (commit, session-end, docs-lint, prime, new-spec,
    new-plan, verify-slice, ingest-source)
  - 7 hooks (block-env, block-secrets, format-dart, run-riverpod-codegen,
    warn-adr-drift, reinject-roadmap registrados em settings.json +
    verify-task como utilitário invocável manualmente)
  - `settings.json` com 30 entries em allow + 9 em deny + 6 hook entries
    em 3 eventos (PreToolUse, PostToolUse, SessionStart)
- Templates TLC Spec-Driven: `docs/superpowers/specs/0000-template.md`
  e `docs/superpowers/plans/0000-template.md`
- `CLAUDE.md` Seção 6 com workflow auto-sizing (quick/medium/large) +
  sinais que escalam fatia + primeira spec sugerida

### Corrigido (sprints retroativos)

- Sprint 2.7-fixes: 5 fixes pós-Fase 3 (trial 30d direto, hook
  dart-format sem cd quebrado, warning 14 packages explicado em ADR,
  smoke test com guards reais, README.md)
- Sprint 4.7-fixes: 5 fixes pós-Fase 4 (`$schema` URL inexistente
  removido, Stop event teatral removido, analyze-changed-dart
  redundante removido, warn-adr-drift sem blacklist hardcoded,
  setup.sh valida python3)

### Bootstrap status

**v0.1.0 bootstrap completo em 30 commits.** Próximo passo: criar
primeira spec via `/new-spec camera-native-bridge` (Roadmap prioridade 1).
