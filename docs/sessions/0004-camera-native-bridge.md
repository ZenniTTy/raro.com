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

## Pendente

- **Task 19 — Device tests em iPhone 12 (usuário) + emulador Android Pixel 6**. Validar Goals G1-G10 com cronômetro/Instruments/Memory Profiler. Sem isso, spec fica em `In implementation` (não Done definitivo).

## Próxima sessão sugerida

- **0005** — `feat/replay-buffer-native-bridge` (Roadmap rm-8). Plataforma agora moderna (Flutter 3.44 + SPM + iOS 15), camera bridge entrega preview pronto, contract anti-drift + hooks policiando enum semantic + pigeon namespace, harness verde. Replay buffer reusa CameraSession (sem reabrir AVCaptureSession), adiciona AVAssetWriter (iOS) + MediaCodec/MediaMuxer (Android), CVPixelBufferPool (iOS) e MediaCodec pool (Android). Pré-roll integra com `feat/camera-recording` futura.
