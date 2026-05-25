# 0001 — Bootstrap do projeto (Fases 1–3)

- **Data:** 2026-05-25
- **Duração:** ~3h (incremental)
- **Participantes:** Eduardo Rodrigues (humano) + Claude Code (AI)
- **Branch:** `develop`
- **Commits:** `c40e55d` (initial) até `9703cc5` (claude.md) — ver `git log`

## Objetivo

Executar o skill `bootstrap-mobile-flutter` contra o briefing do projeto RARO (Raro Camera) para sair do "repo vazio com briefing" para "monorepo completo, documentado, com harness e workflow spec-driven configurado".

## Contexto inicial

- Repo `develop` com 1 arquivo: `original-briefing.md` (briefing imutável)
- Protótipo Claude Design disponível em URL interna Anthropic (`api.anthropic.com/v1/design/...`)
- Tentativas iniciais de fetch falharam (404, depois passou de 10MB do WebFetch)
- Resolução: Eduardo salvou `Prototipo RARO.html` (99KB) e `raro-logo.png` na root do repo manualmente

## O que foi feito

### Fase 1 — Blueprint (commit `da902f8`)

- Briefing movido para `docs/briefing/original-briefing.md` (imutável)
- Protótipo movido para `docs/briefing/prototype/Prototipo-RARO.html` + asset `raro-logo.png`
- Context7 + pub.dev consultados para fixar versões de 14 libs
- 6 divergências briefing × protótipo identificadas e resolvidas:
  1. Wake word: `"Raro"` (não OkCamera) — Eduardo + protótipo prevalecem
  2. Free trial: 30 dias (não 15) — Eduardo decidiu briefing prevalece
  3. Planos: ambos mensal + anual — protótipo prevalece
  4. Volume buttons: implementar — protótipo prevalece
  5. Tradução em tempo real: fora de escopo
  6. Onboarding Xiaomi: híbrido (auto MIUI + manual)
- Blueprint v1.0 escrito em `docs/Blueprint.md` com aprovação registrada

### Fase 2 — Scaffold (commits `fe07c7b` → `a2585c3`, 6 µ-sprints)

- 2.1 — `package.json` root, `bunfig.toml`, `.editorconfig`, `.gitignore`
- 2.2 — `apps/mobile` via `flutter create org=com.rarocamera`, pubspec com 14 deps fixadas, `analysis_options.yaml` strict, smoke test
- 2.3 — `packages/shared` Dart puro com `AppIdentity`, `VoiceConfig` (wakeWord='Raro'), `SubscriptionConfig` (freeTrialDays=30), 6 enums, 26 event names
- 2.4 — `turbo.json` + `biome.json` + `package.json` wrappers em workspaces
- 2.5 — `lefthook.yml` (pre-commit + pre-push + commit-msg) + `commitlint.config.cjs` com scope-enum
- 2.6 — `setup.sh` idempotente em 5 steps

### Fase 3 — Foundation (commits `9703cc5` em diante, 4 µ-sprints)

- 3.1 — `AGENTS.md` thin redirect + `CLAUDE.md` manual autoritativo de 13 seções com Karpathy 4 princípios
- 3.2 — `docs/01-PROJECT.md` até `10-CHANGELOG.md` + `docs/index.md`
- 3.3 — `docs/decisions/0000-template.md` + ADRs 0001 a 0012 derivados do Blueprint
- 3.4 — este arquivo + `0000-template.md` de sessions + `0001-INDEX.md` (a criar)

## O que NÃO foi feito (e por quê)

- **Fase 4 (Harness)** — subagents `.claude/agents/`, hooks `.claude/hooks/`, slash commands `.claude/commands/`, `.claude/settings.json`. Pausa entre fases para revisão.
- **Fase 5 (Spec-Driven)** — templates de spec + plan + primeira spec sugerida. Pausa entre fases.
- **Fontes TTF** — Space Grotesk / Inter / JetBrains Mono não baixadas. Serão adicionadas como spec na Fase 5.
- **Firebase config files** — `google-services.json` / `GoogleService-Info.plist` ausentes (serão criados pelo cliente em sua conta Firebase, não vão pro repo).
- **RevenueCat API keys** — fora do escopo do bootstrap, configurar via env vars na Fase 5.

## Aprendizados / surpresas

- **`flutter_lints ^7.0.0` foi alucinação minha.** Real era `^6.0.0`. Validei via `curl pub.dev/api/...` depois do erro do `flutter pub get`. Reforça: nunca pular o Context7/pub.dev gate.
- **`custom_lint 0.8.1` × `riverpod_lint 3.1.3` incompatíveis.** Riverpod adiantou pra analyzer 9, custom_lint ainda em analyzer 8. Solução: remover `custom_lint` explícito — `riverpod_lint 3.1.3` virou standalone com `analysis_server_plugin`. Importante registrar para devs futuros que tentem adicionar `custom_lint` "de volta".
- **`cd` no Bash tool não persiste entre chamadas.** Causou `apps/apps/mobile/` lixo quando criei o Flutter num `cd apps && flutter create mobile`. Lição: sempre caminhos absolutos.
- **Hook `block-secrets` me pegou** ao commitar o próprio `lefthook.yml` que usa palavras "api_key", "password" em regex. Refinei o pattern para casar atribuições com valor base64-like ≥16 chars.
- **`commitlint subject-case lowercase` me pegou** em `Fase 2 µ-sprint 2.5` (capital F). Não tirei a regra — confirmou que o gate funciona. Mensagens em português exigem atenção.
- **Endpoint Claude Design retorna bundle inteiro >10MB** independente de `?open_file=`. WebFetch tem teto de 10MB → impossível fetch do protótipo via tool. Solução foi Eduardo baixar e salvar localmente. Vale registrar como pattern para projetos futuros.

## Próximos passos

1. **Fase 4 — Harness** em 3-4 µ-sprints:
   - 4.1: subagents (`implementer`, `validator`, `adr-guardian`, `flutter-test-author`, `flutter-perf-auditor`, `design-fidelity-checker`, `researcher`)
   - 4.2: hooks (`block-env`, `block-secrets`, `format-dart`, `run-riverpod-codegen`, `analyze-changed-dart`, `warn-adr-drift`, `reinject-roadmap`, `verify-task`)
   - 4.3: slash commands (`/commit`, `/session-end`, `/docs-lint`, `/prime`, `/new-spec`, `/new-plan`, `/verify-slice`, `/ingest-source`)
   - 4.4: `.claude/settings.json` com hooks registrados
2. **Fase 5 — Spec-Driven**:
   - Templates `docs/superpowers/specs/0000-template.md` + `docs/superpowers/plans/0000-template.md`
   - Workflow auto-sizing documentado no CLAUDE.md
   - Sugestão de primeira spec: `feat/camera-native-bridge`
3. **Validação final** do bootstrap (checklist em [Blueprint Seção 10](../Blueprint.md))

## Referências

- [Blueprint.md](../Blueprint.md)
- [decisions/0001-stack-decisions.md](../decisions/0001-stack-decisions.md) até `0012`
- Commits: `git log --oneline` no branch `develop`
