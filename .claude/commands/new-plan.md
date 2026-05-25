---
description: Cria scaffold de plan em docs/superpowers/plans/ a partir de uma spec já existente
argument-hint: "<feature-slug> (deve corresponder a uma spec existente)"
---

Crie scaffold de plan para a feature `$1`. Requer que a spec correspondente exista.

## Passos

1. Verifique que existe `docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md`. Se não → parar e pedir para rodar `/new-spec $1` primeiro.
2. Data atual: `date +%Y-%m-%d`.
3. Arquivo alvo: `docs/superpowers/plans/<YYYY-MM-DD>-<slug>.md`.
4. Verifique que já não existe.
5. Crie a partir do template em `docs/superpowers/plans/0000-template.md` (Fase 5; se não existir, use esqueleto).
6. **NÃO preencha conteúdo.** Estrutura apenas. Usuário invoca `superpowers:writing-plans` para preencher.

## Esqueleto mínimo

```markdown
# Plan — <feature-slug>

## Spec
`docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md`

## 7 execution rules (sempre aplicar)
1. Surgical changes — só toque no que o plan pede
2. Sem comentários em código de produção
3. Imports absolutos via package:raro_mobile/...
4. Riverpod 3 codegen — @riverpod annotation
5. Strict lints — flutter analyze zero issues após cada arquivo
6. Strings de UI em .arb — sem inline
7. Conventional Commits — scope do scope-enum

## Phase 0 — pre-flight
- [ ] Spec lida integralmente
- [ ] Q-table respondida
- [ ] ADRs necessários abertos
- [ ] Dependências de outras features identificadas

## Atomic tasks

### Task 1 — <título>
- Files: <listar>
- Code outline: <pseudocódigo>
- Verification: <comando que prova que está pronto>
- Commit: <type>(<scope>): <subject>

### Task 2 — ...

## Done when
- [ ] Todas atomic tasks ✅
- [ ] flutter analyze + flutter test zero issues
- [ ] design-fidelity-checker passa contra protótipo
- [ ] validator subagent confirma
```

## Após criar

Diga: "Plan criado. Rode `superpowers:writing-plans` para preencher tasks antes de invocar implementer."

## Anti-patterns

- ❌ Criar plan sem spec
- ❌ Atomic tasks vagas ("implementar X")
- ❌ Tasks sem verification rodável
