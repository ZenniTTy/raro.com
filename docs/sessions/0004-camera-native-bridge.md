# Session 0004 — camera-native-bridge

- **Date:** 2026-05-26
- **Branch:** `feat/camera-native-bridge`
- **Spec:** `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md`
- **Plan:** `docs/superpowers/plans/2026-05-26-camera-native-bridge.md`
- **ADR:** `docs/decisions/0015-camera-native-bridge-strategy.md`

## Summary

Entregou a fundação técnica do P05 (Câmera) — bridge nativa via Pigeon (iOS AVFoundation + Android CameraX 1.6.1) com preview ao vivo, lens switch 0.5×/1×, tap-to-focus, format control (720p/1080p/4K @ 30/60fps), e overlay UI fiel ao protótipo (rule-of-thirds + grain + focus ring animado + lens chips pill). Sem gravação real (depende de replay_buffer). Bridge agnóstica de paywall/voice/volume/Firebase direto.

Workflow TLC Spec-Driven completo: Spec (Q-table 15 itens + Observable Goals G1-G16) → Plan (19 atomic tasks TDD) → Subagent-driven execution (1 implementer por task, fresh context). Per-task harness validation antes de cada commit (analyze + tests verdes obrigatório, memória persistente respeitada).

**Auditoria intermediária pós Task 10** detectou 2 problemas HIGH (error code semantic loss no Pigeon + testes só pin-tipo). Pausou execução, corrigiu inline com fixes B1+N5, adicionou 10 testes pin-behavior, 1 hook anti-drift novo + 1 contract test novo + 3 doc addenda. Reiniciou Tasks 11-18. **Auditoria final Task 17** detectou 2 desvios HIGH de fidelidade visual (chip active translucent vs solid white do protótipo + rounded-rect vs pill). Corrigido em commit `e013d6f`.

## Desvios documentados

- **Task 1 a 10**: implementação Pigeon + domain + repo + controller + analytics listener + iOS native. Validator inicial flagou error code semantic loss + testes fracos.
- **Task 10.5 (pausa de auditoria)**: 5 commits — `497b2b2` (docs addenda), `d6e3f0a` (pbxproj parity test), `9472892` (hook block-pigeon-error-rawvalue), `d2a571d` (fix B1 swift PigeonError + N5 catch log), `65c6a87` (10 tests pin-behavior). Memória persistente nova: `feedback_tdd_pin_behavior_not_type`.
- **Tasks 11-13 (Android)**: CameraX 1.6.1 + manifest CAMERA permission + Kotlin sub-package `com.rarocamera.raro_mobile.camera` (não `generated.camera`). HostApi usa `symbolicCode()` extension para evitar enum→raw drift.
- **Tasks 14-15 (UI)**: contract test `forbidden_literals` forçou `BridgeChannels.cameraPreview` constant no shared (não literal inline). Gate funcionou.
- **Task 16**: scope `contract` não está em commitlint enum — usado `bridge` (scope semanticamente correto).
- **Task 17 fidelidade**: chip active state corrigido (solid white + black text); padding 14×8→12×6; gap 8→6; pill (`StadiumBorder`); rule-of-thirds opacity `0.15→0.08` + stroke `0.5→1.0`. Goldens regenerados.
- **Task 19**: pendente — aguarda iPhone 12 do usuário para device tests (G1-G10).

## Commits

Range `6104289..e013d6f` (25 commits), ordem cronológica:

1. `6104289` docs(spec): fill camera-native-bridge design — pigeon-first + ios hybrid + camerax 1.6.1
2. `85752cb` docs(spec): tighten camera-native-bridge — drop swap strategy yagni + add analytics goals
3. `1f87b0e` docs(spec): fill camera-native-bridge plan with 19 atomic tasks tdd + device tests
4. `c6d334c` docs(spec): mark camera-native-bridge in implementation
5. `dacaed8` docs(docs): adr-0015 camera native bridge strategy
6. `4cbd5f2` feat(analytics): add camera lifecycle events to shared contract
7. `bc0d548` feat(bridge): pigeon schema for camera api with lenstype resolution fps + hostapi flutterapi
8. `17112d1` feat(camera): domain types camerasettings + camerastate freezed
9. `aad175c` feat(camera): repository abstraction wrapping pigeon hostapi
10. `05c0441` feat(camera): camera controller riverpod 3 with start/stop/lens/format/focus
11. `08ac046` feat(analytics): camera lifecycle events listener via riverpod
12. `b40f032` feat(bridge): ios camera manager with virtual camera + active format control
13. `68c7c8d` feat(bridge): ios camera hostapi impl + platformview + factory registration
14. `497b2b2` docs(docs): post-audit addenda adr-0014 adr-0015 claude.md anti-patterns
15. `d6e3f0a` test(bridge): ios pbxproj parity contract test for native swift files
16. `9472892` feat(ci): hook block-pigeon-error-rawvalue (preserve enum semantic across pigeon)
17. `d2a571d` fix(bridge): preserve enum semantic in pigeonerror + log zoom catch (post-audit b1 n5)
18. `65c6a87` test(camera): pin behavior — error code, no-op guards, stop, analytics payload, repo delegation
19. `161971e` build(bridge): add camerax 1.6.1 deps + android camera permission
20. `215244b` feat(bridge): android camera manager + lens discovery + error mapper
21. `e87bbc9` feat(bridge): android camera hostapi impl + platformview + factory registration
22. `0050c07` feat(camera): preview widget with rule-of-thirds + grain + focus ring overlays
23. `b471209` feat(camera): lens chip row 0.5x/1x with goldens
24. `e928979` test(bridge): assert camera_preview platformview registered ios + android + shared
25. `e013d6f` fix(camera): chip active solid white + pill shape + rule-of-thirds opacity (post-fidelity audit)

## Verification

- `flutter analyze` mobile: zero issues
- `dart analyze` shared: zero issues
- `flutter test` mobile: **62 verdes** (smoke + contract + features/camera)
- `dart test` shared: **33 verdes** (smoke + analytics_events)
- `flutter build ios --no-codesign --debug`: PASS (Runner.app)
- `flutter build apk --debug`: PASS (app-debug.apk)
- Goldens `lens_chip_row` macOS + CI variants regenerados
- Validator subagent (Task 17): **SPEC_COMPLIANT** com 3 notes não-bloqueantes (G9 background/foreground implícito iOS, G10 iPad implícito, chip labels inline como tokens visuais)
- Design-fidelity-checker (Task 17): 2 HIGH + 2 MEDIUM corrigidos inline (`e013d6f`), 3 LOW deixados como tech-debt
- Cross-doc audit: zero placeholders reais nos docs finais (spec + ADR-0015 + plan)

## Gates novos ativados (anti-drift)

1. **Hook `.claude/hooks/block-pigeon-error-rawvalue.sh`** — bloqueia `String(enum.rawValue)` em `PigeonError(...)` / `FlutterError(...)` em `.swift` e `.kt` (PreToolUse Write/Edit/MultiEdit)
2. **Contract test `ios_pbxproj_parity_test.dart`** — todo Swift em `Native/**` deve estar em PBXFileReference + PBXSourcesBuildPhase
3. **Contract test `bridge_channels_parity_test.dart` extension** — `BridgeChannels.cameraPreview` ↔ AppDelegate.swift ↔ MainActivity.kt parity
4. **ADR-0015 addendum** — PlatformView único, threading refinado, error semantic, TDD pin behavior
5. **CLAUDE.md §11 addendum** — 3 anti-patterns novos (enum rawValue em Pigeon, expect isA<T> sem campo, swallow catch sem log)
6. **Memória persistente `feedback_tdd_pin_behavior_not_type`** — TDD pin de comportamento, não de tipo
7. **Xcode Build Phase `Fix SPM iOS Target`** — patch automático Flutter SPM 13→15 entre Flutter Run Script e Sources (UUID `CA00000000000000000000C1` no pbxproj). Script idempotente `scripts/fix-spm-ios-target.sh`.
8. **CLAUDE.md §11 addendum 2** — 2 anti-patterns novos sobre arquivos gerados (não assumir respeito a config externa, não editar e esperar persistência)
9. **Memória persistente `raro-pattern-flutter-spm-ios-13-hardcoded`** — root cause (Flutter `darwin.dart:71` hardcoda iOS 13) + solução (Xcode Build Phase) + como remover quando issue #176313 fechar.

## Debug-session 2026-05-27 (device validation pre-flight)

Antes de Task 19 começar de fato, build iOS quebrou 3x com erro Firebase 15.0 vs target 13.0. Foram 3 ciclos perdidos:

1. **Ciclo 1** — assumido que Pods estavam errados, adicionado `IPHONEOS_DEPLOYMENT_TARGET = '15.0'` no `post_install` do Podfile. Resultado: pods OK, mas erro mudou de origem.
2. **Ciclo 2** — assumido que Xcode SPM cache estava ruim, editado `Package.swift` manualmente 13→15. Resultado: build PASS, mas próximo `flutter pub get` reverteu.
3. **Ciclo 3** — criado script `fix-spm-ios-target.sh` + wired em `bun run pub:get`. Resultado: funciona via CLI, mas build pelo Play do Xcode (sem passar pelo bun script) reverte.

Após o 3º ciclo, parei e investiguei a fonte. Encontrei `darwin.dart:71` com `Version(13, 0, null)` hardcoded. Documentado e fix definitivo via Xcode Build Phase aplicado.

**Lição registrada em memória persistente**: antes de assumir que arquivo "Generated. Do not edit." obedece configuração externa, **ler o code que gera**. 5 minutos de leitura de source economizariam 3 ciclos de tentativa.

### Update 2026-05-27 (Build Phase falhou — solução oficial via Scheme Pre-action)

A solução inicial via Xcode **Build Phase** (commit `2fcd7be`) FALHOU em produção. Após rebuild no iPhone 12 do usuário, mesmos 3 erros Firebase 15 vs 13 retornaram.

**Diagnóstico**: Xcode resolve dependências SPM ("Resolve Package Graph") **ANTES** de qualquer Build Phase rodar. Os erros são detectados na resolução, não no build pipeline.

**Pesquisa moderna ([WebSearch + docs.flutter.dev](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers))** revelou solução oficial documentada: **Scheme Pre-actions** rodam ANTES da resolução SPM. Issue Flutter [#162072](https://github.com/flutter/flutter/issues/162072) documenta o bug. A doc oficial recomenda Pre-action no `Runner.xcscheme`.

**Correção aplicada**: adicionada segunda `<ExecutionAction>` no `<PreActions>` do `Runner.xcscheme`, após o "Run Prepare Flutter Framework Script" oficial. Script `fix-spm-ios-target.sh` invocado via `${SRCROOT}/../scripts/`. Build Phase anterior removida.

**Lição adicional (3ª) registrada**: usar WebSearch + docs oficiais ANTES de improvisar workaround. A solução exata estava documentada o tempo todo.

## Pendente

- **Task 19 — Device tests em iPhone 12 (usuário) + emulador Android Pixel 6**. Validar Goals G1-G10 com cronômetro/Instruments/Memory Profiler. Sem isso, spec fica em `In implementation` (não Done definitivo).

## Próxima sessão sugerida

- **0005** — `feat/replay-buffer-native-bridge` (Roadmap rm-8). Plataforma agora moderna (Flutter 3.44 + SPM + iOS 15), camera bridge entrega preview pronto, contract anti-drift + hooks policiando enum semantic + pigeon namespace, harness verde. Replay buffer reusa CameraSession (sem reabrir AVCaptureSession), adiciona AVAssetWriter (iOS) + MediaCodec/MediaMuxer (Android), CVPixelBufferPool (iOS) e MediaCodec pool (Android). Pré-roll integra com `feat/camera-recording` futura.

---

## Debug-session 2026-05-27/28 (device validation Task 19 — extensão)

Tentativa de validar Task 19 (Goals G1-G10) em iPhone 12 físico. **Tempo gasto: ~6 horas em ciclos build-test-corrigir.** Resultado de **chutar fix antes de ler logs reais** — lição capital documentada em `feedback_device_debug_use_real_logs_not_assumptions`.

### 11 bugs descobertos + fixes aplicados

| # | Sintoma | Root cause | Fix |
|---|---|---|---|
| 1 | Pre-action `[fix-spm-ios-target]` faz Xcode abortar build silenciosamente | Pre-action chamava `flutter build ios --config-only` (regenera workspace mid-build) | Pre-action sed-only (instantânea). Diagnóstico via `xclogparser parse --reporter flatJson` |
| 2 | Preview câmera preto mesmo com LED iOS verde | `AVCaptureVideoPreviewLayer.frame` zero + Stack/CustomPaint sobre `UiKitView` quebra hybrid composition | `layerClass` override Apple pattern + `showOverlays=false` no harness |
| 3 | Lens 0.5x ↔ 1x não troca no iPhone 12 | DualWide reporta `minAvailableVideoZoomFactor=1.0` (não 0.5) — `videoZoomFactor=0.5` é clampado silenciosamente | Mapping correto: `virtualDeviceSwitchOverVideoZoomFactors[0]=2.0`; 0.5x→zoom 1.0, 1x→zoom 2.0. **Sem blackout.** Fallback `replace-input` físico para devices sem virtual. |
| 4 | setFormat sem efeito visual | Faltava `session.sessionPreset = .inputPriority` antes de `activeFormat` | `beginConfiguration` + sessionPreset + applyFormat + `commitConfiguration` |
| 5 | 720→1080/4K mostra paisagem brief antes de assentar | Auto-focus rebuild durante format switch | `device.isSmoothAutoFocusEnabled = true` (se suportado) |
| 6 | App crash voltando de Settings.app | iOS suspende AVCaptureSession em background, sem observer não retoma | 3 observers: `wasInterruptedNotification` + `interruptionEndedNotification` + `runtimeErrorNotification`; auto-restart em `.mediaServicesWereReset` |
| 7 | Dialog "open settings" não aparecia em permission denied | `Permission.camera.status.isPermanentlyDenied` é `false` no iOS (iOS reporta `.denied` direto após negação) | Treat `isDenied` igual `isPermanentlyDenied` no iOS para trigger deeplink |
| 8 | Tela preta "iOS 14+ debug mode" ao reabrir | Restrição arquitetural Flutter+Apple (debug usa JIT, JIT exige Xcode) | **Não é bug.** Flag `_forceHarness` permite harness em release; deferir G8/G9 lifecycle real para TestFlight |
| 9 | "Failed to launch — code signature" em release | Apple Development cert (free tier) não basta para release no device físico real | Voltar para debug; documentar requisito Apple Developer Program ($99/ano) |
| 10 | iOS 13 vs 15 voltou após Debug↔Release scheme switch | Xcode regerou ephemeral SPM ao trocar scheme | Pre-action sed-only reativada no scheme |
| 11 | **Câmera nunca aparece em Ajustes → App; prompt nativo nunca dispara** | **`permission_handler` exige macros `GCC_PREPROCESSOR_DEFINITIONS PERMISSION_CAMERA=1` no Podfile** — sem isso plugin retorna `denied` silenciosamente sem chamar `AVCaptureDevice.requestAccess` | Macros no `post_install` do Podfile + script `bootstrap-ios-permissions.sh` idempotente reaplicando após `flutter pub get` (Podfile gitignored, ADR-0014) |

### Anti-patterns catalogados nesta sessão

1. Pre-action Xcode invocando `flutter build` dentro do build em curso
2. Confiar em status "BUILD SUCCEEDED" sem inspecionar `.xcactivitylog`
3. Inventar fix de zoom-ramp para iPhone 12 sem checar `minAvailableVideoZoomFactor`
4. Adicionar `permission_handler` no `pubspec.yaml` sem ler README iOS Setup
5. Inventar fix para bug em device sem instrumentar `os_log` reais primeiro
6. Tratar tela "iOS 14+ debug mode" como bug em vez de restrição arquitetural

Catalogados em CLAUDE.md §11 addendum 3 + ADR-0015 addendum (seções A-H).

### Gates adicionados nesta extensão

10. **Script `scripts/bootstrap-ios-permissions.sh`** — idempotente, reaplica macros `permission_handler` após `flutter pub get`. Suporta `PERMISSION_CAMERA`, `PERMISSION_MICROPHONE`, `PERMISSION_PHOTOS`, `PERMISSION_SPEECH_RECOGNIZER`.
11. **`package.json` mobile** — novos targets `bootstrap:ios` (combo fix-spm + bootstrap-permissions) e `pub:get` atualizado.
12. **CLAUDE.md §11 addendum 3** — 3 anti-patterns adicionais.
13. **Memórias persistentes (4 novas)**:
    - `raro-pattern-permission-handler-ios-podfile-macros`
    - `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`
    - `raro-pattern-flutter-debug-vs-release-on-device`
    - `feedback_device_debug_use_real_logs_not_assumptions`
14. **ADR-0015 addendum 2026-05-28** — seções A-H consolidando lições device validation.

### Estado do harness na pausa

- ✅ G1 start session (instrumentado, falta cronometragem precisa)
- ✅ G2 capabilities (`[ultraWide, wide]` iPhone 12)
- ✅ G3 lens switch 0.5x↔1x **sem blackout** via virtual device zoom
- ⏳ G4 focus ring (out of scope harness — overlay no lado nativo CALayer pendente)
- ✅ G5 resolution runtime (logs confirmam 720/1080/4K aplicados)
- ✅ G6 4K@60fps (logs confirmam `setFormat uhd4k@fps60 → 3840x2160`)
- ⏳ G7 stop libera memória (precisa Instruments)
- ✅ G8 permission denied → open settings → volta (funciona em debug via Control Center; release adiado TestFlight)
- ✅ G9 background/foreground via Control Center (observers AVCaptureSession funcionam)
- ⏳ G10 iPad rejected (N/A — não testado, lógica `discoverCapabilities` já cobre via empty devices)

### Próxima sessão sugerida (atualizada)

Opções:
- **(a)** Continuar harness — G4 focus ring nativo via CALayer + Instruments para G1/G7 + Android Pixel emulator G2/G3
- **(b)** Pular para **0005 — `feat/replay-buffer-native-bridge`** (Roadmap rm-8) reusando CameraSession estável
- **(c)** Comprar Apple Developer Program para fechar G8/G9 em TestFlight

Recomendação: **(a)** para fechar Task 19 antes de mover para 0005.
