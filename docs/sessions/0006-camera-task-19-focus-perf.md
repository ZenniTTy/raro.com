# 0006 — camera task 19: focus ring nativo + perf 5 root causes

- **Data:** 2026-05-29
- **Duração:** ~7h (incluindo ~2.6M tokens em 3 workflows de audit autônomos)
- **Participantes:** Eduardo Rodrigues + Claude Code
- **Branch:** `feat/camera-native-bridge`
- **Spec:** [`docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md`](../superpowers/specs/2026-05-28-camera-task-19-closure-design.md)
- **Plan:** referência ao plan `camera-native-bridge` Task 19 (G4 e perf)
- **ADR:** [`docs/decisions/0015-camera-native-bridge-strategy.md`](../decisions/0015-camera-native-bridge-strategy.md) (nota pendente sobre os 5 fixes de latência — ver `## Próximos passos`)
- **Commits (cronológico):** `cba16ce` → `78e584a` → `354ddc3` → `d259d8c` → `beaeade` → `3b79021`

---

## Objetivo

Fechar o **G4 (focus ring nativo)** deixado explicitamente pendente em 0005 e **colapsar a latência perceptual de tap-to-focus** no iPhone 12. Alvo: ring renderizar em ≤16ms (1 frame @60fps) e focus settle ≤200ms p50, sem quebrar nenhum dos 7 goals já validados (G1, G2, G3, G5, G6, G8, G9).

Sub-objetivo: estabelecer **workflow iOS terminal-first** definitivamente, fechando o anti-pattern recorrente do loop SPM Firebase 15 vs 13 e da regressão de Pre-action documentada em 0005.

---

## Contexto inicial

- Estado pós-0005: G4 era único bloqueio funcional remanescente da Task 19. Abordagem Flutter `Stack` + `CustomPaint` sobre `UiKitView` já descartada (quebra hybrid composition do iOS).
- Logs perceptuais de 0005 sugeriam delay agregado tap→ring no iPhone 12 maior que o esperado, mas **sem instrumentação fine-grained** — não havia hipótese causal concreta.
- Testes unitários do focus KVO escritos em 0004 estavam GREEN em isolamento (Simulator), mas não capturavam o problema porque trabalhavam fora do stack real Flutter → MethodChannel → `AVCaptureDevice`.
- Branch já trazia commits `cba16ce` e `78e584a` (sessão emendada): refactor do focus KVO removendo `AtomicBool` em favor de `focusWasAdjusting` em main queue serial, timeout cancellation determinístico, fix do closure-capture point.

---

## O que foi feito

### 1. C1 — Focus KVO: timeout + closure-capture + remoção de AtomicBool (`cba16ce`, `78e584a`)

- `AtomicBool` substituído por property `focusWasAdjusting` lida/escrita exclusivamente na main queue serial — elimina double-fire em races sob carga.
- Timeout do focus convertido para `DispatchWorkItem` cancelável determinístico (era `asyncAfter` solto, race com KVO settle).
- Closure-capture point corrigido — KVO observer estava capturando `self` strong dentro do `addObserver(forKeyPath:options:context:)` por engano sintático; convertido para `[weak self]` com guard.

### 2. C2 — Sensor coords + os_log (`d259d8c`)

- Conversão de tap coords substituída por `device.captureDevicePointConverted(fromLayerPoint:)` (API oficial AVFoundation). Cálculo manual anterior (`CGPoint(x: y/height, y: 1 - x/width)` com swap de eixos) divergia em devices com diferentes `videoOrientation`.
- Subsystem `os_log` estruturado: `OSLog(subsystem: "com.rarocamera", category: "focus")`. Pontos instrumentados: tap recebido, lockForConfiguration, focusPointOfInterest setado, KVO settle, timeout, error path.
- Diagnóstico via `log stream --predicate 'subsystem == "com.rarocamera"'` no terminal do Mac com iPhone 12 conectado por cabo.

### 3. C3 — Render otimista + offload + fire-and-forget (`beaeade`)

- Ring desenha **antes** do `lockForConfiguration` — usuário vê feedback visual instantâneo enquanto o AVCaptureDevice processa.
- Toda a sequência de configuração de focus (`lockForConfiguration` → `focusPointOfInterest` → `focusMode` → `unlockForConfiguration`) **offloaded para `sessionQueue`** (DispatchQueue serial dedicada). Antes rodava na main queue e bloqueava UI thread por ~30-50ms.
- Dart side mudado para `unawaited(_channel.invokeMethod('focusAt', ...))` — Flutter não bloqueia em await desnecessário porque ring já foi renderizado otimisticamente.

### 4. C4 — 5 root causes colapsados (`3b79021`)

Cinco fontes independentes de latência identificadas via os_log diagnostic + leitura cuidadosa de docs AVFoundation/Flutter:

| # | Causa | Fix | Impacto p50 |
|---|---|---|---|
| a | `isSmoothAutoFocusEnabled = true` (default em formats que suportam) injeta ramp cinematográfico | Setar `false` dentro de `lockForConfiguration` ANTES de `focusPointOfInterest`; manter `true` apenas durante gravação de vídeo | -150 a -400ms |
| b | Debounce de KVO settle estava em 100ms (legado de prototipagem) | Reduzido para 16ms (~1 frame @60fps) | -84ms |
| c | `UiKitView` SEM `gestureRecognizers` explícito atrasa propagação do tap (Flutter issue #170735) | `gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new)}` reclama gesture imediatamente | -80ms baseline |
| d | KVO de `isAdjustingFocus` estava sendo re-registrado por tap (churn de observer + 5-20ms) | Instalado UMA vez em `startSession`, invalidado em `stopSession`; property `pendingFocusPoint` coordena qual tap o callback resolve com sucesso/timeout | -5 a -20ms + estabilidade |
| e | Ring layer não renderizava sub-frame por config errada de `CATransaction` | Tentativa inicial com `CATransaction.begin/setDisableActions(true)/commit` quebrou teste `testShowFocusRingAnimationsConfigured` (vide anti-pattern #2 abaixo); `CATransaction.flush()` sozinho removeu animation pelo `removedOnCompletion=true` default; fix final: `setNeedsDisplay` após `addSublayer` preserva animation registrada E força layout/render imediato | render <16ms confirmado em Simulator |

Resultado agregado esperado em iPhone 12: tap → ring visível ≤16ms, focus settle p50 ≤200ms. **Pendente validação perceptual no device físico** (próxima sessão).

### 5. Terminal-first iOS workflow (`354ddc3`)

- `scripts/run-ios-native-tests.sh` — auto-detecta Simulator disponível (iPhone 17 Pro → 16 → 15 → 14 → 13 fallback), encadeia `flutter pub get` + `fix-spm` (Package.swift iOS 13→15) + `xcodebuild test`.
- `package.json` scripts adicionados: `dev:ios`, `test:ios` (apps/mobile).
- `bun --filter @raro/mobile run dev:ios -- -d <udid>` encadeia: `flutter pub get` → fix-spm sed → bootstrap-permissions → `flutter run`.
- **CLAUDE.md §13 novo:** documenta workflow terminal-first + lista taxativa de operações que **proibido** fazer no Xcode UI (build ⌘B, run ⌘R, Reset Package Caches via UI). Xcode UI restrito a: signing/capabilities, debug attach, asset catalog inspection, Scheme Pre-action edit (excepcional).

### 6. Workflows de audit autônomos executados

Três workflows paralelos consumindo ~2.6M tokens de contexto. Cada um produziu relatório que validou ou refutou decisões:

| ID | Foco | Conclusão |
|---|---|---|
| `wc7955ttk` | Por que testes verdes não pegaram delay + inventário tooling perf 2026 | Propôs Pigeon telemetry + MetricKit + XCTClockMetric — **maioria deferida** após audit `w3cediota` (ver próximo) |
| `w3cediota` | Audit adversarial item-por-item dos 18 itens do plano original | **13 OVERENGINEERING/DEFER, 5 HIGH_VALUE, 0 ESSENTIAL.** Anti-pattern descoberto: "infra de observabilidade antes de fix conhecido é inverso de 'log antes de fix'" — quando causa técnica está mapeada concretamente, fix primeiro |
| `wwe1u6vm0` | Audit harness E2E (Maestro? Patrol? integration_test? custom?) | Maestro iOS NÃO suporta iPhone físico oficial. Patrol exige Apple Dev pago. Recomendação: **Hybrid integration_test --machine + Pigeon CameraDebugHostApi + rota `/debug/self-test` guardada por `kDebugMode` + go-ios/pymobiledevice3 + Maestro Simulator para fluxos não-camera** |

### 7. Validações batidas (gates)

| Gate | Status |
|---|---|
| Flutter widget/unit tests | 66/66 PASS |
| Native iOS tests (RunnerTests no iPhone 17 Pro Simulator) | 5/5 PASS — `CameraManagerFocusTests`, `CameraPlatformViewTests` |
| Contract tests pre-push (lefthook) | 30/30 PASS |
| `flutter analyze` | GREEN |
| lefthook (block-secrets + dart-format + commitlint) | GREEN em todos os commits — **zero `--no-verify`** |
| Push `origin/feat/camera-native-bridge` | concluído |

---

## O que NÃO foi feito (e por quê)

### G4 perceptual validation no iPhone 12 físico

- Tecnicamente fechado nos commits, mas **falta confirmação perceptual em hardware real**.
- Depende do usuário rodar `bun --filter @raro/mobile run dev:ios -- -d <udid>` com iPhone 12 conectado e validar manualmente <16ms ring + <200ms settle.
- Pendência: próxima janela de trabalho.

### G1 (cold start ≤500ms) e G7 (memory release ≤200ms) — métricas reais

- Continuam pendentes de instrumentação. Plano: capturar via integration_test `--machine` + Pigeon `CameraDebugHostApi` na Sessão 2.
- Não foi feito agora porque depende do harness E2E híbrido (ver Próximos passos Opção A).

### G10 — iPad

- Sem hardware iPad para validar. Postergado indefinidamente, sem impacto em release v1.0 (Blueprint não compromete iPad).

### ADR-0015 — adendum sobre os 5 fixes de latência

- ADR continua `Approved`. **Não foi escrito** o addendum específico cobrindo as 5 causas + decisão de SmoothAutoFocus tap-vs-record + KVO permanente.
- Sugerido para Sessão 2, junto com merge `feat/camera-native-bridge` → `develop`.

### Spec `2026-05-28-camera-task-19-closure-design.md` — status update

- Spec não foi reescrita ainda. Status atual no arquivo está desatualizado: G4 ring nativo deve ir para **Done**, G1/G7 perf para **In progress (Session 2)**, Samsung M54 para **Deferred**.

### Harness E2E híbrido (integration_test + Pigeon + go-ios + Maestro Simulator)

- Recomendação do audit `wwe1u6vm0` aceita mas não implementada. Planejada como entregável central da Sessão 2.

### Patrol upgrade

- Bloqueado por Apple Dev Program $99 ainda não pago. Usuário confirmou pagamento nos próximos 30d → Sessão futura (4 ou 5) cobre upgrade para Volume bridge + permission dialog real automation.

---

## Decisões

| # | Decisão | Justificativa |
|---|---|---|
| D1 | Focus ring é **CALayer nativo dentro do PlatformView iOS**, não Flutter Stack/CustomPaint sobreposto | Hybrid composition do `UiKitView` reordena z-index e atrasa primeiro frame; ring precisa estar dentro da view nativa para garantir <16ms |
| D2 | `isSmoothAutoFocusEnabled = false` durante tap, `true` durante record | Tap exige resposta instantânea (UX); record exige suavidade cinematográfica (qualidade percebida) — trade-off explícito em vez de single setting |
| D3 | KVO de `isAdjustingFocus` é **permanente** (install em startSession, invalidate em stopSession) | Re-registrar por tap adiciona 5-20ms + churn de observer. Coordenação via property `pendingFocusPoint` |
| D4 | Workflow iOS é **terminal-first definitivo** (CLAUDE.md §13) | Xcode UI Build/Run pula `fix-spm` Pre-action em SPM Resolve automático, causando regressão recorrente Firebase 15 vs 13. Terminal encadeia recovery sempre |
| D5 | Harness E2E será **híbrido (integration_test --machine + Pigeon + Maestro Simulator)**, não Maestro puro nem Patrol agora | Maestro iOS não suporta iPhone físico oficial; Patrol exige $99 Apple Dev. Híbrido é o único caminho que cobre iPhone 12 físico hoje |
| D6 | Plano original de 18 itens de instrumentação foi **podado para 5** após audit adversarial | "Infra de observabilidade antes de fix conhecido" é anti-pattern invertido. Causas técnicas já estavam mapeadas — fix direto economiza esforço |

---

## Anti-patterns descobertos (registrar como memória + CLAUDE.md §11)

### AP-1 — "Infra de observabilidade antes de fix conhecido" é anti-pattern invertido

- Inverso de "logs reais antes de fix" (lição 0005). Aplica-se quando **causas técnicas já estão mapeadas concretamente**.
- Workflow audit `w3cediota` revelou que plano original de 18 itens era 13 overengineering/defer + 5 high-value + 0 essential.
- Regra: se há hipótese causal concreta → fix primeiro, instrumentar apenas se delay residual. Se há sintoma sem causa → logs primeiro (lição 0005).

### AP-2 — `CATransaction.setDisableActions(true)` quebra `layer.add(animation, forKey:)` em testes

- `setDisableActions(true)` ao redor de `layer.add(animation, forKey:)` **desabilita a registration interna** — `layer.animation(forKey:)` retorna `nil` em testes.
- Uso correto: apenas em torno de mutations de propriedade (`bounds`, `position`, `path`) que precisam pular implicit animation, **não** em torno de explicit registration.

### AP-3 — `CATransaction.flush()` força commit sync mas remove animation com `removedOnCompletion=true`

- Animation com `removedOnCompletion=true` (default) é removida pelo runtime assim que duração termina.
- Testes que leem `layer.animation(forKey:)` logo após `showFocusRing` podem ver `nil` se houver `flush()`.
- Para sub-frame display sem perder registration: `setNeedsDisplay` funciona, `flush` não.

### AP-4 — Flutter `UiKitView`/`AndroidView` sem `gestureRecognizers` explícito atrasa tap ~80ms

- Flutter issue [#170735](https://github.com/flutter/flutter/issues/170735).
- Fix: `gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new)}` reclama gesture imediatamente em vez de aguardar arena resolution.

### AP-5 — `AVCaptureDevice.isSmoothAutoFocusEnabled = true` adiciona ramp 150-400ms

- Default `true` em formats que suportam — é a feature "Cinematic AF" da Apple.
- Para tap-to-focus responsivo: `device.isSmoothAutoFocusEnabled = false` dentro de `lockForConfiguration` ANTES de setar `focusPointOfInterest`.
- Para gravação de vídeo: manter `true` (UX espera suavidade cinematográfica em pan).

### AP-6 — KVO de `isAdjustingFocus` deve ser permanente, não per-tap

- Re-registrar `addObserver(forKeyPath:options:context:)` por tap adiciona 5-20ms + churn.
- Instalar UMA vez em `startSession`, invalidar em `stopSession`.
- Coordenar qual tap o callback resolve via property `pendingFocusPoint` (set no tap, lido no observer, cleared no settle/timeout/error).

---

## Próximos passos

### Opção A — Sessão 2: harness E2E híbrido + primeiro teste tap-to-focus

- Implementar `integration_test --machine` + Pigeon `CameraDebugHostApi` + rota `/debug/self-test` guardada por `kDebugMode` + `go-ios` ou `pymobiledevice3` para device control + Maestro Simulator para fluxos não-camera.
- Primeiro teste `camera_tap_to_focus_test.dart` rodando em ~90s no iPhone 12.
- Permite capturar métricas reais para G1 (cold start) e G7 (memory release).

### Opção B — Sessão usuário: validação perceptual no iPhone 12 + merge

- Eduardo roda `bun --filter @raro/mobile run dev:ios -- -d <udid>` e confirma percepção <16ms ring + <200ms settle.
- Se OK → fecha G4 formalmente, atualiza spec status, escreve ADR-0015 addendum, mergeia `feat/camera-native-bridge` → `develop`.

### Opção C — Quando $99 Apple Dev cair (em 30d)

- Migrar para Patrol completo cobrindo Volume bridge + permission dialogs reais.
- Integra com fluxo Patrol → CI no GitHub Actions com self-hosted runner Mac mini.

### Recomendação consolidada

1. **Opção B primeiro** — destrava merge da spec camera-native-bridge sem depender de novo harness.
2. **Opção A em paralelo** — instrumenta G1/G7 que ainda precisam métrica real, sem bloquear merge.
3. **Opção C quando $99 cair** — incremental, não bloqueia v1.0.

---

## Recovery (próxima sessão)

Se retomar do zero, executar nesta ordem:

```bash
# 1. Estado do repo
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git status
git log --oneline -10 feat/camera-native-bridge

# 2. Re-prime contexto
# (no Claude Code) /prime

# 3. Re-leia esta session + a 0005
# docs/sessions/0005-camera-device-validation.md
# docs/sessions/0006-camera-task-19-focus-perf.md

# 4. Confirme estado dos testes
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
bun --filter @raro/mobile run test:ios

# 5. Para validação perceptual (Opção B)
bun --filter @raro/mobile run dev:ios -- -d <udid-iphone-12>

# 6. Para harness E2E (Opção A)
# /new-spec camera-e2e-harness-hybrid
```

---

## Referências

### Commits desta sessão

| Hash | Mensagem |
|---|---|
| `cba16ce` | refactor(camera): replace atomic bool with main-queue property |
| `78e584a` | (fix focus KVO closure capture + timeout cancellation) |
| `354ddc3` | feat(scaffold): terminal-first ios workflow + test:ios script |
| `d259d8c` | fix(camera): convert tap to sensor coords via capturedevicepointconverted + os_log diagnostic |
| `beaeade` | perf(camera): render focus ring optimistically + offload focus to sessionqueue + fire-and-forget tap |
| `3b79021` | perf(camera): collapse five sources of perceived tap-to-focus latency |

### Docs internas

- ADR-0015: [`docs/decisions/0015-camera-native-bridge-strategy.md`](../decisions/0015-camera-native-bridge-strategy.md) — addendum pendente
- Spec Task 19 closure: [`docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md`](../superpowers/specs/2026-05-28-camera-task-19-closure-design.md) — status update pendente
- CLAUDE.md §13: workflow iOS terminal-first
- CLAUDE.md §11: addendum 4 com AP-1..AP-6 (pendente)
- Sessão anterior: [`0005-camera-device-validation.md`](0005-camera-device-validation.md)

### Memórias propostas (criar via `claude memory` ou registrar manualmente)

- `raro-pattern-ca-transaction-disable-actions-breaks-add-animation`
- `raro-pattern-ca-transaction-flush-removes-animation-on-completion`
- `raro-pattern-flutter-uikitview-eager-gesture-recognizer-tap-latency`
- `raro-pattern-avcapture-smooth-autofocus-tap-vs-record`
- `raro-pattern-avcapture-kvo-permanent-vs-per-tap`
- `feedback_observability_infra_before_known_fix_is_inverse_antipattern`

### Workflow audit IDs

- `wc7955ttk` — tooling perf 2026
- `w3cediota` — audit adversarial overengineering vs essential
- `wwe1u6vm0` — harness E2E híbrido

### Referências externas

- Flutter issue [#170735](https://github.com/flutter/flutter/issues/170735) — UiKitView gesture latency
- Apple docs — [`AVCaptureDevice.isSmoothAutoFocusEnabled`](https://developer.apple.com/documentation/avfoundation/avcapturedevice/issmoothautofocusenabled)
- Apple docs — [`captureDevicePointConverted(fromLayerPoint:)`](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/capturedevicepointconverted(fromlayerpoint:))
- Apple docs — [`CATransaction`](https://developer.apple.com/documentation/quartzcore/catransaction) (setDisableActions semantics)
