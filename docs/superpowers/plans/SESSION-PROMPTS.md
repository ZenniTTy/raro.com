# Session Prompts — Índice

> Os prompts agora estão **separados em 3 arquivos**, um por Sprint. Self-contained: abra o arquivo da Sprint que vai trabalhar, copie o prompt apropriado, cole em chat novo Claude Code.

---

## Arquivos

| Sprint | Arquivo | Entrega |
|---|---|---|
| **Sprint 1** | [SPRINT-1-PROMPTS.md](SPRINT-1-PROMPTS.md) | Foundation + Walking Skeleton iOS (cleanup + 12 telas mockadas no iPhone 12 free) |
| **Sprint 2** | [SPRINT-2-PROMPTS.md](SPRINT-2-PROMPTS.md) | Backend/Lógica Real iOS (recording, replay, wake word, volume, paywall sandbox, share) |
| **Sprint 3** | [SPRINT-3-PROMPTS.md](SPRINT-3-PROMPTS.md) | Android Parity + TestFlight + Cliente (Android nativo, $99 Apple Dev, $25 Google Play, cliente convidado) |

---

## Conteúdo de cada arquivo (mesma estrutura nos 3)

Cada `SPRINT-N-PROMPTS.md` contém:

1. **N.0 — Kickoff** — primeira sessão da Sprint, audit completo (FASE 1-4) ANTES de executar Task A. Custo: 30-50min upfront. Benefício: zero rework por dep deprecated.
2. **N — Sessão de execução** — sessões subsequentes, substitui `[TASK]` pela letra (B, C, D, etc.). Audit leve (herda Kickoff).
3. **N — Sessão de closure** — última sessão da Sprint, smoke test fim-a-fim + Blueprint mark.
4. **Audit-only** — validar MD sem executar.
5. **Recovery** — algo quebrou.
6. **Continuação** — sessão pausada mid-Task.
7. **Lembretes universais** — guardrails vigentes nessa Sprint.
8. **Em palavras simples** — explicação plain language.

---

## Fluxo padrão

```
Sprint 1 (iOS walking skeleton)
   ↓
   abre SPRINT-1-PROMPTS.md
   ↓
   primeira sessão: cola "1.0 — Kickoff"
   ↓
   sessões seguintes: cola "1 — Sessão de execução" trocando [TASK]
   ↓
   última sessão: cola "1 — Sessão de closure" + smoke test
   ↓
Sprint 2 (backend real iOS)
   ↓
   abre SPRINT-2-PROMPTS.md
   ↓
   mesmo fluxo (2.0 Kickoff → execução → closure)
   ↓
Sprint 3 (Android + TestFlight + cliente)
   ↓
   abre SPRINT-3-PROMPTS.md
   ↓
   mesmo fluxo (3.0 Kickoff → execução → closure)
   ↓
v1.0 candidata App Store + Play Store
```

---

## Princípio

**Pagar audit completo UMA VEZ no Kickoff de cada Sprint** > revisar e refatorar TODA sessão. Tua escolha consciente foi essa. Cada Kickoff valida 26-39 items externos via WebSearch + Context7 ANTES de tocar em código.

---

## Em palavras simples

Antes esse arquivo tinha os 3 prompts juntos. Agora cada Sprint tem o seu (mais fácil pra copiar/colar — abre o arquivo certo, ctrl+A no prompt que precisa, cola).

Quando for começar Sprint 1, abre `SPRINT-1-PROMPTS.md` e usa lá. Sprint 2 idem em `SPRINT-2-PROMPTS.md`. Sprint 3 em `SPRINT-3-PROMPTS.md`. Esse índice (SESSION-PROMPTS.md) é só pra você saber onde encontrar o quê.

