# 04-ROADMAP-SPECS — detalhamento por bloco

> Detalhamento técnico das 20 specs do [roadmap](../04-ROADMAP.md). Cada bloco agrupa specs por afinidade temática e dependência.

## Inventário

| Arquivo | Specs cobertas | µ-sprints | Sizing predominante |
|---|---|---|---|
| [spec-001-api-contract-shared.md](spec-001-api-contract-shared.md) | 001 (única — bloqueante) | 7 | Medium |
| [block-infra.md](block-infra.md) | 002, 003, 004, 005 | 12 | Quick + Medium |
| [block-bridges.md](block-bridges.md) | 007, 008, 009 | 21 | Large 🔴 |
| [block-features.md](block-features.md) | 010, 011, 013, 014, 015, 016 | 38 | Medium + Large |
| [block-polish.md](block-polish.md) | 006, 012, 017, 018, 019, 020 | 22 | Quick + Medium |
| **TOTAL** | **20 specs** | **100 µ-sprints** | — |

## Como navegar

1. **Lendo o roadmap completo:** comece pelo [04-ROADMAP.md](../04-ROADMAP.md) (DAG + tabela com sizing/deps).
2. **Para começar:** [spec-001-api-contract-shared.md](spec-001-api-contract-shared.md) (bloqueia tudo).
3. **Por bloco:** abra o arquivo do bloco e procure pela seção da spec específica (`## spec-NNN — slug`).

## Regras universais aplicadas a todas as specs

- **Conventional Commits** com scope do scope-enum em [commitlint.config.cjs](../../commitlint.config.cjs). Subject lowercase. Sem `--no-verify`.
- **Gates universais:** `bun run lint && bun run typecheck && bun run test` zero issues antes de commit.
- **Gates contextuais:** ver [.claude/slice-checklist.md](../../.claude/slice-checklist.md).
- **Hooks ativos:** ver [CLAUDE.md Seção 8](../../CLAUDE.md).
- **Subagents:** invocados conforme contexto (ver [CLAUDE.md Seção 7](../../CLAUDE.md)).

## Ordem de execução recomendada

```
001 (api contract — BLOQUEIA TUDO)
  ↓
[002 + 003 + 004 + 005] (infra paralela)
  ↓
007 (camera bridge — espinha dorsal técnica)
  ↓
008 (replay) → 009 (voice) → 010 (volume) → 011 (lock)
  ↓
[006 (splash) + 012 (i18n)] (paralelo)
  ↓
013 (paywall) → 014 (checkout)
  ↓
015 (gallery) → 016 (preview)
  ↓
017 (permissions) → 018 (onboarding) → 019 (xiaomi)
  ↓
020 (settings — última, depende de quase tudo)
  ↓
RELEASE v1.0.0
```

## Atualização

Este diretório deve ser atualizado quando:
- Spec é mergeada (marcar como `Done` na tabela do block correspondente)
- Spec é abandonada (marcar como `Superseded by ...`)
- Novo ADR muda contrato de uma spec ainda não implementada
- Surge dependência cruzada não prevista (registrar em ADR + atualizar DAG no [04-ROADMAP.md](../04-ROADMAP.md))

**Sem editar specs já mergeadas** — append-only no `docs/sessions/` para narrar o que mudou.
