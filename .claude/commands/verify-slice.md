---
description: Roda verificação completa antes de declarar fatia pronta (lint + test + design-fidelity + slice-checklist)
---

Verifique se a slice atual está pronta para PR/merge, executando todos os hard gates.

## Passos (em ordem)

### 1. Lint + typecheck + test

```bash
bun run lint
bun run typecheck
bun run test
```

Cada um deve passar zero issues. Se falhar — pare, mostre output, sugira fix.

### 2. Slice checklist contextual

Ler [.claude/slice-checklist.md](../slice-checklist.md) e aplicar checks relevantes ao diff atual:

- **Tocou `lib/app.dart` ou navegação?** → integration test em device real (sugerir comando, mas não rodar automático)
- **Tocou tela com baseline golden?** → `flutter test --update-goldens` e diff visual aprovado
- **Tocou Method Channel?** → contract test em iOS + Android
- **Tocou tela do protótipo?** → invocar agent `design-fidelity-checker`
- **Mudou dep ou stack?** → invocar agent `adr-guardian`

### 3. Design fidelity (se tocou tela)

Invoque `design-fidelity-checker` subagent passando:
- Tela: `apps/mobile/lib/features/<f>/presentation/<screen>.dart`
- Protótipo: P0X conforme docs/06-SCREENS.md

### 4. ADR guard (se tocou stack/contrato)

Invoque `adr-guardian` subagent passando o diff.

### 5. Smoke commit

Tente criar um commit de teste vazio (`git commit --allow-empty -m "test(scaffold): smoke"`) — se hooks bloquearem incorretamente, fix antes do PR.

Reverter: `git reset --soft HEAD~1`.

### 6. Output final

```markdown
# Slice verify — <branch> (<date>)

## ✅ Passed
- bun run lint
- bun run test
- design-fidelity (se aplicável)
- adr-guardian (se aplicável)

## ❌ Failed
- ...

## ⚠️ Manual still needed
- integration test em device físico
- diff visual de goldens
```

## Anti-patterns

- ❌ Declarar pronto sem rodar todos os gates
- ❌ Pular design-fidelity ("é só um botão")
- ❌ Ignorar warnings ("não é error")
- ❌ Bypass de hook com `--no-verify`
