# 0006 — Conventional Commits + lefthook + commitlint

- **Data:** 2026-05-25
- **Status:** Accepted
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Blueprint Seção 8.3

## Contexto

Bootstrap multi-fase com vários µ-sprints precisa de histórico legível. Sem disciplina de commit, `git log` vira inútil em 2 meses.

## Decisão

- **Conventional Commits 1.0.0** com `<type>(<scope>): <description>`
- **scope-enum** em [commitlint.config.cjs](../../commitlint.config.cjs) derivado das features do Blueprint (camera, replay, voice, volume, lock, gallery, preview, subscription, paywall, checkout, settings, xiaomi, i18n, theme, bridge, analytics, shared, deps, ci, docs, blueprint, scaffold, harness, spec)
- **lefthook** com 3 hooks:
  - pre-commit (parallel): dart-format, biome format em json/md staged, block-secrets via regex
  - pre-push: `bun run lint && bun run test`
  - commit-msg: commitlint
- **Subject lowercase** obrigatório
- **Body** sem limite de linha
- **Nunca** `--no-verify`

## Consequências

- **Positivas:**
  - `git log --oneline` parseável
  - Changelog auto-geração possível no futuro
  - Bisect determinístico (1 commit = 1 mudança lógica)
- **Negativas:**
  - Mensagens em português com "Fase", "Configuração" são rejeitadas (subject-case lowercase) — exige mente atenta
  - Hook lefthook precisa estar instalado em cada clone (`bunx lefthook install` em `setup.sh`)
- **Como reverter:** rollback do `commitlint.config.cjs` e desativação dos hooks

## Referências

- https://www.conventionalcommits.org/
- [commitlint.config.cjs](../../commitlint.config.cjs)
- [lefthook.yml](../../lefthook.yml)
