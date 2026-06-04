# 2026-05-29 — e2e-harness-hybrid

> Spec scaffold (TLC Spec-Driven). Esta é a Implementation Spec da Sessão 2: instala toolchain local + entrega Pigeon `CameraDebugHostApi` + rota `/debug/self-test` + primeiro `integration_test` de tap-to-focus + smoke Maestro no Simulator.

## Status

`Draft`

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues
- **Implementer agent:** `implementer`
- **Validator agent:** `validator`
- **Apoio:** `flutter-test-author` (autoria do `integration_test`), `adr-guardian` (confirma ADR-0016), `researcher` (Context7/pub.dev para versão das libs — pigeon, integration_test, go-ios, pymobiledevice3, Maestro)

## Reading order (pre-flight obrigatório)

Antes de implementar, ler nesta ordem:

1. `docs/briefing/original-briefing.md` — Seção camera/tap-to-focus (P05).
2. `docs/Blueprint.md` — Seções 2 (stack), 5 (tela Câmera), 11 (roadmap native bridge).
3. `docs/briefing/prototype/Prototipo-RARO.html` — P05 Câmera (linha 824+, ring de foco, copy 30 dias).
4. `CLAUDE.md` — Seção 13 (workflow iOS terminal-first), Seção 11 (anti-patterns).
5. `docs/decisions/ADR-0013-api-contract-shared.md` — convenção Pigeon (será baseline para `CameraDebugHostApi`).
6. `docs/decisions/ADR-0014-flutter-3.44-spm-migration.md` — restrições iOS 15+ / SPM no Simulator.
7. **ADR-0016 (proposto)** — `e2e-harness-hybrid` (Maestro Simulator + integration_test device + Pigeon debug bridge). Esta spec é a primeira implementação após approval do ADR-0016.
8. `apps/mobile/lib/core/native_bridges/camera_bridge.dart` + `apps/mobile/ios/Runner/CameraBridge.swift` — entender contrato existente que o `CameraDebugHostApi` espelha (read-only counterpart).

## Problem

A pipeline de câmera é a path crítica do RARO (P05 Câmera + foco/zoom + replay buffer). A perf work das últimas 5 sessões (commits `3b79021` → `cba16ce`) atacou latency de tap-to-focus por inspeção visual ("parece mais rápido") e `os_log` manual. Isso não escala:

1. **Sem ground truth**, qualquer claim de "reduzimos N ms" é narrativa, não evidência. Não há como provar regressão antes do usuário sentir.
2. **Sem state probe do AVFoundation**, não dá pra afirmar que o `focusPointOfInterest` setado bate com o ponto tocado (já tivemos bug nisso — commit `d259d8c` `capturedevicepointconverted`).
3. **Sem harness reprodutível**, cada perf session re-instrumenta `os_log` ad-hoc, deleta no fim, e a próxima sessão recomeça do zero.
4. O `$99/ano Apple Developer Program` não está pago ainda, o que bloqueia Patrol full (que precisa de release build no device físico — ver `raro-pattern-flutter-debug-vs-release-on-device`). Precisamos de um harness que **funcione hoje com free tier** e escale quando o $99 entrar.

**Esta spec entrega o MVP do harness híbrido**: toolchain local instalado, Pigeon debug bridge expondo state do `AVCaptureDevice` para Dart, rota `/debug/self-test` para invocar bench manualmente, primeiro `integration_test` de tap-to-focus rodando no iPhone 12 físico via `flutter test integration_test/` (que funciona em debug attach, diferente de Patrol), e smoke Maestro no Simulator para permission rehearsal. **Não tenta** rodar measurement em release build (defer pós-$99) nem usar XCTClockMetric (defer) nem MetricKit (out-of-scope — audit ADR-0016 marcou como overengineering).

Cita: ADR-0016 §3 (escopo Sessão 2), Blueprint §11 (bridge camera é prioridade 1), `CLAUDE.md` §10 (gate: tocou Method Channel → contract test obrigatório).

## Sizing (auto-sizing)

- [ ] Quick
- [ ] Medium
- [x] **Large** — novo Pigeon API (`CameraDebugHostApi`) cruzando Dart↔Swift↔Kotlin + nova rota Flutter + nova suite `integration_test/` + 3 binários CLI instalados via Homebrew/pip + novo script `package.json` + ADR-0016 referenciado. Aciona `/new-plan` antes do Execute.

Sinais de escalada disparados (§6 do CLAUDE.md):

- Toca Method Channel (novo Pigeon API).
- Adiciona deps (`pigeon`, `integration_test` em `dev_dependencies`).
- Toca `pubspec.yaml`, `package.json` raiz (novo script).
- Multi-file (>5 arquivos: 1 Pigeon spec, 3 generated, 1 Swift handler, 1 Kotlin handler, 1 rota Flutter, 1 widget bench, 1 integration_test, 1 maestro yaml, 1 install script, 1 package.json edit).

## Q-table (perguntas antes de implementar)

| #  | Question | Answer |
|----|----------|--------|
| 1  | Onde mora o Pigeon spec file? Convenção do projeto. | `apps/mobile/pigeons/camera_debug_api.dart` (segue ADR-0013 que padronizou `pigeons/` na raiz do app). |
| 2  | Generated Dart vai pra onde? | `apps/mobile/lib/core/native_bridges/generated/camera_debug_api.g.dart` (mesma pasta dos outros generated). Adicionar ao `.gitignore`? Não — generated Pigeon é commitado (ADR-0013 §5). |
| 3  | Generated Swift vai pra onde? | `apps/mobile/ios/Runner/Generated/CameraDebugApi.g.swift`. Commitado. |
| 4  | Generated Kotlin? | `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/CameraDebugApi.g.kt`. Commitado. |
| 5  | `kDebugMode` guarda em qual layer? Só Dart? Native também? | **Defesa em profundidade**: (a) Dart route guard (`if (!kDebugMode) return const SizedBox.shrink();`), (b) Pigeon HostApi handler em Swift/Kotlin retorna `FlutterError(code: "DEBUG_ONLY")` se `#if !DEBUG` (Swift) ou `BuildConfig.DEBUG == false` (Kotlin). Garante que mesmo se um release build acidentalmente contiver a rota, o native side recusa. |
| 6  | `getFocusPointOfInterest` retorna o quê? | `FocusState { x: Double, y: Double, mode: FocusMode (enum: locked/autoFocus/continuousAutoFocus), isAdjusting: bool, lensPosition: Double, timestampMs: Int64 }`. Lido sincronamente do `AVCaptureDevice` ativo. |
| 7  | `getCurrentLens` retorna o quê? | `LensInfo { deviceType: String (ex "builtInDualWideCamera"), virtualDeviceSwitchOverZoomFactors: List<Double>, activePhysicalLens: String (ex "ultraWide"/"wide"), zoomFactor: Double }`. |
| 8  | `getZoomFactor` é redundante com `getCurrentLens`? | Sim, mas útil pra teste isolado de zoom sem ler estrutura inteira. Mantém. |
| 9  | Integration test usa qual finder pra ring de foco? | `find.byKey(const Key('camera-focus-ring'))`. Adicionar `Key` ao widget se não existir (mínimo necessário — Surgical Changes). |
| 10 | Stopwatch mede o quê exatamente? Início e fim. | Início: `await tester.tap(viewport)` retorna (gesture enqueued). Fim: `CameraDebugHostApi.getFocusPointOfInterest()` retorna `focusMode == autoFocus` E `(focusPoint - tappedPoint).distance < epsilon`. Threshold: `<100ms` (alinhado a perf budget P05 do briefing). |
| 11 | Como obter UDID do iPhone 12? | `xcrun xctrace list devices 2>&1 | grep -i iphone` ou `ios list` (go-ios). Hardcode em env `RARO_IOS_DEVICE_UDID` em `.env.local` (gitignored). Script lê de env. |
| 12 | Maestro Simulator: qual Simulator alvo? | iPhone 15 (iOS 17), pois Maestro tem suporte estável e cobre maior parte da userbase. Auto-detect via `xcrun simctl list devices available --json \| jq` no install script. |
| 13 | Permission rehearsal no Simulator usa o quê? | `xcrun simctl privacy <udid> grant camera com.rarocamera` antes de cada Maestro flow; `revoke` no teardown. Maestro YAML chama isso via `runScript`. |
| 14 | go-ios e pymobiledevice3 são realmente necessários nesta sessão? | **go-ios**: sim, pra listar UDIDs e validar `ios info` antes do `flutter test`. **pymobiledevice3**: sim, pra `pymobiledevice3 syslog` quando integration test falhar e precisarmos correlacionar com `os_log` (`idevicesyslog` não captura terceiros em iOS 18+, ver `raro-pattern...real-logs`). Install script instala ambos. |
| 15 | Onde o script de install vive? | `apps/mobile/scripts/install-e2e-toolchain.sh` (segue padrão de `scripts/` existente em apps/mobile). Idempotente: detecta cada binário, instala só se ausente. |
| 16 | Bun script no `package.json` raiz ou em `apps/mobile/package.json`? | Em **ambos**: `apps/mobile/package.json` define `test:integration:ios`, e raiz expõe via filter (`bun --filter @raro/mobile run test:integration:ios`). Consistente com `dev:ios` existente. |
| 17 | `--machine --reporter=json | jq` — qual subset do JSON é assertado? | Output é parseado por `jq` para extrair `{ testID, result, time }`. Script falha (exit 1) se qualquer test reportar `result != "success"`. Stopwatch latency é asserted **dentro** do Dart test (não no parser) — `jq` só verifica pass/fail. |
| 18 | Quem chama `flutter pub run pigeon`? | Bun script `bun --filter @raro/mobile run pigeon` (novo). Roda manualmente quando spec mudar. NÃO em pre-commit hook (regen gera 3 arquivos cross-platform — explicit é melhor). Codegen é parte do flow do dev, não automático. |
| 19 | `integration_test` precisa de patches no iOS? | Sim: `apps/mobile/ios/RunnerTests/RunnerTests.swift` já existe (Sessão 1 perf). Para integration_test, Flutter adiciona target separado automaticamente via `flutter create --platforms` quando deps são adicionadas. Verificar via `bun pub:get` que `ios/Flutter/Generated.xcconfig` lista `integration_test`. |
| 20 | Android cobertura nesta sessão? | **Sim mas mínima**: Pigeon Kotlin handler implementa stub que retorna `LensInfo` real (CameraX `Camera.getCameraInfo()`) + `FocusState` real (`Camera2CameraInfo` foco state). Integration test Android pode ser rodado mas **gate principal é iOS** (path crítico do briefing). Smoke Maestro Android: defer Sessão 3. |
| 21 | Esta spec assume ADR-0016 approved? | Sim. Se ADR-0016 ainda estiver `Proposed`, esta spec fica `Draft`. Implementer NÃO inicia até `adr-guardian` confirmar ADR-0016 `Approved`. |

## Observable goals (testes em device)

### G1 — Toolchain local idempotente

- [ ] `bash apps/mobile/scripts/install-e2e-toolchain.sh` instala (se ausente): Maestro CLI (`curl -Ls "https://get.maestro.mobile.dev" | bash`), go-ios (`brew install go-ios`), pymobiledevice3 (`pipx install pymobiledevice3`).
- [ ] Segunda execução do script é no-op (detecta `command -v maestro`, `command -v ios`, `command -v pymobiledevice3` e pula).
- [ ] Script falha rápido (`set -euo pipefail`) e imprime diagnóstico se Homebrew/pipx ausentes — não tenta auto-install desses.
- [ ] Script exporta versões num arquivo `apps/mobile/scripts/.e2e-toolchain.lock` (formato `tool=version`) commitado. Permite detectar drift entre devs.
- [ ] CI (futuro, não nesta spec): script é idempotente o suficiente pra rodar como step.

### G2 — Pigeon `CameraDebugHostApi`

- [ ] Spec file `apps/mobile/pigeons/camera_debug_api.dart` define 3 métodos sync (não async — leitura de state instantânea):
  - `FocusState getFocusPointOfInterest()`
  - `LensInfo getCurrentLens()`
  - `double getZoomFactor()`
- [ ] `bun --filter @raro/mobile run pigeon` gera: Dart (`lib/core/native_bridges/generated/camera_debug_api.g.dart`) + Swift (`ios/Runner/Generated/CameraDebugApi.g.swift`) + Kotlin (`android/app/src/main/kotlin/.../generated/CameraDebugApi.g.kt`).
- [ ] Swift handler `apps/mobile/ios/Runner/CameraDebugBridge.swift`:
  - Implementa `CameraDebugHostApi` (gerado).
  - Lê state do `AVCaptureDevice` ativo (mesma instância que `CameraBridge` usa — injetar via singleton ou property).
  - Guard `#if DEBUG` em volta do registration no `AppDelegate`. Em release, `CameraDebugHostApi.setUp(messenger, nil)` é chamado, ou nem chamado, garantindo que call retorna `FlutterError`.
- [ ] Kotlin handler `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/CameraDebugBridge.kt`:
  - Mesmo padrão. Guard `if (BuildConfig.DEBUG)` no `MainActivity.configureFlutterEngine`.
- [ ] Generated files commitados (ADR-0013 §5).
- [ ] `apps/mobile/lib/core/native_bridges/camera_debug_bridge.dart` — wrapper Dart que expõe `CameraDebugHostApi` com check de `kDebugMode` no construtor:
  ```dart
  CameraDebugBridge() {
    if (!kDebugMode) {
      throw StateError('CameraDebugBridge instantiated outside debug build');
    }
  }
  ```

### G3 — Rota Flutter `/debug/self-test`

- [ ] `go_router` ganha rota condicional em `apps/mobile/lib/core/routing/app_router.dart`:
  ```dart
  if (kDebugMode)
    GoRoute(path: '/debug/self-test', builder: (_, __) => const DebugSelfTestScreen()),
  ```
- [ ] `apps/mobile/lib/features/debug/presentation/debug_self_test_screen.dart`:
  - AppBar com título "Debug — Self-Test".
  - Botão "Run tap-to-focus benchmark" que simula tap em centro do viewport e exibe `FocusState` lido + Stopwatch elapsed.
  - Botão "Read current lens" exibindo `LensInfo` em JSON.
  - **Não acessível em release** (`kDebugMode` false → rota não registrada → 404 do go_router).
- [ ] Acesso manual via `flutter run` no device, navegar para `/debug/self-test` digitando URL no app via deep link (`bun --filter @raro/mobile exec flutter run` + xcrun simctl openurl ou via launcher button só visível em debug).
- [ ] **Não** adicionar atalho de UI permanente na home — rota é descoberta só por quem conhece o path (anti-leak).

### G4 — `integration_test/camera_tap_to_focus_test.dart`

- [ ] Novo arquivo `apps/mobile/integration_test/camera_tap_to_focus_test.dart`:
  - `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
  - `testWidgets('tap-to-focus < 100ms with correct sensor coord', (tester) async { ... })`.
  - Setup: `await tester.pumpWidget(const RaroApp())`, navega para tela câmera, aguarda câmera pronta (`await tester.pumpAndSettle(const Duration(seconds: 2))`).
  - Act: `final viewport = find.byKey(const Key('camera-viewport')); final stopwatch = Stopwatch()..start(); await tester.tap(viewport);`
  - Assert: poll `CameraDebugBridge().getFocusPointOfInterest()` até `focusMode == FocusMode.autoFocus` (poll a cada 5ms, max 200ms).
  - `stopwatch.stop(); expect(stopwatch.elapsedMilliseconds, lessThan(100));`
  - `expect(focusState.x, closeTo(0.5, 0.05)); expect(focusState.y, closeTo(0.5, 0.05));` (tap no centro do viewport = sensor coord ≈ 0.5, 0.5 — `captureDevicePointConverted` já lida com orientação; ver commit `d259d8c`).
  - `expect(focusState.mode, FocusMode.autoFocus);`
- [ ] Test falha se câmera não inicializou em 2s (não silencia).
- [ ] Test passa **só** no iPhone 12 físico (não em Simulator — Simulator não tem câmera real, `AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)` retorna `nil`). Doc isso no header do arquivo.

### G5 — Script `bun run test:integration:ios`

- [ ] `apps/mobile/package.json` ganha script:
  ```json
  "test:integration:ios": "bash scripts/run-integration-ios.sh"
  ```
- [ ] `apps/mobile/scripts/run-integration-ios.sh`:
  - `set -euo pipefail`.
  - Lê `RARO_IOS_DEVICE_UDID` de `.env.local` (gitignored) ou argumento `$1`. Falha se ausente com instrução pra rodar `ios list`.
  - Roda `bun --filter @raro/mobile run pub:get` (encadeia recovery do iOS SPM — `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery`).
  - Roda `flutter test integration_test/camera_tap_to_focus_test.dart -d "$UDID" --machine --reporter=json` pipe `jq -r 'select(.type=="testDone") | "\(.result) \(.testID)"'`.
  - Exit code não-zero se qualquer testDone reportar `result != "success"`.
- [ ] Raiz `package.json` (workspaces) expõe via filter — funciona via `bun --filter @raro/mobile run test:integration:ios` (já é o padrão das outras `dev:ios`/`test:ios`).
- [ ] Script é referenciado em `CLAUDE.md` §13 (tabela "Operação → Comando") após merge.

### G6 — Maestro Simulator smoke

- [ ] `apps/mobile/maestro/smoke-app-launch.yaml`:
  - `appId: com.rarocamera`.
  - Pre-hook: `runScript: { content: "xcrun simctl privacy ${MAESTRO_DEVICE_UDID} grant camera com.rarocamera" }` (permission rehearsal).
  - Steps: `launchApp`, `assertVisible: "RARO"` (texto do splash ou home), `tapOn: "Acessar câmera"` (ou o que o protótipo definir), `assertVisible: { id: "camera-viewport" }`.
  - Post-hook (cleanup): `runScript: { content: "xcrun simctl privacy ${MAESTRO_DEVICE_UDID} revoke camera com.rarocamera" }`.
- [ ] `apps/mobile/scripts/run-maestro-smoke.sh`:
  - Detecta Simulator iPhone 15 disponível: `xcrun simctl list devices available --json | jq -r '.devices | to_entries[] | .value[] | select(.name | test("iPhone 15")) | .udid' | head -1`. Fallback iPhone 14, 13.
  - `xcrun simctl boot $UDID || true`.
  - `flutter build ios --simulator --no-codesign`.
  - `xcrun simctl install $UDID build/ios/iphonesimulator/Runner.app`.
  - `export MAESTRO_DEVICE_UDID=$UDID; maestro test maestro/smoke-app-launch.yaml`.
- [ ] Bun script: `"test:maestro:ios": "bash scripts/run-maestro-smoke.sh"`.
- [ ] **Smoke test não asserta latency** — só pass/fail de launch + permission rehearsal. Latency fica no `integration_test` no device físico (G4).

## UI / protótipo (se aplicável)

- Tela do protótipo: P05 (Câmera) — esta spec não modifica UI da câmera (Surgical Changes).
- Tela nova: `/debug/self-test` — UI não está no protótipo (é developer tooling). Stack pode usar `Scaffold` cru, sem tokens canônicos. Justificativa: nunca chega ao usuário final.
- Tokens canônicos: N/A (debug-only).
- Microinterações: N/A.
- Copy literal: "Debug — Self-Test", "Run tap-to-focus benchmark", "Read current lens". Português pra consistência. **Não menciona** "OkCamera" nem variações (CLAUDE §11).

## Out of scope

Defer pra Sessão 3 ou pós-$99:

- ❌ **Patrol setup.** Requer release build no device físico → requer $99/ano Apple Developer Program. Defer até $99 pago. ADR-0016 §5.
- ❌ **XCTClockMetric measurement.** Audit ADR-0016 marcou como DEFER — `integration_test` Stopwatch é evidência suficiente pra esta sessão. Pode entrar Sessão 3 se Stopwatch mostrar variância > 20% entre runs.
- ❌ **MetricKit bridge.** Audit ADR-0016 marcou como OVERENGINEERING — coleta hangs/disk-writes/CPU em background; útil em produção, não em harness E2E local. Não nesta spec, possivelmente nunca.
- ❌ **Android `integration_test` e Maestro Android.** Kotlin Pigeon handler é stub funcional, mas integration test em Android device físico fica pra Sessão 3 (path crítico do briefing é iOS).
- ❌ **CI integration.** Esta spec entrega tooling local. Rodar `test:integration:ios` em GitHub Actions exige runner com device físico (MacStadium ou similar — custo) ou rodar só `test:maestro:ios` em Simulator (CI grátis). Decisão: defer pra spec separada após validar localmente.
- ❌ **Performance budget tracking histórico** (CSV/SQLite com resultados de cada run). Defer — primeiro temos que ter 1 medição confiável, depois automatizar histórico.
- ❌ **Refactor do `CameraBridge` existente.** `CameraDebugHostApi` é spike read-only; não reorganiza nem reescreve o bridge de produção. Surgical Changes.
- ❌ **Golden test de `/debug/self-test`.** Tela é developer tooling, não vai pro usuário, não vale o overhead de baseline.

## Risks

| Risco | Mitigação |
|-------|-----------|
| Stopwatch no Dart tem resolução pior que `os_log` (lá usamos `mach_absolute_time`). Pode mascarar latency < 5ms. | Aceitável pra esta sessão. Threshold é < 100ms — resolução de Stopwatch (~1ms em ARM64) é folgada. Se precisar precisão sub-ms, escalar pra XCTClockMetric Sessão 3. |
| `CameraDebugHostApi` em release acidentalmente exposto. | Defesa em profundidade: (a) Dart construtor throw se !kDebugMode, (b) rota go_router não registra se !kDebugMode, (c) Swift `#if DEBUG` guard no AppDelegate, (d) Kotlin `BuildConfig.DEBUG` guard. 4 layers — basta 1 funcionar pra bloquear leak. |
| `integration_test` precisa de release build pra ser confiável (debug usa JIT, latency mascarada). | **Real**: debug latency é tipicamente 1.5x release no Flutter. Mitigação: threshold `< 100ms` é conservador — release deve ficar em ~50-60ms. Quando $99 entrar, re-rodar e ajustar threshold se necessário. Documentar nota no test file. |
| `xcrun simctl privacy grant` requer Simulator booted + iOS 17+. | Script detecta `iOS 17 iPhone 15` priority, fallback. Falha rápido com mensagem clara se nenhum Simulator suportado. |
| pymobiledevice3 instalado via pipx pode quebrar com Python system update. | Documentar em README do toolchain script. Se quebrar, rodar `pipx reinstall pymobiledevice3`. Não é blocking — usado só pra debug post-mortem. |
| Pigeon codegen drift (devs esquecem de rodar após mudar spec). | Script `bun run pigeon` documentado no `CLAUDE.md`. Não criar hook automático ainda — explicit melhor que mágico nesta fase. Sessão 3 pode adicionar `verify-task` hook pra checar staleness. |
| `flutter test --machine --reporter=json` formato pode mudar entre Flutter releases. | Pin Flutter `3.44.x` já está no Blueprint. Se Flutter major bump, ADR + spec re-validation. `jq` filter é defensivo (`select(.type=="testDone")`). |
| Tela `/debug/self-test` ser usada como atalho de teste manual e mascarar bugs reais do flow normal. | Doc clara: rota é pra benchmark sintético reprodutível. Bugs de flow real ainda exigem testar via home → câmera. Code review enforce. |
| Integration test flake em device físico (câmera lenta pra inicializar). | `pumpAndSettle(2s)` antes do tap. Se ainda flake, considerar warm-up de 1 tap descartado antes do measured tap. Reportar variância nos primeiros 10 runs. |

## ADRs necessários

- [x] **ADR-0016 — `e2e-harness-hybrid`** (Proposed → deve estar Approved antes do Execute desta spec). Define a stack: Maestro Simulator + integration_test device + Pigeon debug bridge. **Esta spec é a primeira implementação concreta de ADR-0016.**
- [x] ADR-0013 (api-contract-shared) — convenção Pigeon. Já Approved. `CameraDebugHostApi` segue convenção.
- [x] ADR-0014 (flutter-3.44-spm-migration) — restrição iOS 15+. Já Approved. Maestro/integration_test compatíveis.
- [ ] **Não exige ADR novo** além de ADR-0016 (que é o blanket arquitetural). Mudanças subsequentes (CI, threshold tuning) podem ser PRs sem ADR.

## References

- **Briefing**: Seção P05 (Câmera) — requisito "tap-to-focus rápido como câmera nativa".
- **Blueprint**: §2 (stack pinning — Flutter 3.44, pigeon TBD versão via Context7), §5 (Câmera P05), §11 (roadmap native bridge prioridade 1).
- **ADRs**: ADR-0013 (Pigeon convention), ADR-0014 (Flutter 3.44 SPM), **ADR-0016 (e2e-harness-hybrid — base desta spec)**.
- **Commits recentes (contexto perf)**:
  - `3b79021` perf(camera): collapse five sources of perceived tap-to-focus latency
  - `beaeade` perf(camera): render focus ring optimistically + offload focus to sessionqueue
  - `d259d8c` fix(camera): convert tap to sensor coords via capturedevicepointconverted + os_log diagnostic
  - `354ddc3` feat(scaffold): terminal-first ios workflow + test:ios script
  - `cba16ce` refactor(camera): replace atomic bool with main-queue property
- **Specs relacionadas**: `docs/superpowers/specs/2026-XX-XX-api-contract-shared-design.md` (ADR-0013), `docs/superpowers/specs/2026-XX-XX-flutter-3.44-spm-migration-design.md` (ADR-0014).
- **Memórias relevantes** (`~/.claude/projects/.../memory/`):
  - `feedback_device_debug_use_real_logs_not_assumptions.md` — Stopwatch + Pigeon state probe substitui inspeção visual.
  - `feedback_ios_workflow_terminal_first_no_xcode_build.md` — `bun run test:integration:ios` segue esse padrão.
  - `feedback_tdd_pin_behavior_not_type.md` — test asserta `closeTo` + enum + latency, não `isA<FocusState>`.
  - `raro-pattern-flutter-debug-vs-release-on-device.md` — explica por que Patrol fica defer pós-$99.
  - `raro-pattern-flutter-ios-regen-xcconfig-spm-recovery.md` — script encadeia `pub:get` em pre-flight.
- **Context7 queries pendentes (researcher)**:
  - `pigeon` Dart package — versão latest compatível com Flutter 3.44.
  - `integration_test` — confirmar API atual `IntegrationTestWidgetsFlutterBinding`.
  - Maestro CLI — confirmar formato YAML `runScript` e variável `MAESTRO_DEVICE_UDID`.
  - `go-ios` — versão Homebrew estável.
  - `pymobiledevice3` — versão pipx estável.

---

## Definition of Done (resumo executivo)

Spec é Done quando:

1. `bash apps/mobile/scripts/install-e2e-toolchain.sh` roda 2× e segunda execução é no-op (G1).
2. `bun --filter @raro/mobile run pigeon` gera 3 arquivos commitados (G2).
3. `flutter run` em debug + navegar `/debug/self-test` mostra tela com 2 botões funcionais (G3).
4. `bun --filter @raro/mobile run test:integration:ios` no iPhone 12 físico passa com latency reportada < 100ms e `focusMode == autoFocus` (G4, G5).
5. `bun --filter @raro/mobile run test:maestro:ios` no Simulator iPhone 15 passa com permission rehearsal (G6).
6. `/verify-slice` orquestra: analyze + integration test + maestro smoke + adr-guardian confirma ADR-0016 referenciado.
7. Session log de Sessão 2 commitado em `docs/sessions/` referenciando esta spec.
8. `CLAUDE.md` §13 tabela atualizada com `test:integration:ios` e `test:maestro:ios`.
9. Anti-pattern adicional adicionado em CLAUDE §11 se aprendizado novo emergir (ex: "❌ Não acessar `CameraDebugHostApi` fora de `kDebugMode`").

Não declarar Done sem evidência de cada item acima (Goal-Driven Execution — Karpathy #4).
