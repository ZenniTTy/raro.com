# <YYYY-MM-DD> — <feature-slug>

> Spec scaffold (TLC Spec-Driven). Após criação via `/new-spec <slug>`, invoque `superpowers:brainstorming` para preencher conteúdo.

## Status

`Draft` | `Approved` | `In implementation` | `Done` | `Superseded by ...`

## Owner / Implementer

- **Spec owner:** <quem assina o WHAT>
- **Implementer agent:** `implementer` (ou outro)
- **Validator agent:** `validator`

## Reading order (pre-flight obrigatório)

Antes de implementar, ler nesta ordem:

1. `docs/briefing/original-briefing.md` (sessão relevante)
2. `docs/Blueprint.md` (decisões aprovadas)
3. `docs/briefing/prototype/Prototipo-RARO.html` (tela do protótipo correspondente, se houver)
4. `CLAUDE.md` (manual autoritativo)
5. ADRs relacionados: <listar com referência ao número>

## Problem

<O que esta feature resolve? Que dor do usuário ou requisito do briefing/protótipo? Cite a seção do briefing/Blueprint.>

## Sizing (auto-sizing)

- [ ] **Quick** (≤3 arquivos, sem mudança arquitetural) — implementa direto após brainstorming
- [ ] **Medium** (1 feature, multi-file, sem novo bridge) — exige `/new-plan` e atomic tasks
- [ ] **Large** (novo bridge, novo ADR, multi-feature) — exige `/new-plan` + ADR + design-fidelity-checker

## Q-table (perguntas antes de implementar)

Liste ambiguidades. Resposta vazia = não pode iniciar implementação.

| # | Question | Answer |
|---|----------|--------|
| 1 | ? | ? |
| 2 | ? | ? |

## Observable goals (testes em device)

Cada item deve virar teste verificável (unit, widget, golden, integration).

- [ ] <goal 1 — comportamento observável, ex: "ao apertar REC, viewport mostra timer 00:00:00 em ≤200ms">
- [ ] <goal 2>
- [ ] <goal 3>

## UI / protótipo (se aplicável)

- Tela do protótipo: P0X / M0X / —
- Tokens canônicos: cores, gradientes, tipografia (referenciar Blueprint Seção 4)
- Microinterações: <listar>
- Copy literal: <citar do protótipo, lembrar 30 dias trial>

## Out of scope

Liste o que NÃO entra para evitar scope creep:

- ...

## Risks

| Risco | Mitigação |
|-------|-----------|
| ? | ? |

## ADRs necessários

- [ ] ADR existente: <link>
- [ ] ADR novo necessário (`adr-guardian` confirma): <título sugerido>

## References

- Briefing seção <N>
- Blueprint seção <N>
- ADRs: <lista>
- Issues / PRs: <links>
- Specs relacionadas: <links>
