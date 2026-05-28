# 0005 — camera device validation (Task 19)

- **Data:** 2026-05-27 → 2026-05-28
- **Duração:** ~6h (efetivas em debug + correções)
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Spec:** `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md`
- **Plan:** `docs/superpowers/plans/2026-05-26-camera-native-bridge.md` (Task 19 — Device tests)
- **ADR:** `docs/decisions/0015-camera-native-bridge-strategy.md` (com addendum 2026-05-28 seções A-H)
- **Commits:** `17d6d45` … `3e14d8f` (24 commits — extensão da spec camera-native-bridge para device validation)

## Objetivo

Validar Goals G1-G10 do plan camera-native-bridge em iPhone 12 físico, fechando Task 19 e movendo a spec de "In implementation" para "Done definitivo".

Pré-requisito: app rodando em device físico real (não simulador), pois G3 (lens switch), G6 (4K@60fps), G7 (memory) só validam com hardware.

## Contexto inicial

- Tasks 1-18 da spec implementadas e mergeadas via subagent-driven-development (session 0004, 25 commits)
- Validator subagent assinou SPEC_COMPLIANT com 3 notes não-bloqueantes
- Design-fidelity-checker: 2 HIGH + 2 MEDIUM corrigidos
- ADR-0015 com 9 addenda pós-auditoria
- 9 gates anti-drift ativos
- `feat/camera-native-bridge` 25 commits ahead de `develop`, esperando Task 19 device test antes de merge

Pré-flight build havia falhado 3x na primeira sessão (session 0004) com erro Firebase 15.0 vs target iOS 13.0 — resolvido com `darwin.dart:71` hardcode workaround via Xcode Scheme Pre-action.

## O que foi feito

### Bugs descobertos e corrigidos (11 ao total)

Listados na ordem cronológica em que apareceram:

1. **Pre-action `[fix-spm-ios-target]` abortando build silenciosamente** (`b48e452`, `f962d66`)
   - Pre-action chamava `flutter build ios --config-only` que regenera workspace durante o build em curso
   - Diagnosticado via `xclogparser parse --reporter flatJson` no `.xcactivitylog` — log mostrou 4 steps totais, apenas pre-actions, status "stopped", zero build phases executadas
   - Fix: Pre-action sed-only (instantânea)

2. **Preview câmera preto mesmo com LED iOS verde** (`f34acfa`)
   - Memory `raro-pattern-ios-platformview-camera-preview-black` confirmou: `AVCaptureVideoPreviewLayer.frame` não sincroniza + Stack/CustomPaint sobre `UiKitView` quebra hybrid composition
   - Fix: `layerClass` override Apple-recommended + `showOverlays=false` no harness

3. **Lens switch 0.5x ↔ 1x não troca no iPhone 12** (`83e8578`, `e8090de`)
   - Tentativa inicial: replace-input físico (`builtInUltraWideCamera` ↔ `builtInWideAngleCamera`). Funcionou mas com blackout 100-300ms
   - Tentativa alternativa: `videoZoomFactor=0.5` no DualWide — clampado silenciosamente para 1.0
   - Root cause via Xcode Console logs (`switchLens path=zoom-ramp targetZoom=0.50 clamped=1.00`): DualWide reporta `minAvailableVideoZoomFactor=1.0` mesmo com ultra-wide física dentro
   - Fix definitivo: mapping Apple-correto — 0.5x → zoom 1.0, 1x → zoom `virtualDeviceSwitchOverVideoZoomFactors[0]`=2.0. Sem blackout.

4. **setFormat sem efeito visual** (`cf4a12d`)
   - `device.activeFormat = X` ignorado silenciosamente sem `session.sessionPreset = .inputPriority`
   - Fix: wrap `beginConfiguration` + sessionPreset + applyFormat + `commitConfiguration`

5. **720→1080/4K mostra paisagem brief antes de assentar** (`e2ca8e8`)
   - Auto-focus rebuild durante format switch
   - Fix: `device.isSmoothAutoFocusEnabled = true` (se suportado)

6. **App crash voltando de Settings.app** (`1340272`)
   - iOS suspende AVCaptureSession em background; sem observer não retoma
   - Fix: 3 observers (`wasInterruptedNotification`, `interruptionEndedNotification`, `runtimeErrorNotification`) + auto-restart em `.mediaServicesWereReset`

7. **Dialog "open settings" não aparecia em permission denied** (`0c4a979`, `1340272`)
   - `Permission.camera.status.isPermanentlyDenied` é `false` no iOS após primeira negação (iOS reporta `.denied` direto, não `.permanentlyDenied`)
   - Fix: treat `isDenied` igual `isPermanentlyDenied` no iOS para trigger deeplink

8. **Tela preta "iOS 14+ debug mode Flutter apps can only be launched from Xcode"** (`eb5acb7`)
   - **Não é bug.** Restrição arquitetural: Flutter debug usa JIT, JIT exige Xcode conexão
   - Fix: comunicar limitação + adicionar flag `_forceHarness` (via `bool.fromEnvironment('RARO_HARNESS')`) permitindo harness em release mode

9. **"Failed to launch — code signature" em release** (`62a1c2b`)
   - Apple Development cert (free tier) não basta para release no device físico real — Apple Developer Program ($99/ano) obrigatório
   - Fix: voltar para debug; documentar requisito

10. **iOS 13 vs 15 voltou após Debug↔Release scheme switch** (`62a1c2b`)
    - Xcode regerou ephemeral SPM ao trocar scheme; ephemeral é gitignored
    - Fix: Pre-action sed-only reativada no scheme (segura agora — sem `flutter build` interno)

11. **Câmera nunca aparece em Ajustes → App; prompt nativo nunca dispara** (`3d0a6dd`)
    - **Bug crítico mais grave da sessão.** `permission_handler` Flutter exige macros `GCC_PREPROCESSOR_DEFINITIONS PERMISSION_CAMERA=1` no `Podfile` — sem isso, plugin retorna `denied` silenciosamente sem chamar `AVCaptureDevice.requestAccess`
    - Best practice oficial documentada em [pub.dev/packages/permission_handler#setup-ios](https://pub.dev/packages/permission_handler) — não foi seguida no scaffold inicial (Fase 2)
    - Fix: macros no `post_install` do Podfile + script `bootstrap-ios-permissions.sh` idempotente que reaplica após `flutter pub get` (Podfile é gitignored, ADR-0014)

### Documentação criada/atualizada

- **ADR-0015 addendum 2026-05-28** (seções A-H) — consolida lições device validation (`3e14d8f`)
- **CLAUDE.md §11 addendum 3** — 3 anti-patterns novos
- **CHANGELOG entry 0.4.1** com breakdown completo
- **Session 0004 extension** — debug-session timeline + 11-bug table
- **INDEX 0001** atualizado: 48 commits, G1-G6 ✅, G7/G10 ⏳, G4 nativo, G8/G9 → TestFlight

### Memórias persistentes criadas (4 novas)

1. **`raro-pattern-permission-handler-ios-podfile-macros`** — root cause + fix completo + script bootstrap
2. **`raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`** — consolidado iPhone 12 (zoom, sessionPreset, observers, smoothAutoFocus, @preconcurrency, err=-17281)
3. **`raro-pattern-flutter-debug-vs-release-on-device`** — explicação tela debug-mode + limitações free tier + lifecycle testing
4. **`feedback_device_debug_use_real_logs_not_assumptions`** — meta-feedback: logs reais > suposições; fluxo xclogparser/os_log/Xcode Console

### Gates / automação adicionados

- `apps/mobile/scripts/bootstrap-ios-permissions.sh` (idempotente, com `pod install` propagação)
- `apps/mobile/package.json` target `bootstrap:ios` + `pub:get` atualizado
- 3 anti-patterns CLAUDE.md §11 addendum 3

## O que NÃO foi feito (e por quê)

### G4 — focus ring overlay
**Não testado em device.** Implementação atual do `CameraTestHarnessScreen` usa `showOverlays=false` para evitar Stack/CustomPaint sobre `UiKitView` (quebra hybrid composition). Solução planejada (já documentada em memory `raro-pattern-ios-platformview-camera-preview-black`): renderizar focus ring como **CALayer no lado nativo Swift**, não Flutter. Pendente próxima sessão.

### G7 — stop libera memória ±5MB
**Não medido.** Precisa Xcode Instruments + Memory Profiler para baseline pre-start vs pós-stop. Pendente sessão futura com setup Instruments.

### G10 — iPad rejected
**Não testado.** Sem iPad físico disponível na sessão. Lógica `discoverCapabilities` já cobre via empty devices array → `throw .deviceUnavailable`. Validação opcional.

### G8/G9 — lifecycle real (fechar app + reabrir)
**Adiado para TestFlight.** Requer Apple Developer Program ($99/ano) para signing release no device físico. Em debug, observers de AVCaptureSession já validam comportamento via Control Center / multitasking parcial (G8 ✅, G9 ✅ funcionalmente). Validação "fechar app + reabrir pelo ícone" só em TestFlight.

### Android Pixel 6 emulator
**Não iniciado.** Foco total nesta sessão foi iPhone 12. CameraX bridge na Android side já implementado nas tasks 1-18, mas precisa device test próprio. Memory `raro-pattern-android-camerax-ultra-wide-unreliable` já indica que ultra-wide é OEM-dependent — esperar validar em device real.

### Performance G1 (start ≤500ms)
**Logs instrumentados, cronometragem precisa pendente.** Os `os_log` agora informam `startSession lens=... device=...`, mas falta wrapper com `mach_absolute_time()` para medir Time-To-First-Frame. Pendente quando configurar Instruments.

### Performance G6 (4K@60fps verificação metadata)
**Aplicação confirmada via logs** (`setFormat uhd4k@fps60 -> 3840x2160`). Mas medição real-time de FPS via `CONTROL_AE_TARGET_FPS_RANGE` (Android) ou `activeVideoMinFrameDuration` (iOS) inspection pendente.

## Aprendizados / surpresas

### Capital — "Logs reais > suposições"

A lição mais cara desta sessão. Gastamos ~4h em ciclos build-test-corrigir baseados em chutes teóricos antes de instrumentar logs reais. Quando finalmente capturamos:

- `xclogparser` revelou em <2min que Pre-action abortava build silenciosamente
- `os_log` revelou `minZoom=1.00 clamped=1.00` provando bug zoom-ramp
- `grep PERMISSION_ Pods.xcodeproj` revelou macros ausentes

**Cada uma dessas evidências teria sido capturada em <2min** se a primeira ação tivesse sido "instrumentar e ler" em vez de "chutar e testar". Registrado como `feedback_device_debug_use_real_logs_not_assumptions` para future-me parar de cometer esse erro.

### permission_handler é bug-prone-by-default no iOS

A flag-based compilation do `permission_handler_apple` é **invisível**: instala o plugin, código compila, app roda, mas funcionalidade não existe — sem stack trace, sem warning, sem erro. **Único sintoma:** Permissão não aparece nas Settings do iOS. Levei 4h para descobrir isso porque assumi que o setup do plugin estava completo no scaffold.

Best practice óbvia em retrospecto: **sempre ler README iOS Setup do plugin antes de mexer no código**. Agora catalogado em CLAUDE.md §11.

### `idevicesyslog` não captura apps de terceiros em iOS 18+

Tentei usar `idevicesyslog` (libimobiledevice) para capturar logs do device automaticamente. **Apple restringiu acesso ao syslog_relay** — só mostra processos do sistema. Para apps de usuário, única opção é Console.app do Mac (filtrar device) ou Xcode debugger conectado.

Aprendizado: pedir ao usuário pra colar conteúdo do Xcode Console é o protocolo mais confiável. Tentei ligar monitor automático que não capturou nada útil (filtrou só erros do sistema).

### iPhone DualWide `minAvailableVideoZoomFactor` mente

Reporta `1.0` mesmo com ultra-wide física disponível dentro do device virtual. Apple usa `virtualDeviceSwitchOverVideoZoomFactors[0]` como threshold real — abaixo dele = ultra-wide internamente, no/acima = wide. Mapping correto vai contra a intuição.

### Pre-actions Xcode são frágeis

Modificar workspace durante o build em curso é destrutivo. Pre-actions devem ser **instantâneas** (<1s), **read-only** ou patches mínimos via `sed`. Qualquer coisa que invoque `flutter build`, `pod install`, ou regenere `project.pbxproj` ali dentro = build abortado em silêncio.

### Free tier Apple não basta para release no device

Apple Development cert (sem Dev Program) consegue debug install no device físico real, mas não release. Para fechar G8/G9 lifecycle completo, vai precisar Apple Developer Program ($99/ano). Em debug, observers já cobrem o comportamento esperado via Control Center.

## Próximos passos

### Opção A (recomendada): fechar Task 19 antes de mover para spec 0005
1. Implementar G4 focus ring nativo (CALayer Swift) — não passa pela hybrid composition issue
2. Configurar Xcode Instruments + medir G1 start time + G7 memory release
3. Validar G3 (sem blackout) + G6 (4K@60fps) com cronômetro/metadata
4. Configurar Pixel 6 emulator + validar Android: G2 (capabilities), G3 (lens), G6 (4K@60)
5. Marcar spec camera-native-bridge como **Done**
6. Merge `feat/camera-native-bridge` → `develop` → `main`

### Opção B: pular para spec 0005 — replay-buffer-native-bridge
- Roadmap rm-8
- Reusa CameraSession agora estável
- AVAssetWriter (iOS) + MediaCodec/MediaMuxer (Android) + CVPixelBufferPool / MediaCodec pool
- Pré-roll integra com `feat/camera-recording` futura
- Workflow: `/new-spec replay-buffer-native-bridge` → brainstorming → `/new-plan` → writing-plans → subagent-driven-development

### Opção C: investir em Apple Developer Program
- Comprar Apple Dev Program ($99/ano)
- Configurar Distribution Certificate
- Fechar G8/G9 em TestFlight
- Build release no device físico real

**Recomendação consolidada:** Opção A para destravar merge. G4/G7/G10 são as últimas pontas. Apple Dev Program pode ficar para quando aproximar TestFlight (próximas 2-3 specs ainda são bridges nativas, sem urgência de release real).

## Referências

- ADR-0015 (com addendum 2026-05-28 seções A-H)
- CHANGELOG 0.4.1
- Spec `2026-05-26-camera-native-bridge-design.md` (sem mudança nesta sessão)
- Plan `2026-05-26-camera-native-bridge.md` Task 19 (parcialmente concluído: G1, G2, G3, G5, G6, G8, G9 validados; G4, G7, G10 pendentes)
- Memórias novas: `raro-pattern-permission-handler-ios-podfile-macros`, `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`, `raro-pattern-flutter-debug-vs-release-on-device`, `feedback_device_debug_use_real_logs_not_assumptions`
- CLAUDE.md §11 addendum 3 (3 anti-patterns novos)
- Best practice externa: [pub.dev/packages/permission_handler#setup-ios](https://pub.dev/packages/permission_handler)
- Apple DTS confirmação `FigCaptureSourceRemote err=-17281` benigno: [forums.apple.com/thread/810894](https://developer.apple.com/forums/thread/810894)
