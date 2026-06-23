# AGENTS.md — RARO

> **Thin redirect.** Este arquivo existe como ponto de entrada universal para qualquer agente AI (Claude Code, Codex, Aider, Cursor, etc.). A configuração autoritativa está em [CLAUDE.md](CLAUDE.md).

## Read-first map

Em ordem de precedência. Leia tudo antes de propor qualquer mudança:

1. [CLAUDE.md](CLAUDE.md) — manual completo, convenções, hooks, subagents, MCP precedence
2. [docs/Blueprint.md](docs/Blueprint.md) — decisões arquiteturais aprovadas (versão e status no topo)
3. [docs/briefing/original-briefing.md](docs/briefing/original-briefing.md) — briefing imutável (não editar)
4. [docs/briefing/prototype/Prototipo-RARO.html](docs/briefing/prototype/Prototipo-RARO.html) — protótipo navegacional (fonte de verdade visual e funcional)
5. [docs/01-PROJECT.md](docs/01-PROJECT.md) → [10-CHANGELOG.md](docs/10-CHANGELOG.md) — wiki gerada
6. [docs/decisions/](docs/decisions/) — ADRs (decisões irreversíveis)
7. [docs/sessions/](docs/sessions/) — log append-only de sessões de trabalho
8. [docs/superpowers/specs/](docs/superpowers/specs/) e [docs/superpowers/plans/](docs/superpowers/plans/) — specs e plans por feature (TLC Spec-Driven)
9. [docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md](docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md) — roadmap vigente até entrega

## Regras inegociáveis

- **Protótipo é fonte de verdade** (briefing Seção 3.2). Toda divergência vira ADR antes de implementar.
- **Wake word é `"Raro"`.** "OkCamera" não existe em código, copy, docs ou ADRs.
- **Free trial alvo 30 dias** (a configurar no RevenueCat — hoje mock, PLANO-MESTRE Bloco 2), refletido no copy.
- **Planos: Mensal R$ 9,90 + Anual R$ 89,90** com badge "MELHOR OFERTA" no anual.
- **Versões fixadas** via Context7 + pub.dev — nunca atualizar dep sem novo ADR.
- **Sem comentários em código de produção** (Karpathy Surgical Changes). Nomes explicam WHAT, ADRs explicam WHY.
- **Conventional Commits 1.0.0** obrigatório, scope do scope-enum em [commitlint.config.cjs](commitlint.config.cjs).
- **Nunca `git commit --no-verify`.** Hooks lefthook + commitlint não devem ser pulados.

## Como iniciar trabalho

1. Ler `CLAUDE.md` completo.
2. Verificar `docs/sessions/0001-INDEX.md` para contexto da última sessão.
3. Se for feature nova: criar spec em `docs/superpowers/specs/` antes de tocar código (ciclo Specify → Design → Tasks → Execute).
4. Se for bugfix ou ajuste pequeno (≤3 arquivos): pode ir direto, mas commit deve referenciar Blueprint ou ADR existente.

## Comandos comuns

```bash
./setup.sh                    # bootstrap em clone novo
bun run lint                  # turbo lint
bun run typecheck             # turbo typecheck
bun run test                  # turbo test
bun run --filter '@raro/mobile' codegen   # dart run build_runner (filter DEPOIS de run — bun 1.3.13)
cd apps/mobile && flutter run # rodar o app
```

## O que NÃO fazer

- Não atualizar dep sem ADR e re-Context7
- Não adicionar arquivo `.env` ao repo (só `.env.example`)
- Não criar feature que não esteja no protótipo (ver Blueprint Seção 5)
- Não mencionar "OkCamera" em nenhum lugar
- Não bypass de hook (`--no-verify`, `--no-gpg-sign`, etc.)
- Não amendar commits — sempre novo commit
