# RARO

> Raro Camera — app mobile (iOS + Android) para captura profissional de vídeo com operação hands-free. Comando de voz (`"Raro"`), captura retroativa via Raro Replay, sem precisar tocar no aparelho.

**Status:** bootstrap em andamento (Fases 1–3 concluídas). Veja [docs/sessions/0001-bootstrap.md](docs/sessions/0001-bootstrap.md) para o ponto atual.

## Comece por aqui

1. Leia [AGENTS.md](AGENTS.md) — ponto de entrada universal (humanos e agentes AI).
2. Leia [CLAUDE.md](CLAUDE.md) — manual autoritativo.
3. Rode `./setup.sh` para preparar o ambiente local.

## Setup rápido

```bash
./setup.sh                        # bootstrap idempotente
bun run lint                      # turbo lint em todos workspaces
bun run test                      # turbo test
cd apps/mobile && flutter run     # rodar o app no simulador/emulador
```

Pré-requisitos: Bun ≥ 1.3.13, Flutter ≥ 3.41 (canal stable), Node ≥ 20.9, Python ≥ 3.9 (usado pelos hooks em `.claude/hooks/`), Docker, Git.

## Estrutura

```
raro/
├── apps/mobile/          # app Flutter (iOS + Android)
├── packages/shared/      # constantes, enums, event names (Dart puro)
└── docs/
    ├── Blueprint.md      # decisões arquiteturais aprovadas
    ├── briefing/         # briefing imutável + protótipo Claude Design
    ├── 01-PROJECT.md     # visão de produto
    ├── ...               # 02 a 10
    ├── decisions/        # 13 ADRs (0000-template + 0001-0012)
    └── sessions/         # log append-only de sessões de trabalho
```

## Convenções

- **Conventional Commits** com scope-enum em [commitlint.config.cjs](commitlint.config.cjs). Subject lowercase. Sem `--no-verify`.
- **Versões fixadas** via Context7 + pub.dev. Atualizar dep = abrir ADR.
- **Sem comentários em código de produção** (Karpathy Surgical Changes).
- **Wake word é `"Raro"`** (nunca `"OkCamera"`). Locked em `packages/shared` e validado por teste.

## Licença e propriedade

Após quitação contratual integral, toda a IP é transferida ao cliente (Vitor Autorino Lopes). Detalhes em [docs/01-PROJECT.md](docs/01-PROJECT.md) e [docs/08-RELEASE.md](docs/08-RELEASE.md).

---

Desenvolvido por **Elovision Digital** · contato via Claude Code session log.
