# Sessions Index

> Append-only. Cada nova sessão adiciona uma linha. Mais recente no topo.

| # | Data | Título | Branch | Commits |
|---|---|---|---|---|
| [0004](0004-camera-native-bridge.md) | 2026-05-26 | camera-native-bridge (P05 fundação: preview + lens 0.5×/1× + focus + format, ADR-0015) | `feat/camera-native-bridge` (device test G1-G10 pendente — Task 19 aguarda iPhone 12) | `6104289` … `e013d6f` (25 commits) |
| [0003](0003-flutter-3.44-spm-migration.md) | 2026-05-26 | flutter-3.44-spm-migration (upgrade SDK + SPM + iOS 15, ADR-0014) | `feat/flutter-3.44-spm-migration` → merged em `develop` (`d91ccaa`) | `b357d4b` … `d91ccaa` (17 commits) |
| [0002](0002-api-contract-shared.md) | 2026-05-26 | api-contract-shared (rm-2 spec bloqueante, 12 famílias) | `feat/api-contract-shared` | `2783166` … `f30bb1b` (16 commits) |
| [0001](0001-bootstrap.md) | 2026-05-25 | Bootstrap do projeto (Fases 1–5 + 3 sprints de fixes) | `develop` | `c40e55d` … `1c43be0` (33 commits) |

## Próxima sessão sugerida

- **0005** — `feat/replay-buffer-native-bridge` (Roadmap rm-8). Reusa CameraSession da spec 0004 + adiciona AVAssetWriter (iOS) + MediaCodec/MediaMuxer (Android) + CVPixelBufferPool / MediaCodec pool. Pré-roll integra com camera-recording futura. Workflow:
  1. `/new-spec replay-buffer-native-bridge`
  2. `superpowers:brainstorming`
  3. Sizing **Large** (novo bridge nativo + ADR)
  4. `/new-plan replay-buffer-native-bridge` + `superpowers:writing-plans`
  5. `superpowers:subagent-driven-development`
