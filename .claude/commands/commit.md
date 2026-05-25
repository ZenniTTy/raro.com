---
description: Cria commit Conventional com scope-enum e subject lowercase, sem --no-verify
---

Crie um commit Conventional Commits 1.0.0 seguindo as regras do projeto RARO.

## Passos

1. Rode `git status --short` para ver o que está staged/não-staged.
2. Rode `git diff --cached` (e `git diff` se nada staged) para entender as mudanças.
3. Rode `git log --oneline -5` para alinhar estilo das mensagens recentes.
4. Analise o diff e proponha:
   - **type:** `feat` / `fix` / `refactor` / `docs` / `style` / `test` / `chore` / `perf` / `build` / `ci` / `revert`
   - **scope:** do scope-enum em `commitlint.config.cjs`
   - **subject:** lowercase, ≤100 chars, sem ponto final
   - **body:** explica o porquê, não o quê. Pode ter múltiplas linhas.
5. Se nada está staged ainda, sugira `git add <files>` (NÃO use `git add -A` para evitar capturar `.env` ou secrets).
6. Crie o commit com HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject lowercase>

<body opcional>
EOF
)"
```

7. **Nunca** use `--no-verify`. Se hook falhar, mostre o erro e proponha fix.
8. Rode `git status` após commit para confirmar.

## Regras inegociáveis

- Subject lowercase (commitlint vai bloquear capital)
- Scope do scope-enum (lista em `commitlint.config.cjs`)
- Sem ponto final no subject
- Nunca capturar `.env`, `keystore.jks`, `google-services.json` etc.
- Nunca `--no-verify`

## Anti-patterns

- ❌ Commit com mensagem "wip", "fix", "update"
- ❌ Mais de uma mudança lógica num commit
- ❌ Body com "as requested" — explique o porquê real
