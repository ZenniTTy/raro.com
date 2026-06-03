# 0016 — Sprint 2 Task A (S2.A): Recording real + Vault

- **Data:** 2026-06-03
- **Duração:** ~5h
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `0eadcb9` (plan) → `f4e5a53` (17 commits): `d89b933`, `e9bae45`, `3b6727d`, `c03c574`, `a3880f8`, `31df735`, `97bfd9d`, `a651f57`, `c8a29de`, `7b444bd`, `0c333ac`, `fe7a672`, `8b7a492`, `b4c6944`, `8cb6960`, `f4e5a53`

## Objetivo

Primeiro entregável fechado do Sprint 2 (CLAUDE.md §6 — 1 sessão = 1 entregável): Task A completa (A1→A4) — Pigeon start/stop recording + `RecordingPipeline.swift` (AVFoundation) + `VaultService` (Dart) + integração REC→vault→gallery→preview. DONE = tap REC grava MP4 real no vault, gallery lista o vídeo real, preview reproduz. Gate G1: latência tap→started <300ms. NÃO puxar Tasks B–F (replay/wake/volume/revenuecat/share).

## Contexto inicial

- Sprint 1 fechada (Task H, sessão 0015): walking skeleton de 12 telas validado no iPhone 12. Suíte 200/200 GREEN. Branch `feat/camera-native-bridge` limpa, sincronizada com origin (último commit `de0e4f3`).
- Merge → `develop` **segurado** por decisão do usuário até gates de câmera nativa fecharem (mantido nesta sessão — nenhum merge feito).
- **2 premissas desatualizadas do plano Sprint 2 (escrito 29/mai) corrigidas:** (1) o plano dizia "develop contém o merge da camera-native-bridge" — FALSO, trabalhado em `feat/camera-native-bridge`; o item de pre-flight de merge não foi rodado. (2) A P05 do Sprint 1 era fundo preto (`UiKitView` só no harness) — avaliado no Think-Before-Coding e escalado.

## O que foi feito

**Think-Before-Coding (sem código de produção):** mapeei o estado real do código com workflow de exploração paralela (5 agentes) em vez de confiar no plano de 29/mai — que estava desatualizado em 6 pontos concretos (provider `recording_state_provider.dart` não existe; recording vivia em `camera_shell_provider.dart` como mock puro; `VideoEntity` não tinha `path`/`thumbnailPath`/`length`; `RecordingMetadata`/`RecordingOptions`/`Codec`/`RecordingSettings`-shared não existiam; script pigeon é `bun run --filter '@raro/mobile' pigeon`; swiftOut em `Generated/` não `Pigeon/`).

**2 decisões escaladas ao usuário:** (1) **Ligar preview + sessão na P05** (recomendado) — a gravação real exige uma `AVCaptureSession` rodando; a P05 não iniciava sessão (só o harness). Decidido montar `CameraPreviewWidget` (UiKitView) no `_Viewport` + dirigir `CameraController.start/stop` via ciclo de vida. (2) **Parar no "pronto pro device"** — implemento tudo + analyze + tests + compilação iOS; usuário valida G1 no iPhone 12.

**Gate de ADR (adr-guardian):** recording cruza o boundary explícito do ADR-0015 item 7 ("Sem gravação nesta ADR"). Exigiu **ADR-0018 novo** ANTES de tocar o contrato Pigeon. Verifiquei a citação (ADR-0015:21) de primeira mão.

**Pesquisa Apple-docs (não memória de treino):** decisão de output API. `AVCaptureMovieFileOutput` (não `AVAssetWriter`) para recording — minimal config, HEVC+H264 via `setOutputSettings([AVVideoCodecKey:], for:)`. AssetWriter fica reservado para o replay buffer (Task B, precisa de `CMSampleBuffer`). Container é **`.mov`** (QuickTime), NÃO `.mp4` — verificado; `video_player`/`share_plus` tocam `.mov` nativamente.

**Plano escrito + verificado adversarialmente:** plano de 12 tasks em `docs/superpowers/plans/2026-06-03-s2a-recording-vault.md`, com workflow de verificação adversarial de 6 claims técnicos (Apple docs + código + memórias) — 4 confirmados, 2 corrigidos no plano (provider de settings real é `settingsControllerProvider` não `settingsProvider`; padrão de stop de sessão via `ref.watch` + `onDispose`).

**Execução subagent-driven (12 tasks, cada uma com implementer + review independente via validator + correção em loop):**
- ADR-0018 (`d89b933`); `Codec` enum em raro_shared (`e9bae45` + `3b6727d` hardening do fallback); contrato Pigeon start/stop + `RecordingOptions` + `onRecordingFinished`/`onRecordingFailed` (`c03c574`).
- `RecordingPipeline.swift` (AVCaptureMovieFileOutput) + 5 XCTests + wiring do `CameraHostApiImpl` (`a3880f8`) — **Task 3 e Task 4 mescladas** porque o target iOS não compilava sem o host impl (consequência de o contrato ter vindo na Task 2). Review pegou um `setFormat` redundante no hot path de REC → removido (`31df735`, protege G1).
- `RecordingMetadata` value type (`97bfd9d` + `a651f57` asserções completas); `VideoEntity.filePath` opcional (`c8a29de`); `VaultService` save/list/delete + provider com `Directory` injetável + sidecar JSON (`7b444bd`); delegação no port `CameraRepository` (`0c333ac`); `RecordingController` core + `RecordingPhase` sealed + guards (`fe7a672`).
- **Wiring da P05** (`8b7a492`): preview ao vivo + sessão + REC→vault→gallery + provider `recordingController` + `camera_flutter_api_provider.dart` (SOLE `CameraFlutterApi.setUp` keepAlive + stream `recordingEvents` + sink salva no vault + invalidate gallery). Adaptou 11 testes camera_screen + video_list_provider + router_test. **Mapper shared→pigeon** criado (decisão do usuário ao desbloquear o BLOCKED do type-mismatch): `uhd4k60` decompõe em `uhd4k` + `fps60` forçado.
- Perf audit (flutter-perf-auditor) da P05: 0 Critical, confirmou que o `const CameraPreviewWidget` isola o PlatformView do rebuild do timer 1s (sem jank). 1 Important fixado: REC tap não espera mais I/O de settings — formato resolvido na entrada + `ref.listen`, cacheado em `_format` (`b4c6944`, protege G1).
- **Holistic review final pegou gap:** preview ainda tocava o mock asset, nunca o `.mov` real. Fixado (`8cb6960`): `previewController` agora usa `VideoPlayerController.file(filePath)` quando há filePath, fallback `.asset` para os 6 mocks.

**Verificação ready-for-device (todos GREEN):** analyze 0 issues; Flutter **218/218**; shared **42/42**; XCTest nativo **12/12** (simulador iPhone 17); iOS profile build **`✓ Built Runner.app 46.8MB`** (timestamp fresh confirmado — não a armadilha do exit-0 enganoso). `Package.resolved` do `.xcodeproj` alinhado a 12.14 (igual ao `.xcworkspace`, `f4e5a53`) prevenindo a divergência que quebrou a 0015.

## O que NÃO foi feito (e por quê)

- **Validação no iPhone 12 físico (G1 + reprodução real):** é a parte do usuário (decisão escalada). O código está ready-for-device; G1 (tap→started <300ms) e a reprodução do `.mov` real só dão pra confirmar no aparelho (sem video engine no test binding). Blueprint §11 NÃO marcado até o OK do device.
- **Tasks B–F do Sprint 2** (replay buffer, wake word, volume, RevenueCat sandbox, share): out-of-scope desta sessão (S2.B+).
- **Eventos de analytics de recording** (`recordingStarted`/`recordingEnded`): deixados de fora pelo implementer com aval — o `RecordingStartedPayload` exige `lens`/`ControlMode trigger`/`BufferDuration` que o fluxo atual de recording não carrega; fiar isso direto é trabalho arquitetural. Analytics de sessão de câmera (`cameraStarted`/`cameraError`) seguem cobertos.
- **Reatividade de stop iniciado pelo nativo:** a UI de gravação usa um `bool _recording` local (RecordingController é classe simples, `phase` muta sem notificar Riverpod). Se `onRecordingFailed` disparar no nativo, o `_recording` não reseta sozinho — botão poderia ficar "preso". Aceitável para Task A (o botão é o único gatilho); fix limpo em S2.B é promover RecordingController a Notifier `@riverpod` expondo `RecordingPhase` observável.
- **Merge → develop:** segurado (mantido da 0010/0015).

## Aprendizados / surpresas

- **Plano de 29/mai estava desatualizado em 6 pontos** após 5 sessões de trabalho — confirmar realidade do código ANTES de executar evitou implementar contra premissas falsas (memória `feedback_validator_cross_doc_consistency` em ação).
- **Type-mismatch shared vs pigeon Resolution/Fps:** o implementer travou (BLOCKED, corretamente) ao descobrir que `raro_shared.Resolution` (4 valores, inclui `uhd4k60`) e a `Resolution` do Pigeon (3 valores) são tipos DIFERENTES com cases diferentes. O plano (e a verificação adversarial) não pegaram. Resolvido com mapper + decisão do usuário sobre `uhd4k60`→(`uhd4k`+`fps60`). Lição: enums "com o mesmo nome" em pacotes diferentes não são o mesmo tipo — checar cross-package antes de assumir.
- **`stopRecording` síncrono retornando path está ERRADO para MovieFileOutput** — o arquivo finaliza no delegate `didFinishRecordingTo`, não no retorno. Corrigido no contrato: path vem async via `onRecordingFinished`. (O plano Sprint 2 MD tinha o shape errado.)
- **`AVCaptureMovieFileOutput` escreve `.mov`, não `.mp4`** (QuickTime, sem seletor de container) — honestidade registrada no ADR-0018.
- **`flutter build ios` cru reintroduz o bug Firebase iOS 15-vs-13** — NÃO chama o `fix-spm-ios-target.sh` (que o `dev:ios`/`pub:get` encadeiam). Recovery: `flutter clean` → `bun run --filter '@raro/mobile' pub:get` (aplica fix-spm → 15.0) → build. Confirmado: o `flutter clean` foi suficiente desta vez (não precisou apagar DerivedData, que o sandbox bloqueia). Memória `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery` cobre o caso completo.
- **Build iOS background dá exit 0 enganoso** (relembrado da 0015): o 1º build "completou exit 0" mas o log tinha o erro Firebase e nenhum `.app` novo. SEMPRE conferir `✓ Built` + timestamp do `.app`, nunca só o exit code.
- **Shell state não persiste entre chamadas Bash:** um `flutter build` sem `cd` explícito rodou da raiz do workspace e falhou com "No pubspec.yaml" — sempre usar `cd <dir> && <cmd>` no mesmo comando.
- **Disciplina de gates honrada:** 18 commits, todos Conventional, 0 `--no-verify`. Dois casos onde o commitlint abortou e o implementer corrigiu a causa (não bypassou): subject camelCase (`fromLabel`→`from-label`) e scope fora do enum (`vault`→`camera`).

## Próximos passos

- **Usuário:** validar no iPhone 12 — abrir câmera (preview ao vivo, não preto), tap REC ~3s, parar, gallery mostra o vídeo real, tocar → preview reproduz o `.mov` gravado. Medir G1 via Xcode Console (`subsystem:com.rarocamera category:recording`, "recording started" <300ms após tap). Se OK, marcar Blueprint §11 Sprint 2 "Recording real" device-validated.
- **S2.B (próxima sessão):** Replay buffer 15s/30s nativo (`AVAssetWriter` circular + `CVPixelBufferPool`, ADR-0003 refresh). Avaliar coexistência de `MovieFileOutput` (recording) + `VideoDataOutput` (replay) na mesma sessão `.inputPriority` (risco flagado no ADR-0018).
- **Débitos herdados/novos:** promover `RecordingController` a Notifier `@riverpod` (reatividade de stop nativo); analytics de recording (threading lens/trigger/buffer); unificar `BufferDuration` duplicado (raro_shared vs camera_shell_state, dívida da 0013); robustez do vault contra sidecar órfão (`.mov` sem `.json` ou vice-versa).

## Referências

- Plan: `docs/superpowers/plans/2026-06-03-s2a-recording-vault.md` (12 tasks, verificado adversarialmente)
- Plan Sprint 2: `docs/superpowers/plans/sprint-2-backend-logic-ios.md` §Task A
- ADR criado: `docs/decisions/0018-recording-pipeline-mp4.md` (supersedes ADR-0015 item 7)
- ADRs referenciados: ADR-0015 (boundary cruzado), ADR-0013 (mecanismo Pigeon), ADR-0003 (replay buffer / sessão compartilhada)
- Apple docs: AVCaptureMovieFileOutput.availableVideoCodecTypes, setOutputSettings(_:for:), AVVideoCodecType
- Memórias aplicadas: `feedback_validator_cross_doc_consistency`, `feedback_tdd_pin_behavior_not_type`, `raro-pattern-shared-preferences-async-untestable-use-port`, `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery`, `raro-pattern-spm-package-resolved-divergent`, `raro-pattern-bun-filter-arg-order`, `raro-pattern-flutter-video-player-disposal`, `raro-pattern-flutter-uikitview-eager-gesture-recognizer-issue-170735`
- Native: `RecordingPipeline.swift`, `CameraHostApiImpl.swift`, `CameraManager.swift` + `CameraManagerRecordingTests.swift`
- Dart: `vault_service.dart`, `recording_controller.dart`, `recording_phase.dart`, `recording_metadata.dart`, `recording_options_mapper.dart`, `camera_flutter_api_provider.dart`, `camera_screen.dart`, `video_list_provider.dart`, `preview_controller_provider.dart`
