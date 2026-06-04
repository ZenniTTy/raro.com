# 0011 — Sprint 1 Task D (walking skeleton: P01 splash + P02/P03 onboarding + go_router)

- **Data:** 2026-06-02
- **Duração:** ~longa (3 telas TDD + bundle de fontes + build/install iOS + 2 fixes de fidelidade validados em device)
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `bc5e6ed`, `dce7053`, `7bdf839`, `5e48e2d`, `376a5d4`, `d7bc0c7`, `22e0462` (7 commits; + close 0011)

## Objetivo

Executar Sprint 1 Task D (`SPRINT-1-PROMPTS.md` §"1 — Sessão de execução", `[TASK]=D`): primeiras telas Flutter navegáveis — P01 Splash + P02 Onboarding 1 ("Grave sem tocar") + P03 Onboarding 2 ("Nunca perca o momento") — com go_router e Riverpod 3 providers (impl mock, signature real), fiéis ao protótipo HTML.

## Contexto inicial

- Branch `feat/camera-native-bridge` em `f64be6b`, working tree clean (Tasks A/B/C fechadas; Task C merge segurado).
- `lib/features/` tinha só `camera`; `app.dart` abria direto no `CameraTestHarnessScreen` (flag `RARO_HARNESS=true`), sem go_router, sem ProviderScope no widget root.
- Nenhuma das 12 telas do walking skeleton implementada (todas `[ ]` no Blueprint §11).
- Fontes (Space Grotesk/Inter/JetBrains Mono) e logo NÃO bundlados; `pubspec.yaml` sem seção `assets:`/`fonts:`.

## O que foi feito

- **Mini-audit do MD (commit `bc5e6ed`):** o MD Task D (escrito no Sprint 0) divergia do codebase real. Reconciliado: rotas via contrato canônico `AppScreen` de `raro_shared` (`/splash`, não `/`); logo path corrigido (`raro-logo.png` → `assets/logo/raro_logo.png`); harness sob flag em vez de default; provider reusa `StorageKeys.onboardingCompleted` (não inventa chave); splash nav sai do `initState` solto pro router.
- **3 decisões de design escaladas ao usuário** (AskUserQuestion): logo = copiar PNG existente; fontes = bundlar 3 TTFs agora; harness vs router = router por padrão, harness sob flag.
- **Fontes + logo + tema (commit `dce7053`):** 3 variable fonts (SIL OFL) de `google/fonts` em `assets/fonts/` + OFL licenses; logo raster em `assets/logo/`; `pubspec` registra assets+fonts (VF, eixo wght automático no Flutter 3.44 via breaking change `font-weight-variation`, confirmado no Context7); `RaroFonts` + tema aplica Inter default + Space Grotesk em display/headline; `RaroGradients.rainbow`/`RaroAccents` centralizam os tokens de cor do protótipo §4.2 em `core/theme/` (respeitando o guardrail `forbidden_literals_test` de hex isolation).
- **P01 Splash (commit `7bdf839`):** TDD red→green. `BreathingLogo` (glow), `DotLoader` (3 dots laranja/verde/azul em sequência), tagline "CAPTURE · UNSCRIPTED" mono, `onComplete` callback após 1.8s (nav fica no router, não acoplada).
- **P02/P03 Onboarding (commit `5e48e2d`):** TDD. `OnboardingProgress` provider Riverpod 3 — **`keepAlive: true`** (corrigiu bug de autoDispose, ver Aprendizados) — persiste `onboardingCompleted`. P02 "Grave sem tocar" (mic+halos, wake word "Raro", CTA secundário). P03 "Nunca perca o momento" (buffer waveform viz, CTA primário gradient). Widgets compartilhados: header RARO/Pular, paginação, CTA, mic halo, buffer viz.
- **go_router (commit `376a5d4`):** `buildAppRouter()` com paths canônicos; fluxo splash→onb1→onb2→permissions placeholder testado end-to-end (5 testes nav); `app.dart` vira `MaterialApp.router` por padrão, harness sob `--dart-define=RARO_HARNESS=true`; `smoke_test` segue GREEN.
- **Gate:** `flutter analyze` 0 issues + suíte completa **93/93 GREEN** (sem regressão câmera). 24 testes novos.
- **design-fidelity-checker:** verdict PASS. Copy 100% correto (acentos/em-dashes/middle-dots verificados), cores/tipografia/CTAs corretos. Apontou 1 deviation com significado de design → **fix buffer viz (commit `d7bc0c7`):** P03 buffer agora desenha as 2 camadas de fundo (gradiente de progresso à esquerda + região rainbow "AGORA" a 65%).
- **Validação perceptual no iPhone 12** (build profile assinado + `devicectl install/launch`, workflow §13): usuário aprovou o fluxo. Pegou **glow bruto** no splash → **fix (commit `22e0462`):** `BoxShadow` (projeta o retângulo 220×220 → halo quadrado) trocado por drop-shadow real (2 cópias borradas+tingidas do PNG via `ImageFiltered`+`ColorFiltered srcATop`, seguindo o alpha — logo tem 58% pixels transparentes). Usuário validou "agora sim, ficou fiel".
- **Blueprint §11:** P01/P02/P03 marcados ✅ com nota de validação device.
- **Memória nova:** `raro-pattern-flutter-drop-shadow-vs-boxshadow-png-glow` (indexada em MEMORY.md).

## O que NÃO foi feito (e por quê)

- **Animações 100% fiéis ao protótipo** — o `logoBreathe` usa controller de meio-ciclo (1700ms reverse) em vez de keyframe 0→50→100% (3400ms) e hardcoda a duração em vez de consumir `RaroDurations.logoBreathe`. design-fidelity-checker classificou como cosmético/acceptable; deixado para polish.
- **Logo como SVG vetorial animado** — protótipo e app usam o MESMO PNG raster; a animação interna do gradiente do SVG não existe. Acceptable walking-skeleton.
- **Mic icon custom** — usado `Icons.mic_none_rounded` do Material em vez do SVG do protótipo. Acceptable.
- **P04–P11 + trial countdown** — fora do escopo da Task D (Tasks E/F/G). Permissions é placeholder.
- **Merge da branch** — segue segurada (Task C); não tocada nesta sessão.

## Aprendizados / surpresas

- **`@riverpod` é autoDispose por padrão:** o teste "Avançar avança o provider" falhava (provider voltava a `intro`) porque o widget só fazia `ref.read` (sem `watch`) → nenhum observador → o provider era descartado entre o tap e o assert. Fix correto = `@Riverpod(keepAlive: true)`, que reflete a intenção real (progresso de onboarding é estado de sessão). Não foi gambiarra de teste.
- **drop-shadow CSS ≠ BoxShadow Flutter:** `BoxShadow` projeta a sombra do retângulo do widget (incluindo região transparente) → halo quadrado bruto. Replicar drop-shadow = cópias borradas+tingidas do PNG seguindo o alpha. **Só apareceu em device** (build profile), não nos widget tests (que checam Key, não pixels) — reforça que fidelidade de glow exige olho no device. Memória criada.
- **Erro 74 do Flutter, de novo enganoso:** o build assinado falhou com "error (74)" genérico; o `--verbose` revelou a causa real: `index.lock` órfão no clone SPM do firebase-ios-sdk, deixado por um `flutter build` que EU interrompi (TaskStop) no meio da resolução git. Fix = remover só o `.lock` (não o cache). Systematic-debugging (log real antes de fix) evitou apagar o cache à toa.
- **"paired" ≠ "conectado":** `devicectl`/`flutter devices` listam o iPhone do cache de pareamento mesmo desconectado. O sinal de conexão ativa real é `idevice_id -l` (libimobiledevice só lista devices realmente plugados).
- **Variable fonts no Flutter 3.44:** 1 arquivo VF por família basta; `FontWeight.w400..w700` ajusta o eixo wght automaticamente (breaking change `font-weight-variation`). Não precisa declarar `weight:` por peso.
- **Commit subject-case:** `keepAlive` no subject quebrou o commitlint (exige lowercase) → `keepalive`. Também usei scope `onboarding` no commit do splash quando `splash` existe no enum — impreciso, não amendado (regra: novo commit, não amend).

## Próximos passos

- **Sprint 1 Task E — Permissions (P04) + Camera UI shell (P05)** (`sprint-1-foundation-walking-skeleton.md` §Task E). Substitui o `_PermissionsPlaceholder` por tela real (permission_handler) e implementa o HUD da câmera fiel ao protótipo. Cole `SPRINT-1-PROMPTS.md` §"1 — Sessão de execução", `[TASK]=E`.
- **Polish deferido (backlog):** wirar `logoBreathe` ao token `RaroDurations` + keyframe full-cycle; logo SVG vetorial se quiser a animação interna do gradiente.

## Referências

- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1 — Sessão de execução"
- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` (Task D, reconciliado nesta sessão)
- Protótipo: `docs/briefing/prototype/Prototipo-RARO.html` (screenSplash 697, screenOnb1 710, screenOnb2 742)
- Commits: `bc5e6ed` (md fix), `dce7053` (fonts/theme), `7bdf839` (splash), `5e48e2d` (onboarding), `376a5d4` (router), `d7bc0c7` (buffer fix), `22e0462` (glow fix)
- Memória nova: `raro-pattern-flutter-drop-shadow-vs-boxshadow-png-glow` (índice em MEMORY.md)
- Blueprint §11: P01/P02/P03 ✅
