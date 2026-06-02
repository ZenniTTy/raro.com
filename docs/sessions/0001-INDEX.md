# Sessions Index

> Append-only. Cada nova sessão adiciona uma linha. Mais recente no topo.

| # | Data | Título | Branch | Commits |
|---|---|---|---|---|
| [0010](0010-sprint1-task-c-camera-focus-ring.md) | 2026-06-01 | Sprint 1 Task C (camera G4: focus ring validado no iPhone 12 — 3 bugs empilhados corrigidos via systematic-debugging + TDD + workflows 3-ângulos: opacity model=0 invisível, tap caindo no vão → re-arquitetado pro nativo (UITapGestureRecognizer), ring vindo do canto (anchor/bounds); + desbloqueio build iOS sandbox (bun filter, SPM 2-gate git override, profile vs debug); 5 memórias + hook novo + CLAUDE.md §13/§8. **Merge SEGURADO** — gates G1/G7 perf + Android M54 + goldens → Sprint 2/3) | `feat/camera-native-bridge` | `8d4a5d9`, `b8b9a01`, `42bb901` (3 commits) |
| [0009](0009-sprint1-task-b-workflow-refactor.md) | 2026-05-29 | Sprint 1 Task B (workflow refactor: CLAUDE.md §6 → "1 sessão = 1 entregável"; §11 cortada 29→11 por critério, 18 viram memória/hook + 1 memória nova Pigeon; Blueprint §11 roadmap 3-Sprint com checkboxes reais; session 0007 retroativo criado) | `feat/camera-native-bridge` | `8292ded`, `8442dea` (2 commits) |
| [0008](0008-sprint1-task-a-cleanup.md) | 2026-05-29 | Sprint 1 Kickoff + Task A (audit FASE 1–4 de 26 deps/APIs via Context7+WebSearch + 6 telas de gate; MD audit fixes; cleanup: 6 memórias renomeadas consertando índice, multicam mantido p/ não quebrar refs em docs, §8 → 9 hooks reais; 0007 reservado p/ Sprint-0 reset retroativo na Task B) | `feat/camera-native-bridge` | `7608c59`, `4f9085e` (2 commits) |
| [0007](0007-sprint0-reset-roadmap-workflow.md) | 2026-05-29 | sprint 0: master plan v2 + 3 sprint MDs (reset estratégico — Fases v1 → 3-Sprint; cleanup com critério; Riverpod providers vs MockData; free Apple ID até Sprint 3) | `feat/camera-native-bridge` | `06ec0fb`…`1160c9f` (4 commits) |
| [0006](0006-camera-task-19-focus-perf.md) | 2026-05-28 → 2026-05-29 | camera task 19 focus + perf (G4 focus ring nativo via CALayer + 5 root causes tap-to-focus delay no iPhone 12 colapsados: smoothAutoFocus, debounce 100→16ms, EagerGestureRecognizer, KVO permanente, setNeedsDisplay; terminal-first iOS workflow §13; 3 workflows audit ~60 agents 2.6M tokens; ADR-0016 harness E2E híbrido Proposed; decisão $99 Apple Dev em 30d) | `feat/camera-native-bridge` (extensão Task 19, mesma branch) | `cba16ce` … `3b79021` (6 commits) |
| [0005](0005-camera-device-validation.md) | 2026-05-27 → 2026-05-28 | camera device validation (Task 19 — iPhone 12 físico: 11 bugs corrigidos, 4 memórias novas, ADR-0015 addendum A-H, bootstrap permission script, G1-G6 ✅ + G8/G9 debug-only) | `feat/camera-native-bridge` (extensão Task 19, mesma branch) | `17d6d45` … `3e14d8f` (24 commits) |
| [0004](0004-camera-native-bridge.md) | 2026-05-26 / 2026-05-28 | camera-native-bridge (P05 fundação + device validation Task 19: preview + lens 0.5×/1× sem blackout + focus + format + permission flow + observers bg/fg, ADR-0015 com addendum 2026-05-28 seções A-H) | `feat/camera-native-bridge` (validação iPhone 12: G1-G6 ✅, G7/G10 ⏳ Instruments, G4 nativo CALayer, G8/G9 lifecycle real → TestFlight Apple Dev Program) | `6104289` … `62a1c2b` (48 commits) |
| [0003](0003-flutter-3.44-spm-migration.md) | 2026-05-26 | flutter-3.44-spm-migration (upgrade SDK + SPM + iOS 15, ADR-0014) | `feat/flutter-3.44-spm-migration` → merged em `develop` (`d91ccaa`) | `b357d4b` … `d91ccaa` (17 commits) |
| [0002](0002-api-contract-shared.md) | 2026-05-26 | api-contract-shared (rm-2 spec bloqueante, 12 famílias) | `feat/api-contract-shared` | `2783166` … `f30bb1b` (16 commits) |
| [0001](0001-bootstrap.md) | 2026-05-25 | Bootstrap do projeto (Fases 1–5 + 3 sprints de fixes) | `develop` | `c40e55d` … `1c43be0` (33 commits) |

## Próxima sessão (Sprint 1 Task D — Walking skeleton: Splash + Onboarding)

Primeiras telas Flutter navegáveis: P01 Splash + P02 Onboarding 1 ("Grave sem tocar") + P03 Onboarding 2 ("Nunca perca o momento"), com Riverpod 3 providers (impl mock, signature real) + go_router. Detalhe em `docs/superpowers/plans/sprint-1-foundation-walking-skeleton.md` §"Task D". Cole `SPRINT-1-PROMPTS.md` §"1 — Sessão de execução" com `[TASK]=D`.

> **Task C (camera G4) parcialmente fechada na sessão 0010:** focus ring iOS validado em device. **Merge segurado** — gates G1/G7 (perf) + Android M54 + goldens deferidos pra Sprint 2/3 (ver spec `2026-05-28-camera-task-19-closure-design.md` §progresso). Branch `feat/camera-native-bridge` NÃO mergeada em `develop` (pushed pra origin em 2026-06-01, sincronizada). Backlog Sprint 3: tap-to-focus nativo Android (CameraX/Kotlin).

> **Nota (Sprint 0 reset):** as antigas "Opções A/C/D" (harness E2E híbrido, replay buffer, Patrol) viraram backlog de Sprint 2/3 no roadmap (Blueprint §11). Sprint 1 foca cleanup + walking skeleton iOS. ADR-0016 e a spec do harness E2E continuam válidos como referência para Sprint 2.

## Como retomar (prompt sugerido)

Cole no início da próxima sessão (de `SPRINT-1-PROMPTS.md` §"1 — Sessão de execução", `[TASK]` = C):

> Sessão Sprint 1 — Task C. CONTEXTO: Sprint 1 já passou pelo Kickoff (audit FASE 1-4) e Tasks A/B. Esta sessão executa apenas Task C. Setup: `/prime` → `git log`/`status` → ler `sprint-1-foundation-walking-skeleton.md` §"Task C" + "Riscos conhecidos" + "Out of scope" → mini-audit. Execução: Task C step-by-step, **confirme destrutivos (merge, `git branch -d`) antes**. Closure: `/session-end` → próximo objetivo "Sprint 1 Task D". Guardrails idem Kickoff.

## Recovery rápido (se algo quebrar ao retomar)

| Sintoma | Comando |
|---|---|
| Build iOS quebra com "Firebase iOS 15 vs 13" | `bun --filter @raro/mobile run bootstrap:ios` |
| Câmera para de aparecer em Ajustes iPhone | `bun --filter @raro/mobile run bootstrap:ios` + Xcode Clean Build Folder + reinstall |
| Build "BUILD SUCCEEDED" mas app não roda | `xclogparser parse --file <log>.xcactivitylog --reporter flatJson` (ver memória `raro-pattern-xcode-preaction-modifies-workspace`) |
| Xcode "Failed to launch — code signature" em release | Edit Scheme → Run → Build Configuration = **Debug** (free tier não suporta release no device, ver memória `raro-pattern-flutter-debug-vs-release-on-device`) |
| Tela "iOS 14+ debug mode" ao reabrir app no iPhone | **Não é bug**; é restrição arquitetural Apple+Flutter. Use Control Center / multitasking parcial. |
