# Sessions Index

> Append-only. Cada nova sessão adiciona uma linha. Mais recente no topo.

| # | Data | Título | Branch | Commits |
|---|---|---|---|---|
| [0003](0003-flutter-3.44-spm-migration.md) | 2026-05-26 | flutter-3.44-spm-migration (upgrade SDK + SPM + iOS 15, ADR-0014) | `feat/flutter-3.44-spm-migration` | (commits a inserir) |
| [0002](0002-api-contract-shared.md) | 2026-05-26 | api-contract-shared (rm-2 spec bloqueante, 12 famílias) | `feat/api-contract-shared` | `2783166` … `f30bb1b` (16 commits) |
| [0001](0001-bootstrap.md) | 2026-05-25 | Bootstrap do projeto (Fases 1–5 + 3 sprints de fixes) | `develop` | `c40e55d` … `1c43be0` (33 commits) |

## Próxima sessão sugerida

- **0004** — Primeira feature: `feat/camera-native-bridge` (Roadmap prioridade 1). Workflow:
  1. `/new-spec camera-native-bridge`
  2. `superpowers:brainstorming` para preencher
  3. Avaliar sizing (provavelmente **Large** — novo native bridge + ADR de contrato)
  4. Se Large: `/new-plan camera-native-bridge` + `superpowers:writing-plans`
  5. Invocar `implementer` para Phase 0 pre-flight + atomic tasks
  6. `validator` ao final + `design-fidelity-checker` se tocar UI
