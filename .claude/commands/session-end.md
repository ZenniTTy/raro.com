---
description: Encerra sessão de trabalho criando session log append-only e atualizando 0001-INDEX.md
---

Encerre a sessão atual de trabalho gerando registro em `docs/sessions/`.

## Passos

1. Identifique o próximo número de session: `ls docs/sessions/` e veja o maior `NNNN-*.md` (excluindo `0000-template.md` e `0001-INDEX.md`). Próximo = `<maior+1>`.
2. Crie `docs/sessions/<NNNN>-<slug>.md` usando [docs/sessions/0000-template.md](../../docs/sessions/0000-template.md) como base. Preencha:
   - **Data:** hoje
   - **Duração:** estimativa
   - **Participantes:** Eduardo Rodrigues + Claude Code (ou agente)
   - **Branch:** `git rev-parse --abbrev-ref HEAD`
   - **Commits:** `git log --oneline <hash_inicial>..HEAD`
   - **Objetivo, Contexto, O que foi feito, O que NÃO foi feito, Aprendizados, Próximos passos**
3. Atualize `docs/sessions/0001-INDEX.md` adicionando linha no topo da tabela (mais recente primeiro).
4. Pergunte ao usuário se quer commitar via `/commit` (não commite automático — usuário deve revisar o resumo).

## Princípios

- **Append-only** — nunca edita session existente.
- **Honestidade** — registre o que não funcionou também. Aprendizados > vitórias.
- **Específico** — `git log --oneline` ajuda a lembrar; cite hashes e arquivos.

## Anti-patterns

- ❌ Session log genérico ("trabalhou no projeto")
- ❌ Pular seção "O que NÃO foi feito" — débito esquecido vira drift
- ❌ Editar session anterior
