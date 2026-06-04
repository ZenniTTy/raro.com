# 0010 — Sprint 1 Task C (camera merge: validação G4 focus ring no iPhone 12)

- **Data:** 2026-06-01
- **Duração:** ~longa (debug iterativo + 3 bugs empilhados + bloqueios de ambiente)
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `8d4a5d9`, `b8b9a01`, `42bb901` (3 commits; + `366b13b` close 0009 no início)

## Objetivo

Executar Sprint 1 Task C ("1 — Sessão de execução" de `SPRINT-1-PROMPTS.md`, `[TASK]=C`): validação perceptual do focus ring (G4) no iPhone 12 físico → marcar spec `camera-task-19-closure-design` Done → merge `feat/camera-native-bridge` → `develop`. Pre-flight pedido pelo usuário: iPhone 12 conectado para tap-to-focus manual.

## Contexto inicial

- Branch `feat/camera-native-bridge` em `366b13b` (após commit do close da sessão 0009, que estava unstaged).
- iPhone 12 conectado (USB, iOS 26.5), confirmado por `flutter devices` + `devicectl` + `idevice_id`.
- Spec camera-task-19 em `In implementation — partial`; 5 fixes da sessão 0006 em código mas nunca exercidos perceptualmente.

## O que foi feito

- **Erro inicial de leitura de ferramenta:** primeiro comando encadeou device-check que travou e bloqueou o canal de saída → interpretei "vazio" como "arquivos não existem" e disparei AskUserQuestion com premissa falsa. Usuário corrigiu ("como não existe?"). Lição reforçada nos Aprendizados.
- **Desbloqueio de build iOS (3 camadas, todas diagnosticadas com log real):**
  1. `bun --filter X run` (CLAUDE.md §13) falha → forma correta `bun run --filter X` (memória `raro-pattern-bun-filter-arg-order`).
  2. SPM "Could not resolve package dependencies" → sandbox injeta `safe.bareRepository=explicit` + bloqueia `protocol.file.allow`; fix `GIT_CONFIG_COUNT=2` com os 2 overrides (memória `raro-pattern-spm-safe-bare-repository-sandbox`). Provado por `xcodebuild -resolvePackageDependencies` EXIT 0.
  3. `flutter run` debug dá erro 74 no deploy (Xcode 26/CoreDevice, Flutter #179234) + debug não roda standalone ("iOS 14+ debug mode") → usar `flutter build ios --profile` + `devicectl install/launch` (roda standalone). Também: `SourcePackages` local com packfile corrompido (`bad object`) → `rm -rf build/ios/SourcePackages`.
- **BUG focus ring — 3 root causes empilhados** (cada um diagnosticado por workflow multi-agente de 3 ângulos + WebSearch/Context7, refs Apple/objc.io), commit `8d4a5d9`:
  1. **opacity invisível:** `ring.opacity=0` model + `CAAnimation removedOnCompletion=true` → presentation revertia pro model (0). Fix: opacity model=1, keyframes `[1,1,0]`, `fillMode .forwards`, `isRemovedOnCompletion=false`.
  2. **tap caía no vão (re-arquitetura):** `EagerGestureRecognizer` entrega o tap à view nativa, mas a nativa não escutava; `GestureDetector` Flutter pai nunca disparava. Fix: `UITapGestureRecognizer` na `CameraPreviewContainerView` (tap nativo → `showFocusRing` + `focusAtAsync`); `GestureDetector` Dart removido; Eager mantido; manager wiring via factory.
  3. **ring vinha do canto:** `CAShapeLayer` bounds zero + path absoluto → `transform.scale` ancorava em (0,0). Fix: `layer.bounds` próprio + `position` no ponto + path centrado em (0,0).
- **Validação no device:** usuário confirmou "agora sim, perfeito" — ring instantâneo, centrado no tap, fade. **G4 fechado (iOS).**
- **TDD:** teste RED `testShowFocusRingIsVisibleWhileAnimating` (provou opacity=0) → GREEN após fix; + `testShowFocusRingOpacityAnimationFreezesAtEnd`; widget test atualizado (tap nativo, não chama `focusAt` Dart). `flutter analyze` GREEN, widget tests GREEN.
- **Memórias (5):** `raro-pattern-bun-filter-arg-order`, `raro-pattern-spm-safe-bare-repository-sandbox`, `raro-pattern-calayer-opacity-zero-model-invisible`, `raro-pattern-flutter-platformview-tap-must-be-native`, `raro-pattern-calayer-scale-anchor-zero-bounds` — todas indexadas em MEMORY.md.
- **Harness (commit `b8b9a01`):** CLAUDE.md §13 corrigida (9 ocorrências bun + 3 guardrails: bun filter, SPM 2-gate, profile build); §8 8→9 hooks; novo hook `warn-gesturedetector-over-platformview.sh` (avisa GestureDetector sobre UiKitView com Eager) registrado em settings.json.
- **Docs (commit `42bb901`):** spec camera-task-19 + Blueprint §11 com status honesto (G4 validado, gates deferidos listados, merge segurado).

## O que NÃO foi feito (e por quê)

- **Merge `feat/camera-native-bridge` → `develop` SEGURADO** (decisão do usuário). A branch tem 80 commits ahead de develop e 12 unpushed; spec ainda tem gates abertos. Mergear consolidaria trabalho parcial. Os fixes estão commitados na branch (salvos), não pushed.
- **Spec NÃO marcada "Done"** — só G4 (iOS) validado. Gates G1/G7 (perf), G2b/G3b/G4g/G5b/G6b (Android Samsung M54), goldens (actool trava no Xcode 26) seguem abertos → Sprint 2/3 (alinhado roadmap Blueprint §11). Marcar Done seria desonesto.
- **Android tap-to-focus quebrou temporariamente** — remover o `GestureDetector` Dart deixou o Android sem input de tap até instalar `setOnTouchListener`/GestureDetector na `PreviewView` Kotlin. Backlog Sprint 3 (decisão do usuário). Sprint 1 é iOS-only.
- **XCTest nativo (RunnerTests) não rodou** — `actool` (asset catalog compiler) trava no Xcode 26 local (15min+). Os fixes Swift foram validados por: build profile GREEN + validação manual no device. Goldens/XCTest completos via CI futuro.
- **Push não feito** — ação outward, aguarda pedido.

## Aprendizados / surpresas

- **Vazio de ferramenta ≠ "não existe":** um device-check travado bloqueou o canal e fez vários `find`/`ls` voltarem vazios; interpretei como ausência de arquivos e quase agi sobre premissa falsa. Sempre confirmar com comando isolado antes de concluir ausência.
- **"Erro 74" do Flutter é genérico e enganoso:** mascarava 3 causas diferentes em momentos diferentes (git sandbox, SourcePackages corrompido, debug standalone). O log verbose (`--verbose`) + `xcodebuild -resolvePackageDependencies` isolado revelaram a causa real cada vez. Nunca tratar "erro 74" como uma coisa só.
- **Validação perceptual virou debug de bug real:** o que o plano chamava de "validar tela pronta" era na verdade 3 bugs empilhados. Aplicar `systematic-debugging` (root cause antes de fix) + TDD (RED antes de GREEN) + workflows adversariais de 3 ângulos evitou fixes especulativos (descartei "race de ordem" e "sibling UIView" com evidência).
- **Ambiente Xcode 26/macOS Tahoe é hostil a automação:** `flutter run` (CoreDevice #179234), `actool` (trava), debug standalone (bloqueado), SPM (git sandbox). Profile build + devicectl é o caminho que funciona neste setup.
- **Memória pessoal vs harness versionado são lugares diferentes:** padrões hyper-específicos → memória (`~/.claude/`); guardrails de processo que ajudam o próximo dev → CLAUDE.md/hooks (git). O critério §11 (Task B) guia a separação.

## Próximos passos

- **Sprint 1 Task D — Walking skeleton: Splash + Onboarding 1 + Onboarding 2** (`sprint-1-foundation-walking-skeleton.md` §Task D). Primeiras telas Flutter navegáveis com Riverpod providers.
- **Quando retomar camera (Sprint 2):** fechar gates deferidos (G1/G7 perf via integration_test + Pigeon `CameraDebugHostApi` ADR-0016), depois merge `feat/camera-native-bridge` → `develop`.
- **Sprint 3:** instalar tap-to-focus nativo Android (CameraX/Kotlin) — backlog registrado.
- **Opcional:** push da branch pra backup remoto (12 commits unpushed).

## Referências

- Prompts: `docs/superpowers/plans/SPRINT-1-PROMPTS.md` §"1 — Sessão de execução"
- Plan: `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` (Task C)
- Spec: `docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md` (§progresso Sprint 1.C)
- Commits: `8d4a5d9` (fix camera), `b8b9a01` (harness), `42bb901` (docs)
- Memórias novas (5): índice em MEMORY.md (fora do repo)
- Flutter issue #179234 (flutter run Xcode 26 CoreDevice), refs Apple/objc.io (CAAnimation model vs presentation layer)
