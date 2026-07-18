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
4. docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md (ROADMAP VIGENTE)
5. docs/sessions/0001-INDEX.md (último estado)

ESTADO ATUAL (2026-07-14):
- Fase: finalização para entrega (PLANO-MESTRE, 6 blocos). NÃO é mais bootstrap.
- Voz: FOREGROUND SFSpeech "raro gravar"/"raro parar" FUNCIONA (iPhone 12).
  BACKGROUND wake-word ONNX próprio = INVIÁVEL (sessão 0029, 4 modelos).
  NÃO reabrir treino ONNX nem WakeWordDetector sem ADR novo (beco provado,
  ~US$11). Prompt openwakeword = OBSOLETO.
- SENSORY EM VALIDAÇÃO ATIVA (0033, email Jeff Rogers 2026-06-23): respondeu,
  deu VoiceHub Pro grátis (expira 2026-09-21), TEM pt-BR nativo, licença de
  PRODUÇÃO non-expiring + 1 preço cobre iOS+Android; dono ASSINOU o NDA mútuo.
  Modelo "Raro" pt-BR em build (Best Quality). PENDENTE p/ decidir: (a) PREÇO
  (Jeff vai mandar; per-user inviabiliza R$9,90, flat/per-app serve) + (b) TESTE
  do modelo no iPhone 12. Decisão de produto ABERTA — NÃO é "Sensory resolvido".
  Runtime background já provado (memória proven-ane); o que falta é a palavra
  "Raro" passar no device.
- Mock/pendente: RevenueCat (bool local), share ("Em breve"), i18n (0 .arb),
  Volume (stub). Ver PLANO-MESTRE.
- Firebase Bloco 1 FECHADO (0034 código+build, 0035 provado no iPhone 12):
  Firebase.initializeApp em main.dart + 3 handlers Crashlytics + analytics
  listener ligado (era morto); plugins gradle google-services 4.4.4 +
  crashlytics 3.0.7. Provado no device: crash chegou no painel Crashlytics +
  dSYM subido (UUID bate). firebase_options.dart/plist/json gitignored (chaves
  reais, só no device do dono). Próximo CÓDIGO = Bloco 2 (Monetização
  RevenueCat, depende conta+produtos+IAP Key do dono). Ver ADR-0025.
- Android pré-APK: 3 de 4 fatias FECHADAS e provadas no Galaxy M54.
  Fatia 1 GRAVAÇÃO (0037, PR #5): CameraX VideoCapture<Recorder>, MP4+áudio
  real (ADR-0030). Fatia 2 FOCO (0038, PR #7): tap-to-focus nativo + ring.
  Fatia 3 VOZ (0038, PR #8 aberto): "raro gravar"/"raro parar" via VOSK
  MOTOR ÚNICO (vosk-android 0.3.47 + FGS microphone, ADR-0029) — provado no
  M54 (câmera gravou por voz). SpeechRecognizer nativo NÃO usado (motor único,
  spike-gate provou pt-BR on-device). Voice HostApi registrada no MainActivity.
  Falta Fatia 4 (i18n PT/EN/ES) → depois o APK do cliente.
  ReplayBuffer/Volume HostApi Android seguem não registradas (fatia futura).

Locked invariants:
- Wake word = "Raro" (NUNCA "OkCamera")
- Free trial = 30 dias (não 15)
- Planos = Mensal R$ 9,90 + Anual R$ 89,90 com "MELHOR OFERTA"
- Bundle ID = com.rarocamera (iOS + Android applicationId alinhados,
  Bloco 0.3 resolvido 2026-06-22; namespace Kotlin segue raro_mobile, ok)
- Backend = client-only (sem apps/api)

Gates ativos:
- Conventional Commits via commitlint (subject lowercase, scope obrigatório)
- lefthook pre-commit: dart-format, biome-format, block-secrets
- lefthook pre-push: bun run lint && bun run test
- .claude/hooks/ (11 hooks): PreToolUse: block-env, block-secrets,
  warn-adr-drift, block-forbidden-terms, block-pigeon-error-rawvalue,
  warn-gesturedetector-over-platformview, warn-sfspeech-recycle-per-error
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
  echo "Últimas sessões (ver 0001-INDEX.md para detalhe):"
  # cabeçalho + 3 linhas de sessão, truncando colunas longas para não poluir o contexto
  grep -E '^\| \[[0-9]' "$root/docs/sessions/0001-INDEX.md" | head -3 | cut -c1-140
fi

echo ""
echo "=== /context re-injection ==="
