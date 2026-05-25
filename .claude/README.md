# .claude/ — Harness do Claude Code

> Configuração de subagents, hooks e slash commands para o repo RARO. Manual autoritativo em [../CLAUDE.md](../CLAUDE.md).

## Estrutura

| Diretório | Conteúdo | Quando é usado |
|---|---|---|
| `agents/` | 7 subagents (`*.md` com frontmatter YAML) | Quando o agente principal delega tarefa especializada |
| `commands/` | 9 slash commands (`*.md`) | Quando o usuário digita `/<command>` |
| `hooks/` | 8 shell scripts (`*.sh`) | Em eventos do Claude Code (PreToolUse, PostToolUse, SessionStart) |
| `settings.json` | Permissões + registro de hooks + MCP servers | Carregado no início de toda sessão |
| `slice-checklist.md` | Checklist de hard gates antes de declarar feature pronta | Lido pelos slash commands `/verify-slice` |

## Como funciona

1. **Settings.json** declara o que está permitido (e o que está bloqueado) por padrão, mais o registro dos hooks por evento.
2. **Hooks** são scripts shell disparados em eventos: por exemplo, antes de cada `Write` (`PreToolUse:Write`), o `block-env.sh` checa se o caminho é `.env` e aborta.
3. **Subagents** são prompts especializados com `tools:` allowlist própria. O agente principal os invoca via `Agent` tool.
4. **Slash commands** são gatilhos rápidos para fluxos comuns (`/commit`, `/new-spec`, `/verify-slice`).

## Não editar diretamente

Mudanças nesta pasta exigem:
- ADR explicando *por quê* (especialmente novos hooks ou mudanças em `tools:` de subagent)
- Atualização de [../CLAUDE.md Seções 7, 8, 9](../CLAUDE.md)
- Teste manual: `bun run lint && bun run test` + commit de teste

## Referências

- [Anthropic Claude Code docs](https://docs.anthropic.com/claude/docs/claude-code)
- ADR 0006 (commit conventions) — base do `verify-task.sh`
