# 0013 — Sprint 1 Task F (Settings P06 + Gallery P07)

- **Data:** 2026-06-02
- **Duração:** ~2h30min
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `46d9635`, `3f60e18`, `423ad35`

## Objetivo

Sprint 1 Task F do walking skeleton iOS: substituir os stubs `/settings` e `/gallery` (deixados pela Task E) por telas reais — **Settings (`AppScreen.p06Settings`)** com `RecordingSettings` persistido em `shared_preferences` e **Gallery (`AppScreen.p07Gallery`)** com vídeos mock em grid 3-col + filtros. Tudo via TDD, fiel ao protótipo, Riverpod providers com signature swap-able pro Sprint 2.

## Contexto inicial

- Tasks A–E fechadas (suíte 122/122 GREEN ao fim da 0012). Router com stubs `_ScreenStub` para `/settings` e `/gallery`, alcançáveis pelos botões da câmera P05.
- Handoff note (`bd04e63`) alertava: o MD numera "P07 Settings / P08 Gallery", mas o contrato `AppScreen` em `raro_shared` usa `p06Settings`/`p07Gallery` — usar o contrato. Stubs a substituir, não rotas novas.
- Persistência existente (onboarding) usava `SharedPreferences.getInstance()` (API legada).

## O que foi feito

**Mini-audit (reconciliação MD vs. codebase):** o MD do Sprint 0 inventava enums (`ReplayDuration`/`AppLocale`) e um `stabilization` toggle. O contrato real do `raro_shared` já tinha `Resolution`/`Fps`/`BufferDuration`/`ControlMode`/`AppLanguage` + `StorageKeys` prontas, e o protótipo mostra estabilização como **status fixo** ("SEMPRE ATIVADA"), não toggle. Segui o contrato + protótipo (fonte de verdade), não o MD.

**Decisões do usuário (4):**
1. Idioma no Settings: **persistir só a preferência** (i18n real = Sprint 3).
2. Filtros da Gallery: **filtrar de verdade** client-side (mocks com `recordedAt`/`isReplay` realistas).
3. Persistência: **modernizar tudo** para `SharedPreferencesAsync` (Settings + onboarding).
4. Test util do prefs async: **evitar o import do `platform_interface`** (sem dep nova / sem ADR).

**Settings (F1, commit `3f60e18`):**
- `RecordingSettings` (freezed) + `RecordingSettingsCodec` puro (encode/decode by-name, parse defensivo → default em valor inválido).
- `SettingsStore` port + impl `SharedPreferencesAsync`; `SettingsController` `@riverpod` keepAlive via `settingsStoreProvider` injetável (swap point Sprint 2).
- UI fiel: qualidade (resolução 2×2 + fps), estabilização status verde, replay grad-border card 15/30s, controle voz/volume com check rainbow, idioma PT/ES/EN (emoji), Sobre + Ver Planos.

**Onboarding modernizado (commit `46d9635`):** roteado por `OnboardingStore` port (mesmo padrão do `permission_handler`), impl em `SharedPreferencesAsync`. API pública intacta; 3 testes de regressão adaptados pra injetar fake — GREEN.

**Gallery (F2, commit `423ad35`):**
- `VideoEntity` (freezed) com `formattedDuration`; `thumbnailHue` (gradiente HSL gerado, sem PNG — conforme protótipo).
- `GalleryFilter` enum com `apply(now:)` puro (semana ISO segunda-início); `videoList` provider (6 mocks) + `GalleryFilterController`.
- UI: header com contagem, filter pills, grid 3-col de thumbnails (play + badge duração + marcador replay).
- Router: stubs → telas reais; novos stubs `paywall`(p09)/`preview/:id`(p08) pra Task G; 2 nav-tests atualizados.

**Gate de verificação:** `flutter analyze` 0 issues, suíte completa **155/155** GREEN (122 → 155, +33 líquido), `design-fidelity-checker` **13/13 PASS**. Contract test `forbidden_literals` (Family 11) pegou hex `Color(0xFF..)` fora de `core/theme/` → corrigido movendo pra `RaroAccents.green`/`RaroAccents.selectedSurface`.

Blueprint §11: P07 Settings + P08 Gallery marcados ✅ (com nota de mapeamento contrato vs. MD).

## O que NÃO foi feito (e por quê)

- **Validação no iPhone 12:** Task F é só Flutter+mock (sem hot-path de câmera/bridge), então não dispara os hard gates de device do CLAUDE.md §10. A validação física do fluxo completo é a Task H (smoke test fim-a-fim).
- **Impl real de prefs sem unit-test:** `SharedPreferencesAsync` é impossível de unit-testar sem o `platform_interface` (vetado). Seguindo o padrão já estabelecido do `PermissionHandlerGateway` (que também não tem teste de impl), a lógica vive no port/codec (testados) e o impl real é validado em device. Decisão consciente, não débito silencioso.
- **`BufferDuration` duplicado (pré-existente):** há um no `raro_shared` (`seconds15`/`seconds30`, usado no Settings) e outro redefinido localmente em `camera_shell_state.dart` (`fifteenSec`/`thirtySec`). Settings usa o canônico. Não unifiquei (fora de escopo — tocaria a câmera já validada). **Débito p/ Sprint 2:** unificar no enum do `raro_shared`.
- **Copy do card Replay em PT:** o protótipo tem esse parágrafo em inglês (inconsistência do próprio HTML); mantive PT-BR por coerência de idioma. Decisão consciente aprovada pelo usuário.
- **Task G (preview/paywall/checkout):** fora de escopo. Deixei stubs `paywall_placeholder`/`preview_placeholder` no router pra os CTAs não darem 404.

## Aprendizados / surpresas

- **`SharedPreferences.getInstance()` é legado em 2026** — o time do Flutter recomenda `SharedPreferencesAsync`/`SharedPreferencesWithCache` desic v2.3.0 (validado Context7 + docs). A `getInstance()` será depreciada.
- **`SharedPreferencesAsync` NÃO é unit-testável sem o `platform_interface`** — provei empiricamente: o test binding não auto-registra um async platform ("instance must be set"), e o `setMockInitialValues` legado não backa a API async (são stores separados). Solução: rotear por port mockável (padrão Repository que o projeto já usava em permissions).
- **Contract test `forbidden_literals` (Family 11) é um guardrail real e útil** — proíbe `Color(0xFF..)` fora de `core/theme/`. Pegou 4 hex que eu tinha hardcodado nas telas. Lição: cores SEMPRE em token de tema, nunca inline em feature.
- **Thumbnails do protótipo são gradientes HSL gerados, não PNGs** — o MD pedia "5 thumbnail PNGs em assets/", mas o HTML usa `hsl()` + `mix-blend-mode:screen`. Replicar com `HSLColor` é mais fiel E evita assets.
- **dart-format hook reflow** durante o commit deixa arquivos `AM` e aborta o commit — precisa re-`git add` + recommitar (aconteceu 2×).

## Próximos passos

- **Sprint 1 Task G** (próxima sessão): Preview (P08, `video_player` — **exige ADR/adendo Blueprint §2 antes**, é dep nova) + Subscription popup (P06) + Paywall (P09) + Checkout (P10) + trial countdown. Substituir os stubs `paywall_placeholder`/`preview_placeholder`.
- Sprint 2 backlog: unificar `BufferDuration` duplicado; migrar pre-existentes pro `SharedPreferencesWithCache` se precisar de leitura síncrona.

## Referências

- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` §"Task F"
- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1 — Sessão de execução"
- Protótipo: `docs/briefing/prototype/Prototipo-RARO.html` (Settings ~993, Gallery ~1160)
- Blueprint §11 atualizado (P07/P08 ✅)
- Commits: `46d9635` (onboarding async), `3f60e18` (settings F1), `423ad35` (gallery F2 + router)
