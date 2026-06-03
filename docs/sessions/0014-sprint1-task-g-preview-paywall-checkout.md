# 0014 — Sprint 1 Task G (Preview P08 + Subscription popup M01 + Paywall P09 + Checkout P10 + trial countdown)

- **Data:** 2026-06-02
- **Duração:** ~4h
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `5f5c5bb`…`aca3aa9` (6 commits)

## Objetivo

Sprint 1 Task G do walking skeleton iOS: fechar as 4 telas/overlays restantes do fluxo de assinatura — **Preview (`AppScreen.p08Preview`)**, **Subscription popup (`AppModal.m01SubscriptionPopup`)**, **Paywall (`AppScreen.p09Paywall`)**, **Checkout (`AppScreen.p10Checkout`)** + **trial countdown** — todos via TDD, fiéis ao protótipo, com Riverpod 3 providers swap-able pro Sprint 2. Substituir os stubs `paywall_placeholder`/`preview_placeholder` do router.

## Contexto inicial

- Tasks A–F fechadas (suíte 155/155 GREEN ao fim da 0013). Router com stubs `paywall_placeholder`/`preview_placeholder` + `_ScreenStub`.
- Pré-requisito bloqueante: `video_player` era dep nova (fora do pubspec e da stack pinada Blueprint §2) → exigia ADR antes de implementar o Preview (CLAUDE.md §3).
- Naming: o MD do Sprint 0 usa numeração Pnn que **não** bate com o contrato `AppScreen`. Usei os enums do contrato (desambiguação Blueprint §11).

## O que foi feito

**Mini-audit (reconciliação MD vs. codebase):** o MD do Sprint 0 inventava literais (`'raro.subscribed'`, `const monthlyPriceBRL`) e não conhecia o contrato `raro_shared` (que já tinha `SubscriptionSkus`/`SubscriptionConfig`/eventos analytics). Segui o contrato como fonte de verdade.

**Decisões do usuário (4):**
1. Preview reproduz **vídeo real** → bundlar 1 `.mp4` de teste (gerado via ffmpeg, 720×1280 9:16, 3s, ~0.5MB).
2. Preços de display **no contrato** `raro_shared` (`PlanPricing`), não hardcoded na feature.
3. `video_player` **`^2.11.1`** (latest, validado pub.dev + Context7).
4. Corrigir **todos** os 10 fixes de design-fidelity (não só os baratos).

**Pré-requisito (commit `5f5c5bb`):** ADR-0017 (video_player Accepted) + adendo Blueprint §2.7.1 + `flutter pub add video_player` + asset mp4. Padrão validado: provider `autoDispose` + `ref.onDispose(controller.dispose)` (best practice 2026, evita leak — memória `raro-pattern-flutter-video-player-disposal`).

**G1 Preview (commit `f8c1ac7`):** `PreviewScreen` busca `VideoEntity` por id do `videoListProvider`; viewport 9:14 + play central + scrubber + metadata card. `PreviewMetadata` (domain puro, 6 testes): H.265, size determinístico proporcional à duração (~256MB em 2:30). `previewController` `@riverpod` autoDispose.

**Contrato (commit `6684d2e`):** `PlanPricing` (9.90/89.90/7.49, ADR-0010) + `StorageKeys.subscriptionActive`/`trialStartedAt`. smoke_test do shared cobre os 3 preços + 2 keys (39/39 GREEN).

**G2 M01 popup (commit `42c9a02`):** `SubscriptionState` (domain, 6 testes: trial math 30d). `SubscriptionStore` port + `SubscriptionController` keepAlive. `SubscriptionPopup` overlay na câmera, auto após 450ms se `!subscribed`; CTA → onSeePlans. 4 nav-tests novos na câmera.

**G3 Paywall + Checkout (commit `0e4f3b6`):** `PaywallScreen` (2 PlanCards selecionáveis + features), `CheckoutScreen` (2 tiles pgto, CTA disabled até método, confirma → `subscribe(now)` → câmera). `PlanType`/`PaymentMethod` domain. Trial countdown via `_TrialBanner` em Settings. Router: stubs → telas reais + rota `/checkout`; `_ScreenStub` removido. Nav-test fim-a-fim câmera→popup→paywall→checkout→confirma→câmera.

**Design-fidelity (commit `aca3aa9`):** 2 rodadas do `design-fidelity-checker`. 1ª pegou 10 divergências; corrigi todas. 2ª re-validação: 10/10 resolvidos + pegou **2 erros meus de fidelidade** (scrubber branco vs rainbow do protótipo; radius 16/14.5 que eu mudei seguindo um falso-positivo da 1ª rodada — o HTML real é 22/20.5). Corrigi ambos pro protótipo. Hex movidos pra `core/theme` (Family 11 isolation): `RaroGradients.rainbow` ganhou stops explícitos + `modalBorder`/`planCardBorder`/`paywallGlowWarm`/`Cool`.

**Gate de verificação:** `flutter analyze` 0 issues, suíte completa **200/200** GREEN (155 → 200, +45 líquido, golden incluído — rainbow stops não regrediu telas validadas), shared 39/39, design-fidelity 10/10 resolvidos.

Blueprint §11: P06/P09/P10/P11 + trial countdown marcados ✅ (com mapeamento contrato vs. MD). Todas as 12 telas do walking skeleton agora ✅.

## O que NÃO foi feito (e por quê)

- **Validação no iPhone 12:** Task G é Flutter+mock (o video_player toca um clipe local, sem hot-path de câmera/bridge), então não dispara os hard gates de device do CLAUDE.md §10. A validação física do fluxo completo das 12 telas é a **Task H** (smoke test fim-a-fim) — incluindo confirmar o vídeo tocando no device real e o popup M01 com delay perceptual.
- **Telas P11/P12 Termos/Privacidade reais:** o paywall tem os **links** "Termos de Uso · Política de Privacidade" (com toast "Em breve"), mas as telas de conteúdo legal são **Sprint 3** (Blueprint §11). Conteúdo virá do cliente.
- **RevenueCat real:** o `SubscriptionController` é mock (persiste em prefs). Sprint 2 substitui a impl do port por RevenueCat sandbox sem mudar a UI (swap point preservado).
- **Restaurar compras / share / delete reais:** botões presentes com toast "Em breve" (Sprint 2).

## Aprendizados / surpresas

- **`video_player` em Riverpod: provider `autoDispose` + `ref.onDispose(dispose)` é o padrão 2026** — resolve o histórico de leak idiomaticamente, em vez de dispose manual em StatefulWidget (validado WebSearch + Riverpod docs).
- **Confiar num único design-fidelity-checker é arriscado** — a 1ª rodada reportou "protótipo = radius 16" e eu "consertei" 22→16; a 2ª rodada leu o CSS real (`.sub-popup{border-radius:22px}`) e me pegou introduzindo drift contra a fonte de verdade. Lição: quando um checker afirma um valor do protótipo, vale conferir o HTML direto antes de "corrigir" — e rodar o checker 2× (uma pós-fix) compensa.
- **`VideoProgressIndicator` não aceita gradiente** — o protótipo usa rainbow na barra tocada; precisei de scrubber custom (Stack + FractionallySizedBox com `RaroGradients.rainbow` + knob + seek por gesto).
- **`flutter_tester` órfãos travam o `git commit`** — execuções de `flutter test` deixaram processos `flutter_tester` pendurados que competiam por recursos e faziam o pre-commit hook (lefthook dart-format) travar. `pkill -f "flutter_tester"` destravou. Vale limpar testers órfãos se um commit pendurar.
- **Contract test `forbidden_literals` (Family 11) pegou hex 2×** — primeiro nas features (gradientes inline), depois nos glows do watermark. Reforço da lição da 0013: cor/gradiente novo **sempre** em `core/theme`, nunca inline em feature.
- **dart-format reflow aborta commit (de novo)** — recorrente; re-`git add` + recommit resolve (já documentado na 0013).

## Próximos passos

- **Sprint 1 Task H** (próxima sessão = closure): smoke test fim-a-fim manual no iPhone 12 das 12 telas (splash → onboarding → permissions → câmera → REC → settings → gallery → preview com vídeo tocando → popup M01 → paywall → checkout → confirma → trial countdown em Settings). Sem regressão camera nativa. Marcar Blueprint §11 Sprint 1 todos ✅. Cole `SPRINT-1-PROMPTS.md` §"1 — Sessão de closure".
- Sprint 2 backlog: RevenueCat real (swap do port); recording/replay/wake word/volume nativos; share/delete/restore reais; unificar `BufferDuration` duplicado (dívida da 0013).

## Referências

- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` §"Task G"
- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1 — Sessão de execução"
- Protótipo: `docs/briefing/prototype/Prototipo-RARO.html` (Preview ~1199, Paywall ~1247, Checkout ~1394, M01 ~481)
- ADR-0017 (video_player) + Blueprint §2.7.1 + §11 atualizado (P06/P09/P10/P11/trial ✅)
- Commits: `5f5c5bb` (deps/ADR), `f8c1ac7` (preview), `6684d2e` (contrato), `42c9a02` (M01), `0e4f3b6` (paywall/checkout), `aca3aa9` (design-fidelity)
