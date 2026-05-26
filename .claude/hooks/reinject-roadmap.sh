#!/usr/bin/env bash
# reinject-roadmap.sh — em SessionStart, lê doc-chave e ecoa para stdout
# Disparado em: SessionStart
# Conteúdo ecoado vai como "additional context" para o agente na nova sessão.
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

cat <<'EOF'
=== RARO context re-injection (SessionStart) ===

Read order obrigatório:
1. AGENTS.md (thin redirect)
2. CLAUDE.md (manual autoritativo)
3. docs/Blueprint.md (decisões aprovadas)
4. docs/sessions/0001-INDEX.md (último estado)

Locked invariants:
- Wake word = "Raro" (NUNCA "OkCamera")
- Free trial = 30 dias (não 15)
- Planos = Mensal R$ 9,90 + Anual R$ 89,90 com "MELHOR OFERTA"
- Bundle ID = com.rarocamera
- Backend = client-only (sem apps/api)

Gates ativos:
- Conventional Commits via commitlint (subject lowercase, scope obrigatório)
- lefthook pre-commit: dart-format, biome-format, block-secrets
- lefthook pre-push: bun run lint && bun run test
- .claude/hooks/ registrados em settings.json (6 hooks em 3 eventos):
  PreToolUse: block-env, block-secrets, warn-adr-drift
  PostToolUse: format-dart, run-riverpod-codegen
  SessionStart: reinject-roadmap
- .claude/hooks/verify-task.sh: utilitário invocável manualmente
  via /verify-slice (não em Stop event para evitar overhead por turno)

Subagents disponíveis (.claude/agents/):
- implementer, flutter-test-author, researcher (write-capable)
- validator, adr-guardian, flutter-perf-auditor,
  design-fidelity-checker (read-only)

Slash commands (.claude/commands/):
- /commit, /session-end, /docs-lint, /prime,
- /new-spec, /new-plan, /verify-slice, /ingest-source

Status do projeto:
EOF

if [ -f "$root/docs/sessions/0001-INDEX.md" ]; then
  echo ""
  head -10 "$root/docs/sessions/0001-INDEX.md"
fi

echo ""
echo "=== /context re-injection ==="
