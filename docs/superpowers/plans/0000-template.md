# Plan — <feature-slug>

> Plan scaffold (TLC Spec-Driven). Após criação via `/new-plan <slug>`, invoque `superpowers:writing-plans` para preencher tasks.

## Spec

`docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md` (deve existir antes deste plan)

## 7 execution rules (sempre aplicar)

1. **Surgical changes** — só toque no que o plan pede. Sem refactor de passagem.
2. **Sem comentários** em código de produção. Nomes explicam WHAT.
3. **Imports absolutos** via `package:raro_mobile/...` ou `package:raro_shared/...`. Sem `../../../`.
4. **Riverpod 3 codegen** — `@riverpod` annotation + `part '<file>.g.dart'`. Codegen via `bun --filter @raro/mobile run codegen`.
5. **Strict lints** — `flutter analyze` zero issues após cada arquivo modificado.
6. **Strings de UI em `.arb`** — sem inline. `pt-BR` (default) + `en` + `es`.
7. **Conventional Commits** — scope do scope-enum em `commitlint.config.cjs`. Subject lowercase. Sem `--no-verify`.

## Phase 0 — pre-flight (bloqueante)

Antes de Phase 1, confirmar:

- [ ] Spec lida integralmente, status `Approved`
- [ ] Q-table preenchida (sem `?` em respostas)
- [ ] Sizing definido (Quick/Medium/Large)
- [ ] ADRs necessários abertos (invocar `adr-guardian` se dúvida)
- [ ] Dependências de outras features identificadas
- [ ] Branch criado a partir de `main` ou de feature parent
- [ ] Hooks lefthook + .claude/hooks/ instalados (`./setup.sh` rodado)

## Atomic tasks

### Task 1 — <título descritivo>

- **Files to touch:** <listar com path completo>
- **Code outline:** <pseudocódigo Dart ou descrição da estrutura>
- **Dependencies:** <quais tasks precisam ter terminado antes>
- **Verification:**
  - [ ] `flutter analyze apps/mobile` zero issues
  - [ ] `dart test packages/shared` passa (se aplicável)
  - [ ] `flutter test test/features/<f>/.../task1_test.dart` verde
  - [ ] <golden ou integration test específico, se aplicável>
- **Commit suggestion:**
  ```
  <type>(<scope>): <subject lowercase>
  ```

### Task 2 — <título>

(repetir estrutura)

### Task N — testes finais + design fidelity

- Invocar `validator` subagent com diff vs main
- Invocar `design-fidelity-checker` se tocou tela do protótipo
- `bun run lint && bun run test` passa

## Done when (definition of done desta feature)

- [ ] Todas atomic tasks ✅
- [ ] `bun run lint && bun run typecheck && bun run test` zero issues
- [ ] `validator` subagent confirma cumprimento da spec
- [ ] `design-fidelity-checker` passa contra protótipo (se aplicável)
- [ ] Goldens regerados e diff visual aprovado (se aplicável)
- [ ] Native bridges com contract test em iOS + Android (se aplicável)
- [ ] Integration test em device físico (se tocou navegação ou nativo)
- [ ] Strings de UI em todos 3 idiomas (`pt-BR`, `en`, `es`)
- [ ] ADRs criados/atualizados linkados nos commits
- [ ] CHANGELOG (`docs/10-CHANGELOG.md`) atualizado
- [ ] Session log em `docs/sessions/` registrando o trabalho
- [ ] PR aberto seguindo template (futuro)

## Rollback plan

Se a feature precisar ser revertida:

1. `git revert <commit>` (não `reset --hard`)
2. Atualizar CHANGELOG com nota de revert
3. Spec marcada como `Superseded by ...` ou `Reverted`
4. Session log explicando motivo
