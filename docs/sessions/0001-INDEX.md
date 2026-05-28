# Sessions Index

> Append-only. Cada nova sessão adiciona uma linha. Mais recente no topo.

| # | Data | Título | Branch | Commits |
|---|---|---|---|---|
| [0005](0005-camera-device-validation.md) | 2026-05-27 → 2026-05-28 | camera device validation (Task 19 — iPhone 12 físico: 11 bugs corrigidos, 4 memórias novas, ADR-0015 addendum A-H, bootstrap permission script, G1-G6 ✅ + G8/G9 debug-only) | `feat/camera-native-bridge` (extensão Task 19, mesma branch) | `17d6d45` … `3e14d8f` (24 commits) |
| [0004](0004-camera-native-bridge.md) | 2026-05-26 / 2026-05-28 | camera-native-bridge (P05 fundação + device validation Task 19: preview + lens 0.5×/1× sem blackout + focus + format + permission flow + observers bg/fg, ADR-0015 com addendum 2026-05-28 seções A-H) | `feat/camera-native-bridge` (validação iPhone 12: G1-G6 ✅, G7/G10 ⏳ Instruments, G4 nativo CALayer, G8/G9 lifecycle real → TestFlight Apple Dev Program) | `6104289` … `62a1c2b` (48 commits) |
| [0003](0003-flutter-3.44-spm-migration.md) | 2026-05-26 | flutter-3.44-spm-migration (upgrade SDK + SPM + iOS 15, ADR-0014) | `feat/flutter-3.44-spm-migration` → merged em `develop` (`d91ccaa`) | `b357d4b` … `d91ccaa` (17 commits) |
| [0002](0002-api-contract-shared.md) | 2026-05-26 | api-contract-shared (rm-2 spec bloqueante, 12 famílias) | `feat/api-contract-shared` | `2783166` … `f30bb1b` (16 commits) |
| [0001](0001-bootstrap.md) | 2026-05-25 | Bootstrap do projeto (Fases 1–5 + 3 sprints de fixes) | `develop` | `c40e55d` … `1c43be0` (33 commits) |

## Próxima sessão sugerida

**Opção A (recomendada)** — `0006` Fechar Task 19 do camera-native-bridge antes de mover:
- Implementar G4 focus ring nativo (CALayer Swift; evita Stack Flutter que quebra hybrid composition)
- Configurar Xcode Instruments para G1 (start ≤500ms) + G7 (memory pre/pós-stop)
- Android Pixel emulator: G2 capabilities + G3 lens switch CameraX
- Marcar spec camera-native-bridge **Done** + merge `feat/camera-native-bridge` → `develop` → `main`

**Opção B** — `0006` Pular para `feat/replay-buffer-native-bridge` (Roadmap rm-8). Reusa CameraSession da spec 0004 + adiciona AVAssetWriter (iOS) + MediaCodec/MediaMuxer (Android) + CVPixelBufferPool / MediaCodec pool. Pré-roll integra com camera-recording futura. Workflow:
  1. `/new-spec replay-buffer-native-bridge`
  2. `superpowers:brainstorming`
  3. Sizing **Large** (novo bridge nativo + ADR)
  4. `/new-plan replay-buffer-native-bridge` + `superpowers:writing-plans`
  5. `superpowers:subagent-driven-development`

**Opção C** — Investir em Apple Developer Program ($99/ano) para fechar G8/G9 lifecycle real em TestFlight. Adiável (próximas 2-3 specs são bridges nativas, sem urgência de release real).

## Como retomar (prompt sugerido)

Cole no início da próxima sessão:

> Vou retomar `feat/camera-native-bridge`. Rode `/prime` para alinhar contexto, leia `docs/sessions/0005-camera-device-validation.md` (último estado) e o ADR-0015 addendum 2026-05-28 seções A-H. Vou seguir [Opção A | B | C] desta seção. Antes de implementar qualquer código: confirma `git status` limpo, valida hipóteses com logs reais (memória `feedback_device_debug_use_real_logs_not_assumptions`), e aplica anti-patterns de CLAUDE.md §11.

## Recovery rápido (se algo quebrar ao retomar)

| Sintoma | Comando |
|---|---|
| Build iOS quebra com "Firebase iOS 15 vs 13" | `bun --filter @raro/mobile run bootstrap:ios` |
| Câmera para de aparecer em Ajustes iPhone | `bun --filter @raro/mobile run bootstrap:ios` + Xcode Clean Build Folder + reinstall |
| Build "BUILD SUCCEEDED" mas app não roda | `xclogparser parse --file <log>.xcactivitylog --reporter flatJson` (ver memória `raro-pattern-xcode-preaction-modifies-workspace`) |
| Xcode "Failed to launch — code signature" em release | Edit Scheme → Run → Build Configuration = **Debug** (free tier não suporta release no device, ver memória `raro-pattern-flutter-debug-vs-release-on-device`) |
| Tela "iOS 14+ debug mode" ao reabrir app no iPhone | **Não é bug**; é restrição arquitetural Apple+Flutter. Use Control Center / multitasking parcial. |
