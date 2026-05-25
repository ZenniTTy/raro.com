---
description: Re-lê o manual completo (AGENTS, CLAUDE, Blueprint, último session) para alinhar contexto antes de trabalho importante
---

Re-prime o contexto do agente lendo a documentação canônica do RARO.

## Passos (em ordem, sem pular)

1. `cat AGENTS.md` — thin redirect com regras inegociáveis
2. `cat CLAUDE.md` — manual autoritativo (13 seções, Karpathy 4 princípios)
3. `cat docs/Blueprint.md` — decisões aprovadas (Seção 1: divergências resolvidas)
4. `ls docs/decisions/ | tail -n +2` — listar ADRs ativos
5. `cat docs/sessions/0001-INDEX.md` — último estado registrado
6. `cat $(ls docs/sessions/*-*.md | grep -v INDEX | grep -v template | sort | tail -1)` — último session log completo
7. `git log --oneline -10` — último estado do código

## Output esperado

Após ler tudo, retorne **resumo de 1 parágrafo**:
- onde o projeto está agora
- locked invariants (wake word, trial, planos)
- gates ativos
- próximo passo sugerido

## Quando usar

- Início de sessão crítica (nova feature, bug em produção, decisão de stack)
- Quando o contexto longo da conversa pode ter feito drift
- Antes de invocar subagent (especialmente implementer)

## Anti-patterns

- ❌ Pular leitura achando que "já sabe" — invariantes mudam
- ❌ Resumir sem citar arquivos
- ❌ Modificar nada (este comando é só ler)
