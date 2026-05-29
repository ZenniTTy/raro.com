# Sessions Index

> Append-only. Cada nova sessão adiciona uma linha. Mais recente no topo.

| # | Data | Título | Branch | Commits |
|---|---|---|---|---|
| [0006](0006-camera-task-19-focus-perf.md) | 2026-05-28 → 2026-05-29 | camera task 19 focus + perf (G4 focus ring nativo via CALayer + 5 root causes tap-to-focus delay no iPhone 12 colapsados: smoothAutoFocus, debounce 100→16ms, EagerGestureRecognizer, KVO permanente, setNeedsDisplay; terminal-first iOS workflow §13; 3 workflows audit ~60 agents 2.6M tokens; ADR-0016 harness E2E híbrido Proposed; decisão $99 Apple Dev em 30d) | `feat/camera-native-bridge` (extensão Task 19, mesma branch) | `cba16ce` … `3b79021` (6 commits) |
| [0005](0005-camera-device-validation.md) | 2026-05-27 → 2026-05-28 | camera device validation (Task 19 — iPhone 12 físico: 11 bugs corrigidos, 4 memórias novas, ADR-0015 addendum A-H, bootstrap permission script, G1-G6 ✅ + G8/G9 debug-only) | `feat/camera-native-bridge` (extensão Task 19, mesma branch) | `17d6d45` … `3e14d8f` (24 commits) |
| [0004](0004-camera-native-bridge.md) | 2026-05-26 / 2026-05-28 | camera-native-bridge (P05 fundação + device validation Task 19: preview + lens 0.5×/1× sem blackout + focus + format + permission flow + observers bg/fg, ADR-0015 com addendum 2026-05-28 seções A-H) | `feat/camera-native-bridge` (validação iPhone 12: G1-G6 ✅, G7/G10 ⏳ Instruments, G4 nativo CALayer, G8/G9 lifecycle real → TestFlight Apple Dev Program) | `6104289` … `62a1c2b` (48 commits) |
| [0003](0003-flutter-3.44-spm-migration.md) | 2026-05-26 | flutter-3.44-spm-migration (upgrade SDK + SPM + iOS 15, ADR-0014) | `feat/flutter-3.44-spm-migration` → merged em `develop` (`d91ccaa`) | `b357d4b` … `d91ccaa` (17 commits) |
| [0002](0002-api-contract-shared.md) | 2026-05-26 | api-contract-shared (rm-2 spec bloqueante, 12 famílias) | `feat/api-contract-shared` | `2783166` … `f30bb1b` (16 commits) |
| [0001](0001-bootstrap.md) | 2026-05-25 | Bootstrap do projeto (Fases 1–5 + 3 sprints de fixes) | `develop` | `c40e55d` … `1c43be0` (33 commits) |

## Próxima sessão (Sessão 2 — validação perceptual + harness E2E híbrido)

**Objetivo combinado:**

1. **Opção B (destrava merge)** — Validar perceptualmente no iPhone 12 físico que o tap-to-focus está <50ms ring + <300ms settle após os 5 fixes da Sessão 0006. Se OK, fechar G4 formalmente, atualizar status da spec `2026-05-28-camera-task-19-closure-design.md` para `Done`, escrever ADR-0015 addendum I (5 fixes), mergear `feat/camera-native-bridge` → `develop`.
2. **Opção A (em paralelo)** — Implementar primeira camada do harness E2E híbrido descrito em [ADR-0016](../decisions/0016-e2e-harness-hybrid.md) + spec [`2026-05-29-e2e-harness-hybrid-design.md`](../superpowers/specs/2026-05-29-e2e-harness-hybrid-design.md): toolchain local (Maestro CLI + go-ios + pymobiledevice3) + Pigeon `CameraDebugHostApi` + rota `/debug/self-test` (kDebugMode) + primeiro `integration_test camera_tap_to_focus_test.dart` rodando em ~90s no iPhone 12.

**Opção C (paralelo, sem bloqueio)** — Iniciar `feat/replay-buffer-native-bridge` (Roadmap rm-8). Workflow: `/new-spec replay-buffer-native-bridge` → `superpowers:brainstorming` → Sizing **Large** → `/new-plan` → `superpowers:writing-plans` → `superpowers:subagent-driven-development`. Pode esperar Sessão 3 ou 4 (Camera 19 ainda não merged).

**Opção D (defer 30d)** — Upgrade Patrol após Apple Dev Program ($99/ano) pago, conforme ADR-0016. Cobre Volume bridge + permission dialog real automation.

## Como retomar (prompt sugerido)

Cole no início da próxima sessão:

> Sessão 2 do RARO. Branch `feat/camera-native-bridge`. Ler em ordem: `docs/sessions/0006-camera-task-19-focus-perf.md`, `docs/decisions/0016-e2e-harness-hybrid.md`, `docs/superpowers/specs/2026-05-29-e2e-harness-hybrid-design.md`, `CLAUDE.md §10-§13`. Objetivos da sessão: (a) destravar merge fazendo validação perceptual no iPhone 12 e atualizando spec/ADR, (b) iniciar implementação do harness E2E híbrido pela camada 1 (toolchain local + Pigeon `CameraDebugHostApi` + rota `/debug/self-test`). Rodar `/prime` primeiro.

## Recovery rápido (se algo quebrar ao retomar)

| Sintoma | Comando |
|---|---|
| Build iOS quebra com "Firebase iOS 15 vs 13" | `bun --filter @raro/mobile run bootstrap:ios` |
| Câmera para de aparecer em Ajustes iPhone | `bun --filter @raro/mobile run bootstrap:ios` + Xcode Clean Build Folder + reinstall |
| Build "BUILD SUCCEEDED" mas app não roda | `xclogparser parse --file <log>.xcactivitylog --reporter flatJson` (ver memória `raro-pattern-xcode-preaction-modifies-workspace`) |
| Xcode "Failed to launch — code signature" em release | Edit Scheme → Run → Build Configuration = **Debug** (free tier não suporta release no device, ver memória `raro-pattern-flutter-debug-vs-release-on-device`) |
| Tela "iOS 14+ debug mode" ao reabrir app no iPhone | **Não é bug**; é restrição arquitetural Apple+Flutter. Use Control Center / multitasking parcial. |
