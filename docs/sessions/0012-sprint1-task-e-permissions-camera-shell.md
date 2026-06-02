# 0012 — Sprint 1 Task E (walking skeleton: P04 Permissions + P05 Camera UI shell)

- **Data:** 2026-06-02
- **Duração:** ~média (2 telas via TDD + design-fidelity + 2 fixes de fidelidade + 2 memórias)
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `2c75f4a`, `9c76877`, `900efd7`, `d5a2406` (+ close 0012)

## Objetivo

Executar Sprint 1 Task E (`SPRINT-1-PROMPTS.md` §"1 — Sessão de execução", `[TASK]=E`): substituir o `_PermissionsPlaceholder` por P04 real (câmera + mic via `permission_handler`) e implementar o Camera UI shell P05 fiel ao protótipo (HUD res/fps/lens, REC button mockado + timer fake, buffer pill, lens switcher), Riverpod 3 com signature swap-able pra Sprint 2.

## Contexto inicial

- Branch em `cfd920a`, working tree clean (Tasks A/B/C/D fechadas; Task C merge segurado).
- Router (`app/router.dart`) abria splash→onb1→onb2→`_PermissionsPlaceholder` (Key `permissions_placeholder`); `/camera` não existia como rota (só o `CameraTestHarnessScreen` sob flag `RARO_HARNESS`).
- Bridge de câmera real já existia (Task C): `cameraControllerProvider`, `CameraSettings`, `LensType`, `CameraPreviewWidget` (UiKitView), `LensChipRow`.
- 93 testes GREEN no fim da Task D.

## O que foi feito

- **2 decisões de arquitetura escaladas ao usuário (AskUserQuestion), ANTES de codar:**
  - **Preview P05 = mock visual** (fundo escuro + rule-of-thirds + grão via CustomPainter), NÃO inicializa `AVCaptureSession`. Preview nativo real fica pra Sprint 2. Testável em qualquer device, sem permissão.
  - **REC = inline** (indicador 00:00:00 + botão pulsa + hint some), sem navegar pro Lock mode (P05a fora do §Task E).
- **Reconciliação do MD (mesmo padrão Task D):** o §E2 dizia "lens switch chama bridge real (já funciona)" — com preview mock não há sessão pra trocar, então o lens switcher atualiza estado Riverpod local + HUD. O `PermissionStatusRef` do exemplo do MD não existe no Riverpod 3 codegen (usa `Ref`). O `Recording.idle()/active()` freezed union do exemplo virou um `CameraShellState` (data class) real.
- **E1 — P04 Permissions (commit `2c75f4a`):** TDD red→green. `PermissionGateway` (port abstrato) + `PermissionHandlerGateway` (impl real) — mesmo padrão ports do camera feature, permite override com fake nos widget tests (mocktail). `permissionStatusProvider` (FutureProvider) + `PermissionController` (Notifier keepAlive). `PermissionsScreen` fiel ao protótipo: section-label "PASSO 1 DE 1" (grad-text ShaderMask), h1 "Permissões essenciais", 2 cards (Câmera/Microfone), CTA "Continuar" gradient → `/camera` quando ambas concedidas. 12 testes (6 provider + 6 widget). Router wirado + 2 nav tests do router_test atualizados (placeholder → tela real) + 1 novo (granted → camera). Placeholder `/camera` temporário pra E1 não dar 404.
- **E2 — P05 Camera shell (commit `9c76877`):** TDD. `CameraShellState` (freezed data class) + `BufferDuration` enum + `CameraShell` notifier (toggleRecording/selectLens/toggleBufferDuration) — 7 testes provider. Widgets fiéis: `RecButton` (72px red → black+ring+square pulsante), `BufferPill` (top-right mono + dot pulsante), `HudInfoBar`/`RecIndicator`/`CameraCenterHint` (`hud_overlay.dart`), `LensSwitcher` (chips). `camera_screen.dart` compõe top bar (close→/permissions, "RARO") + viewport mock + bottom controls (gallery/REC/settings + grad-line). Timer fake (`Timer.periodic` 1s) no REC. 7 testes smoke. Router: `/camera` real + stubs `/settings` e `/gallery` (Task F substitui) + 2 nav tests.
- **Best-practices validadas via Context7 + WebSearch (a pedido do usuário):** Riverpod 3 Notifier-com-codegen + state imutável + copyWith = padrão canônico 2026 confirmado (`/rrousselgit/riverpod`). Animação dirigida por prop: `didUpdateWidget` (reagir a prop) + `FadeTransition`/`AnimatedBuilder` (rebuild sem setState manual) — meu uso já alinhado (Flutter docs).
- **design-fidelity-checker (subagent):** verdict PASS-WITH-DEVIATIONS. Copy exato (acentos, aspas curvas, ·), cores/tipografia/gradientes corretos, zero "OkCamera". Apontou 2 deviations com significado de design → **fix (commit `900efd7`):** (1) HUD `#hudLens` no protótipo usa ASCII `1x`/`0.5x` (chips usam `×`) → adicionei `hudLensLabel` (ASCII) separado de `lensLabel` (×); (2) buffer pill no protótipo é sempre `.pill.active` (white bg/black text, `bufferEnabled:true` "Raro Replay sempre ativo") → troquei o estado de repouso pro chip branco. Verifiquei ambos no HTML antes de aplicar (não corrigi cego).
- **Gate:** `flutter analyze` 0 issues + suíte **122/122 GREEN** (era 93; +29 testes; sem regressão câmera/onboarding). `forbidden_literals_test` (hex isolation) passa — removi um `Color(0xFF080808)` → `colors.bgDeep`.
- **Blueprint §11 (commit `d5a2406`):** P04 + P05 marcados ✅ com nota de mock/device-pending.
- **2 memórias novas** (indexadas em MEMORY.md): `raro-pattern-flutter-late-final-animationcontroller-dispose-crash` + `raro-pattern-flutter-pumpandsettle-infinite-animation-timeout`.

## O que NÃO foi feito (e por quê)

- **Validação perceptual no iPhone 12** — Task D validou em device; aqui o gate do §Task E é widget test + design-fidelity (ambos feitos). Validação device do fluxo completo é a Task H (smoke test fim-a-fim). Não buildei pro device nesta sessão.
- **Preview nativo no P05** — decisão explícita do usuário: mock no walking skeleton; UiKitView + `cameraControllerProvider` real são Sprint 2.
- **Lock mode P05a** — fora do §Task E (REC inline). Aparece no smoke test da Task H.
- **HUD com valores reais de settings** — "1080p · 60FPS" são mock fixos; Task F (Settings) liga os valores reais via provider.
- **Lens switch chamando o bridge nativo** — sem sessão ativa no mock; é estado local. Sprint 2 liga ao `switchLens()` real quando o preview existir.
- **Settings (P06) e Gallery (P07)** — stubs placeholder reachable da câmera; telas reais são Task F.
- **3 deviations cosméticas** (stops explícitos do gradient, anel preto 2px do REC, backdrop-blur das pills) — sem significado de design; deixadas pra polish/golden (Sprint 3).

## Aprendizados / surpresas

- **`late final AnimationController` lazy crasha se o 1º acesso for no `dispose()`** — "Looking up a deactivated widget's ancestor is unsafe". O `RecButton` idle nunca tocava o controller até o dispose; o Ticker precisa de State ativo. Fix: criar em `initState` (eager). Memória criada — vale pra todo widget animado.
- **`pumpAndSettle` dá timeout em tela com `repeat()` infinito** (buffer pill pulsa pra sempre). Os nav tests do router travaram. Fix: `pump()` bounded (`pump()` + `pump(400ms)`) em vez de settle; asserts de presença não precisam settle. Memória criada.
- **Hex isolation pega cedo:** o `forbidden_literals_test` falhou por um `Color(0xFF080808)` na tela — hex tem que viver em `core/theme/`. Usei `colors.bgDeep`. Bom guardrail.
- **commit + format hook:** o primeiro commit do E2 falhou (`exit 1`) porque o `dart-format` reformatou 4 arquivos staged → snapshot stale. Re-`git add` + re-commit resolveu (hook é idempotente na 2ª). Não usei `--no-verify`.
- **design-fidelity como gate de verdade:** o subagent pegou 2 desvios reais de leitura do protótipo (ASCII x, pill active) que os widget tests não pegariam — eles checam presença de texto/Key, não o glifo exato nem a cor de fundo. Reforça o §10 do CLAUDE.md.

## Próximos passos

- **Sprint 1 Task F — Settings (P06) + Gallery (P07)** (`sprint-1-foundation-walking-skeleton.md` §Task F). Substitui os stubs `/settings` e `/gallery` por telas reais: Settings com `RecordingSettings` (freezed) persistido em shared_preferences; Gallery com 5-6 `VideoEntity` mock em grid + filtros. **Pré-requisito Task G:** `video_player` é dep nova → exige ADR/adendo Blueprint §2 ANTES da Task G (não da F). Cole `SPRINT-1-PROMPTS.md` §"1 — Sessão de execução", `[TASK]=F`.
- **Device validation deferida:** P04/P05 só foram validados por widget test + design-fidelity; validação perceptual no iPhone 12 acontece no smoke test fim-a-fim da Task H.

## Referências

- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1 — Sessão de execução"
- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` (Task E)
- Protótipo: `docs/briefing/prototype/Prototipo-RARO.html` (screenPerms 784-812, screenCamera 825-963, tokens 12-25)
- Commits: `2c75f4a` (P04), `9c76877` (P05), `900efd7` (fidelity fix), `d5a2406` (blueprint)
- Memórias novas: `raro-pattern-flutter-late-final-animationcontroller-dispose-crash`, `raro-pattern-flutter-pumpandsettle-infinite-animation-timeout` (índice em MEMORY.md)
- Blueprint §11: P04/P05 ✅
