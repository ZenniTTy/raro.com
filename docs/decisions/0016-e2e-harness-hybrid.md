# 0016 — E2E test harness híbrido (integration_test + Pigeon debug + Maestro Simulator + Patrol pós-Dev Program)

- **Data:** 2026-05-29
- **Status:** Proposed
- **Decisores:** Eduardo Rodrigues (Elovision)
- **Contexto:** Audit workflow `wwe1u6vm0` (2026-05-29) — avaliação dos frameworks E2E iOS face às restrições atuais (free tier Apple) e janela de upgrade ($99/ano Apple Developer Program em ~30 dias)

## Contexto

A spec `camera-native-bridge` foi entregue em 2026-05-28 (session 0005) e as validações G1-G7 + G10 foram cobertas em **debug + Cmd+R no iPhone 12**. Restaram dois grupos de gaps:

1. **Gates G8/G9 (lifecycle real)** — background→foreground após Settings.app, permission denied → `openAppSettings` → volta, interrupção por chamada/Siri. Em debug + free tier (sem Apple Developer Program) só validáveis manualmente via Control Center / multitasking parcial. Não automatizáveis.
2. **Bridges futuros (`replay_buffer`, `voice`, `volume`)** vão herdar o mesmo gap se não houver harness E2E desde o início. `volume` em particular depende de evento físico de hardware button (KVO em `AVAudioSession.outputVolume`) impossível de simular em XCTest puro sem interação real.

Em paralelo, o Blueprint Seção 11 nunca decidiu **qual framework E2E** o projeto adota. O placeholder mencionava "Maestro ou Patrol" sem rationale. A escolha precisa ser feita agora porque:

- A spec do `volume` bridge entra na fila pós-camera RC.
- Cada framework tem restrições incompatíveis com nosso setup atual.
- Trocar de framework a meio caminho custa re-escrever todos os fluxos.

### Restrições de cada framework E2E iOS (audit 2026-05-29)

| Framework | Versão | iPhone físico free tier | iPhone físico com Apple Dev | Simulator | Dependências |
|---|---|---|---|---|---|
| **Maestro CLI** | 2.6.0 | ❌ não oficial — funciona ad-hoc mas sem suporte e instável a cada release iOS | ⚠️ funciona, mas mantenedores priorizam Simulator | ✅ oficial e estável | `idb` (Facebook) + Java |
| **Patrol** | 4.6.1 | ❌ exige Apple Dev ($99/ano) para code-sign do PatrolRunner.app | ✅ oficial — single source of truth (`patrol test`) | ✅ oficial | XCTest + Patrol CLI |
| **XCUITest puro** | — | ❌ mesmo bloqueio de code-signing do PatrolRunner | ✅ stdlib Apple | ✅ stdlib Apple | Xcode |
| **integration_test (Flutter)** | bundled 3.44 | ⚠️ debug-only no device (driver via `--machine`); release exige Dev Program | ✅ ambos modos | ✅ ambos modos | flutter_test + driver |
| **flutter_driver** | bundled | depreciado, mesmas limitações | depreciado | depreciado | — |

### Restrições específicas do nosso bridge

- **camera bridge** (`PlatformView` AVFoundation): nenhum framework E2E enxerga conteúdo do `CALayer` nativo. Validar "preview live" só por **side-effects** (frame timestamp, FPS counter exposto via Pigeon debug, screenshot de pixel comparado contra mock).
- **volume bridge** (futuro): KVO em hardware button é impossível em XCTest puro. Patrol oferece `nativeAutomator.pressHardwareButton(volumeUp/Down)` em iOS 16+ via Accessibility API — mas exige Dev Program.
- **voice bridge** (futuro): `SFSpeechRecognizer` exige `requestAuthorization` real (não simulável). Mesmo gap de `permission_handler` documentado em ADR-0015 Apêndice D.

### Janela de mudança

Usuário confirmou (2026-05-29) que vai comprar Apple Developer Program ($99/ano) em ~30 dias. Após isso, Patrol vira viável no iPhone físico real. Antes disso, qualquer escolha de framework precisa funcionar **sem** Dev Program. A decisão precisa ser **incremental** — não pode forçar reescrita quando o upgrade chegar.

## Opções consideradas

1. **Patrol-only desde já (free tier)**
   - Prós: single source of truth, Dart end-to-end, nativeAutomator cobre permissões e botões de hardware
   - Contras: bloqueado em iPhone físico sem Dev Program. Forçaria só Simulator nos próximos 30 dias, e Simulator não valida camera real (sem hardware ultra-wide, sem AVCaptureSession real, sem KVO de volume). Inútil para os nossos casos críticos
2. **Maestro-only**
   - Prós: roda em Simulator hoje, sintaxe YAML simples, paywall/onboarding/login cobertos rápido
   - Contras: iPhone físico não oficial (frágil a cada release iOS); zero acesso a APIs internas Flutter (state Riverpod, Pigeon mocks); não valida side-effects de bridge nativa (FPS, frame timestamp). Insuficiente para camera/volume/voice
3. **XCUITest puro**
   - Prós: stdlib Apple, sem deps externas
   - Contras: mesmo bloqueio de code-signing do Patrol no free tier; zero integração Flutter; reescreveria toda a stack quando Patrol entrar
4. **Hybrid: integration_test --machine + Pigeon debug-channel + rota `/debug/self-test` + Maestro Simulator (selecionado)**
   - Prós: cobre **agora** tudo o que é coberto sem Dev Program; reutiliza Pigeon (zero novo bridge); migra incrementalmente para Patrol quando Dev Program chegar sem rewrite
   - Contras: três ferramentas em vez de uma; rota `/debug/self-test` precisa de gate `kDebugMode` para não vazar em release; precisa de manutenção de `CameraDebugHostApi` separada do `CameraHostApi` produção
5. **Postpone E2E até Apple Dev Program comprado**
   - Prós: zero overhead nos próximos 30 dias
   - Contras: bridges `volume` e `voice` entram na fila sem rede de segurança; valida na mão a cada commit; aumenta risco de regression pré-RC

## Decisão

Adotamos a **opção 4 (Hybrid)** com **upgrade incremental para Patrol em iPhone físico** após Apple Developer Program ser comprado (~30 dias).

### Camadas do harness

1. **`integration_test --machine` em debug** (camada 1, fluxos Flutter-puro)
   - Cobre: navegação, paywall (RevenueCat mock), onboarding, settings, permission flow Dart-side, theme/i18n
   - Roda: iPhone 12 físico em debug + Simulator. Output JSON consumível por CI script
   - Driver custom: `apps/mobile/test/e2e/driver.dart` (já scaffoldado no `flutter_test`)
   - Comando: `bun --filter @raro/mobile run test:e2e:flutter`

2. **Pigeon debug-channel `CameraDebugHostApi`** (camada 2, side-effects de bridge)
   - Schema novo em `apps/mobile/pigeons/camera_debug.dart`. Sub-package Kotlin `com.rarocamera.raro_mobile.generated.camera_debug` (ADR-0013 anti-redeclaration)
   - Exporta: `getLastFrameTimestamp()`, `getCurrentFps()`, `getActiveDeviceId()`, `getZoomFactor()`, `getInterruptionState()`, `simulatePermissionDenied()` (test-only stub)
   - **Gated por `kDebugMode`** no Dart side + `#if DEBUG` no Swift/Kotlin. Build release não inclui (codegen condicional). Hook PreToolUse `block-debug-api-in-release.sh` (a criar) garante que `CameraDebugHostApi` nunca apareça em `lib/main_production.dart`
   - Permite: assertions tipo `expect(await debug.getCurrentFps(), greaterThan(55))` em integration_test sem precisar parsear logs de OS

3. **Rota `/debug/self-test`** (camada 3, fluxo end-to-end orquestrado)
   - Em `kDebugMode`, `RaroRouter` registra `/debug/self-test` que executa checklist hardcoded (start session → switch lens 0.5x→1x → assert FPS → stop). Resultado renderizado em ListTile pass/fail. Compartilhável via Maestro (que só precisa tocar botão Run e capturar screenshot)
   - Não aparece em release builds (router gated)

4. **`go-ios` + `pymobiledevice3`** (camada 4, instrumentação externa)
   - `ios-deploy` / `idevicesyslog` falham em iOS 18+ (não capturam logs de apps de terceiros). Substituídos por:
   - `go-ios` (Apple WebDriverAgent fork sem precisar Xcode) para launch + log streaming
   - `pymobiledevice3` para file copy (extrair `.har`/`.png` de side-effect testing)
   - Sem dependência de Dev Program. Usado pelo CI script para coletar logs entre runs

5. **Maestro CLI Simulator** (camada 5, fluxos não-camera)
   - Cobre: paywall trial → upgrade flow, onboarding completo, deep link, settings nav, accessibility happy path
   - Roda **só em Simulator** (sem device físico) — `device` quirks ignorados nesta camada
   - Scripts em `apps/mobile/test/maestro/*.yaml`
   - Comando: `bun --filter @raro/mobile run test:e2e:maestro`

### Pós Apple Developer Program (~30 dias)

Quando Dev Program for comprado:

1. **Patrol 4.6.1+** entra para cobrir o que requer device físico real com permission dialog real e hardware buttons:
   - `volume` bridge: `nativeAutomator.pressVolumeUp()` valida KVO
   - `voice` bridge: dispara `SFSpeechRecognizer.requestAuthorization()` real
   - `camera` permission: trigger do dialog iOS real (não simulado), garantia que `permission_handler` macros funcionam end-to-end
   - Background/foreground real (G8/G9 ADR-0015): `nativeAutomator.openQuickSettings()`, `nativeAutomator.openApp()`
2. **integration_test continua** para fluxos Flutter-puro (camada 1) — Patrol coexiste, não substitui
3. **Pigeon debug-channel continua** porque side-effects de bridge ainda precisam de hook tipado
4. **Maestro pode ser depreciado** se Patrol cobrir os mesmos fluxos com menos manutenção. Decisão diferida para o momento.

### Gates obrigatórios

- **Hook PreToolUse `block-debug-api-in-release.sh`**: bloqueia import de `CameraDebugHostApi` em qualquer arquivo que não esteja sob `test/` ou guarded por `kDebugMode`
- **Suite `test/contract/no_debug_api_in_release.dart`**: regex scan garante que `apps/mobile/lib/main_production.dart` e qualquer entrypoint release-flagged nunca referenciam o debug channel
- **CI matrix**: `test:e2e:flutter` roda em PR; `test:e2e:maestro` roda em nightly (Simulator). Patrol entra como job adicional após Dev Program
- **`/verify-slice` atualizado** para incluir `test:e2e:flutter` quando spec tocar bridge ou navegação

## Consequências

**Positivas:**

- E2E cobertura disponível **hoje** sem esperar Apple Dev Program
- Reuso de Pigeon (zero novo paradigma de bridge para subagents/devs aprenderem)
- Camera/volume/voice ganham assertion-grade side-effect checks (FPS, zoom factor, interruption state) sem grep de logs
- Migração para Patrol é **aditiva**, não destrutiva — fluxos existentes continuam funcionando
- `kDebugMode` gating impede vazar surface de debug em release (App Store rejection-proof)
- `go-ios` + `pymobiledevice3` resolvem a limitação documentada do `idevicesyslog` (memória `feedback_device_debug_use_real_logs_not_assumptions`)

**Negativas:**

- **Três ferramentas** em vez de uma. Custo cognitivo para devs novos
- `CameraDebugHostApi` é superfície de manutenção paralela ao `CameraHostApi` — cada novo método produção tipicamente pede método debug equivalente
- Maestro YAML não é Dart — context-switch entre `dart test` e `maestro test`
- Rota `/debug/self-test` precisa ser ignorada por design-fidelity-checker (não é tela de produto)
- `go-ios` + `pymobiledevice3` adicionam deps Python/Go ao workflow CI — mitigado por GitHub Action oficial

**Neutras:**

- Patrol fica de fora dos próximos 30 dias mas é **escolha planejada**, não esquecida. Spec de upgrade Patrol já vai estar pré-redigida em `docs/superpowers/specs/TBD-patrol-upgrade.md` quando Dev Program for comprado

**Como reverter:**

- Se Patrol pós-Dev Program cobrir 100% dos casos, deprecar Maestro (camada 5) — remover `apps/mobile/test/maestro/*` e job CI correspondente. integration_test + Pigeon debug ficam
- Se Pigeon debug-channel virar fardo (ex: muita duplicação de método), substituir por single `DebugHostApi.invoke(method, args)` genérico — perda de type safety mas redução de surface. ADR-update no momento, não preventivo

## Alternativas consideradas (rationale de rejeição)

- **Patrol-only desde já**: bloqueado por code-signing no free tier (Patrol exige `PatrolRunner.app` assinado, e Apple Development cert sem Dev Program falha). Forçaria Simulator-only nos próximos 30 dias — Simulator não valida camera real (sem ultra-wide hardware), volume button (sem hardware), nem permission dialog real. Inútil para os casos críticos
- **Maestro-only**: iPhone físico não oficial (mantenedores priorizam Simulator); zero integração Flutter (não enxerga state Riverpod nem invoca Pigeon); insuficiente para side-effects de bridge. Bom para fluxos UI-puro mas não para camera/voice/volume
- **XCUITest puro**: mesmo bloqueio de code-signing do Patrol; zero integração Dart; ao adotar Patrol depois, todos os testes seriam reescritos. Sunk cost desnecessário
- **Postpone E2E até Dev Program**: bridges `volume` e `voice` entrariam na fila sem rede; cada PR validado manualmente; alto risco de regression pré-RC. Custo de não decidir > custo de adotar híbrido
- **Appium**: rejeitado em audit por overhead WebDriver, sem benefício sobre Patrol pós-Dev Program
- **Flutter Driver legado**: depreciado pelo time Flutter; integration_test é o sucessor oficial

## Cross-refs

- **Spec relacionada (a criar):** `docs/superpowers/specs/2026-05-29-e2e-harness-hybrid-design.md`
- **ADRs predecessores:**
  - [0002 — Camera native bridge](0002-camera-native-bridge.md) — define os bridges que esta ADR testa
  - [0013 — Pigeon + Theme Tailor + gates anti-drift](0013-pigeon-theme-tailor-and-anti-drift-gates.md) — Pigeon é o paradigma reusado pelo debug-channel
  - [0014 — Flutter 3.44 + SPM + iOS 15](0014-flutter-3.44-spm-ios-15.md) — restrição mínima da plataforma
  - [0015 — Camera native bridge strategy](0015-camera-native-bridge-strategy.md) Apêndice G — documenta limitação free tier que motiva esta decisão
- **Sessions:**
  - `docs/sessions/0005-camera-device-validation.md` — origem do gap G8/G9 que esta ADR endereça
- **Memórias persistentes referenciadas:**
  - `feedback_device_debug_use_real_logs_not_assumptions` — porque `go-ios`/`pymobiledevice3` substituem `idevicesyslog`
  - `raro-pattern-flutter-debug-vs-release-on-device` — porque release-only path exige Dev Program
  - `raro-pattern-permission-handler-ios-podfile-macros` — porque permission dialog real só Patrol+Dev Program valida
  - `feedback_ios_workflow_terminal_first_no_xcode_build` — CI script terminal-first é coerente com esta camada
- **Audit workflow input:** `wwe1u6vm0` (2026-05-29)
- **Docs externos:**
  - Patrol: https://patrol.leancode.co/
  - Maestro: https://maestro.mobile.dev/
  - Pigeon: https://pub.dev/packages/pigeon
  - go-ios: https://github.com/danielpaulus/go-ios
  - pymobiledevice3: https://github.com/doronz88/pymobiledevice3
  - integration_test --machine: https://docs.flutter.dev/cookbook/testing/integration/introduction

## Trigger de revisão

Esta ADR vira candidata a `Superseded` quando:

1. Apple Developer Program for comprado E Patrol cobrir 100% dos fluxos hoje cobertos por Maestro + integration_test → simplificar para Patrol+Pigeon-debug
2. OU Pigeon debug-channel virar surface de manutenção desproporcional (>40% dos métodos do bridge produção têm contrapartida debug) → consolidar em single `DebugHostApi` genérico ou trocar por instrumentação via Sentry/OpenTelemetry de side-effects
3. OU integration_test --machine for depreciado pelo Flutter team (improvável <2 anos)
