# Sessions Index

> Append-only. Cada nova sessão adiciona uma linha. Mais recente no topo.

| # | Data | Título | Branch | Commits |
|---|---|---|---|---|
| [0001](0001-bootstrap.md) | 2026-05-25 | Bootstrap do projeto (Fases 1–5 + 3 sprints de fixes) | `develop` | `c40e55d` … `1c43be0` (33 commits) |

## Próxima sessão sugerida

- **0002** — Primeira feature: `feat/camera-native-bridge` (Roadmap prioridade 1). Workflow:
  1. `/new-spec camera-native-bridge`
  2. `superpowers:brainstorming` para preencher
  3. Avaliar sizing (provavelmente **Large** — novo native bridge + ADR de contrato)
  4. Se Large: `/new-plan camera-native-bridge` + `superpowers:writing-plans`
  5. Invocar `implementer` para Phase 0 pre-flight + atomic tasks
  6. `validator` ao final + `design-fidelity-checker` se tocar UI
