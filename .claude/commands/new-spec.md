---
description: Cria scaffold de spec em docs/superpowers/specs/ para nova feature (Fase 5 — TLC Spec-Driven)
argument-hint: "<feature-slug> (ex camera-native-bridge)"
---

Crie um scaffold de spec para a feature `$1`.

## Passos

1. Valide que o slug é kebab-case (`feat-name`, não `FeatName` ou `feat_name`).
2. Data atual: `date +%Y-%m-%d`.
3. Arquivo alvo: `docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md`.
4. Verifique que já não existe — se existir, pare e pergunte se é amend ou nova.
5. Crie o arquivo a partir do template em `docs/superpowers/specs/0000-template.md` (vai ser criado na Fase 5; se ainda não existe, use esqueleto abaixo).
6. **NÃO preencha conteúdo da spec.** Apenas estrutura. O usuário invoca `superpowers:brainstorming` para preencher.

## Esqueleto mínimo (caso template ainda não exista)

```markdown
# <YYYY-MM-DD> — <feature-slug>

## Status
Draft

## Reading order
1. [briefing](../../briefing/original-briefing.md)
2. [Blueprint](../../Blueprint.md)
3. [protótipo HTML](../../briefing/prototype/Prototipo-RARO.html) (seção relevante)
4. ADRs relacionados: <listar>

## Problem
<o que esta feature resolve?>

## Q-table (perguntas antes de implementar)
| # | Q | A |
|---|---|---|
| 1 | ? | ? |

## Observable goals (testes em device)
- [ ] ...

## Out of scope
- ...

## Risks
- ...

## References
- ...
```

## Após criar

- Diga ao usuário: "Spec criada. Rode `superpowers:brainstorming` para preencher antes de implementar."
- NÃO crie o plan ainda — isso é o `/new-plan`.

## Anti-patterns

- ❌ Criar spec já preenchida (você não sabe o suficiente — usuário e brainstorming preenchem)
- ❌ Criar plan junto (são 2 comandos)
- ❌ Pular Q-table — perguntas explicitam ambiguidades
