# Próxima sessão — RARO Camera (continuação de Task 19)

> **Para Claude Code:** Este é o prompt de retomada após pausa em 2026-05-28. Leia tudo antes de agir. Não pule seções.

---

## 0. Antes de qualquer ação

Execute em ordem:

```bash
# 1. Sincronizar branch + state
git fetch --all
git status

# 2. Confirmar que está na branch certa
git branch --show-current   # esperado: feat/camera-native-bridge

# 3. Re-ler memória persistente RELEVANTE (não tudo, só o que matter)
cat ~/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-vitor-workana-app-raro/memory/MEMORY.md
```

Se você for o Claude reiniciado em nova janela:

- Leia **CLAUDE.md** (manual autoritativo) inteiro
- Leia **docs/sessions/0005-camera-device-validation.md** (último estado)
- Leia **docs/decisions/0015-camera-native-bridge-strategy.md** (addendum 2026-05-28 seções A-H)
- Leia **memória `feedback_device_debug_use_real_logs_not_assumptions`** — esta é a lição capital

---

## 1. Estado exato em que paramos

**Data da pausa:** 2026-05-28
**Branch:** `feat/camera-native-bridge` (publicada em `origin`)
**Commits ahead de develop:** 51
**Working tree:** limpa
**Último commit:** `f72f0b5 docs(docs): close session 0005 — camera device validation task 19`
**Link da branch no GitHub:** https://github.com/ZenniTTy/raro.com/tree/feat/camera-native-bridge

### O que está funcionando (validado em iPhone 12 físico)

- ✅ **G1** start session (instrumentado em logs, falta cronometragem precisa)
- ✅ **G2** discoverCapabilities retorna `[ultraWide, wide]` no iPhone 12
- ✅ **G3** lens switch 0.5×↔1× **sem blackout** via virtual device zoom mapping
- ✅ **G5** resolution runtime (720/1080/4K aplicado corretamente)
- ✅ **G6** 4K@60fps aplicado (logs confirmam `setFormat uhd4k@fps60 → 3840x2160`)
- ✅ **G8** permission denied → open settings → volta (funciona em debug via Control Center)
- ✅ **G9** background/foreground via Control Center (observers AVCaptureSession funcionam)

### O que NÃO está validado ainda

- ⏳ **G4** focus ring overlay — pendente; precisa **CALayer nativo no Swift** (não Stack Flutter que quebra hybrid composition)
- ⏳ **G7** stop libera memória ±5MB — precisa Xcode Instruments + Memory Profiler
- ⏳ **G10** iPad rejected — sem iPad disponível; lógica já cobre via empty devices
- ⏳ **G8/G9 lifecycle real** (fechar app + reabrir pelo ícone) — adiado para TestFlight (precisa Apple Developer Program $99/ano)
- ⏳ **Android Pixel emulator** — G2, G3, G6 CameraX bridge não testado em device Android ainda
- ⏳ **G1 cronometragem precisa** (≤500ms) — falta `mach_absolute_time()` wrapper

---

## 2. Próxima sessão — escolher UMA opção

### Opção A (RECOMENDADA) — Fechar Task 19 e fazer merge

Objetivo: marcar spec `camera-native-bridge` como **Done definitivo** e mergear `feat/camera-native-bridge` → `develop` → `main`.

**Tarefas em ordem:**

1. **G4 focus ring nativo (CALayer Swift)**
   - Criar `apps/mobile/ios/Runner/Native/Camera/CameraFocusRingLayer.swift`
   - Adicionar como sublayer no `CameraPreviewContainerView` quando `focusAt()` é chamado
   - Animação: scale-in 0.8→1.0 + fade-in/fade-out 1.2s (idêntica ao protótipo HTML)
   - Por que nativo: Stack/CustomPaint sobre `UiKitView` quebra hybrid composition (memory `raro-pattern-ios-platformview-camera-preview-black`)
   - Mirror Android: `apps/mobile/android/.../camera/CameraFocusRingView.kt` como ViewOverlay

2. **G7 memory test via Instruments**
   - Setup Instruments → Allocations template
   - Baseline antes de `cameraController.start()`
   - Snapshot após `cameraController.stop()` + dispose
   - Asserção: diferença ≤ 5MB
   - Documentar passo a passo em `docs/sessions/0006-*.md`

3. **G1 cronometragem precisa**
   - Adicionar `CFAbsoluteTimeGetCurrent()` em `startSession` (início) e `onSessionStarted` callback
   - Diff < 500ms em iPhone 12
   - Validar em logs do harness

4. **G10 iPad rejection**
   - Pegar iPad emprestado OU simular via iOS Simulator iPad
   - Esperado: `discoverCapabilities` → `throw .deviceUnavailable` (devices array vazio se filtrado por position .back)
   - Atualmente: code path já cobre; só falta evidência

5. **Android Pixel emulator validation**
   - Pixel 6 API 34 emulator
   - Rodar harness, validar G2 (capabilities), G3 (lens), G6 (4K@60fps via metadata)
   - Memory `raro-pattern-android-camerax-ultra-wide-unreliable` avisa: ultra-wide é OEM-dependent; emulator pode não expor

6. **Marcar spec como Done**
   - Atualizar `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md` status: `Draft` → `Done`
   - Adicionar seção "Validation evidence" com logs/screenshots
   - Atualizar `docs/superpowers/plans/2026-05-26-camera-native-bridge.md` Task 19 todos checkbox marcados

7. **Merge flow**
   - `git checkout develop && git merge --no-ff feat/camera-native-bridge`
   - `git checkout main && git merge --no-ff develop`
   - `git tag v0.4.1`
   - `git push origin develop main --tags`
   - Deletar branch local + remota

### Opção B — Pular para spec 0006 (replay-buffer-native-bridge)

Se preferir avançar feature (mais user-visible) e fechar Task 19 depois:

```bash
/new-spec replay-buffer-native-bridge
# Sigue brainstorming → /new-plan → writing-plans → subagent-driven-development
```

Reusa `CameraSession` já estável. Adiciona AVAssetWriter (iOS) + MediaCodec/MediaMuxer (Android) + CVPixelBufferPool / MediaCodec pool. Pré-roll integra com `feat/camera-recording` futura. Sizing **Large**.

### Opção C — Comprar Apple Developer Program

$99/ano. Necessário SOMENTE para:
- Validar G8/G9 lifecycle real (fechar app + reabrir pelo ícone)
- TestFlight beta distribution
- Publicação App Store

**NÃO É BLOCKER** para próximas 2-3 specs (todas bridges nativas + UI). Adiar até estar próximo de release real.

---

## 3. Erros que NÃO DEVEM SER COMETIDOS (catalogados)

### 3.1 Plugin Flutter iOS — SEMPRE ler README de Setup primeiro

**Bug crítico cometido:** `permission_handler` foi adicionado no `pubspec.yaml` sem configurar macros do Podfile. Resultado: 4h debugando "por que Câmera não aparece em Ajustes do iPhone".

**Diagnóstico em 2 minutos** (não 4h):
```bash
grep PERMISSION_ apps/mobile/ios/Pods/Pods.xcodeproj/project.pbxproj
# Vazio = macros faltando = plugin NÃO compila support iOS = retorna denied silently
```

**Solução:** macros já estão no Podfile + script `bootstrap-ios-permissions.sh` reaplica após cada `flutter pub get`.

**Regra geral:** Ao adicionar QUALQUER plugin Flutter, **sempre leia o README do plugin no pub.dev**, seção "Setup iOS" antes de assumir que funciona. Plugins com flag-based compilation (`firebase_messaging`, `flutter_local_notifications`, `permission_handler`) exigem macros no Podfile que não disparam erro de build.

### 3.2 Pre-actions Xcode — instantâneas, read-only, sem `flutter build` interno

**Bug crítico cometido:** Pre-action chamava `flutter build ios --config-only` durante o build em curso. Resultado: Xcode aborta silenciosamente, status "stopped", zero build phases executadas. "BUILD SUCCEEDED" falso.

**Diagnóstico:**
```bash
brew install xclogparser
ls -lt ~/Library/Developer/Xcode/DerivedData/Runner-*/Logs/Build/*.xcactivitylog | head -1
xclogparser parse --file <log>.xcactivitylog --reporter flatJson --output /tmp/b.json
python3 -c "import json; d=json.load(open('/tmp/b.json')); [print(s['buildStatus'], s.get('title','')[:80]) for s in d]"
```

Se você ver SÓ pre-actions, sem `Sources`/`Link`/`CopyResources` = Xcode abortou.

**Regra:** Pre-actions devem ser <1s, read-only ou patches mínimos via `sed`. Nada que regenere `project.pbxproj` ou `xcworkspace`.

### 3.3 NUNCA inventar fix para bug em device sem ler logs reais

**Custo histórico:** ~6h gastas em ciclos build-test-corrigir baseados em chutes teóricos. Cada chute custa ~30min de build + teste + frustração.

**Protocolo correto** (memory `feedback_device_debug_use_real_logs_not_assumptions`):

1. **Instrumentar `os_log` estratégico no caminho suspeito ANTES de qualquer fix**
   ```swift
   os_log("xxxYYY value=%{public}@", log: cameraLog, type: .info, "\(suspect)")
   ```
2. **Pedir ao usuário pra colar Xcode Console** (Cmd+Shift+Y)
3. **Filtrar por subsystem `com.rarocamera`**
4. **Ler evidência → pesquisar causa específica → implementar fix**

**Limitação:** `idevicesyslog` NÃO captura logs de apps de terceiros em iOS 18+. Único caminho confiável é Xcode Console conectado.

### 3.4 Tela "iOS 14+ debug mode" NÃO é bug

Quando user fecha o app pelo home e tenta reabrir, aparece tela:
> "In iOS 14+, debug mode Flutter apps can only be launched from Flutter tooling, IDEs with Flutter plugins or from Xcode."

**Isso é restrição arquitetural Apple+Flutter** (debug usa JIT, JIT exige Xcode conexão). NÃO TENTAR "consertar". Comunicar limitação ao usuário e adaptar protocolo de teste:

| Cenário | Como testar |
|---|---|
| Bug runtime que precisa Xcode logs | Debug + Cmd+R (essencial) |
| Lifecycle bg/fg curto | Debug + Control Center / multitasking parcial |
| Lifecycle bg/fg longo, fechar+reabrir | Release/TestFlight (Apple Dev Program) |

### 3.5 iPhone 12 DualWide `minAvailableVideoZoomFactor` mente

Reporta `1.0` mesmo com ultra-wide física dentro. Não use o número direto. Mapping correto:

```swift
// 0.5x → videoZoomFactor = device.minAvailableVideoZoomFactor (= 1.0, sistema usa ultra-wide internamente)
// 1x → videoZoomFactor = device.virtualDeviceSwitchOverVideoZoomFactors.first.doubleValue (= 2.0, cruza switchover)
```

Implementação está em `CameraManager.applyVirtualLensZoom`.

### 3.6 setFormat exige sessionPreset = .inputPriority

Sem isso, `device.activeFormat = X` é ignorado/sobrescrito silenciosamente.

```swift
session.beginConfiguration()
session.sessionPreset = .inputPriority    // ESSENCIAL
try device.lockForConfiguration()
device.activeFormat = chosenFormat
device.unlockForConfiguration()
session.commitConfiguration()
```

### 3.7 AVCaptureSession exige 3 observers para bg/fg

Sem eles, app crash voltando de Settings.app ou multitasking. Cobrir:

- `AVCaptureSession.wasInterruptedNotification` — log + onError callback
- `AVCaptureSession.interruptionEndedNotification` — auto-restart no `sessionQueue`
- `AVCaptureSession.runtimeErrorNotification` — auto-restart em `.mediaServicesWereReset`

Implementação em `CameraManager.installObservers`.

### 3.8 `FigCaptureSourceRemote err=-17281` é BENIGNO

Confirmado por Apple DTS ([forums.apple.com/thread/810894](https://developer.apple.com/forums/thread/810894)) como ruído iOS 26. Aparece em ~todas as chamadas `AVCaptureSession` config. **NÃO TRATAR COMO ERRO.**

### 3.9 Apple Development cert (free tier) não basta para release

Para rodar release no device físico real precisa **Apple Developer Program ($99/ano)**. Free tier dá erro `"Runner" failed to launch — code signature`. Não tentar "consertar" — comprar Dev Program OU adiar testes release para TestFlight.

### 3.10 Swift 6 strict concurrency + AVFoundation

`AVCaptureSession` não é Sendable. Use:

```swift
@preconcurrency import AVFoundation
final class CameraHostApiImpl: NSObject, CameraHostApi, @unchecked Sendable { ... }
```

Workaround oficial Swift Forums até Apple adicionar Sendable conformance.

---

## 4. Comandos canônicos (uso frequente)

```bash
# Rebuild iOS após mudar Swift
cd apps/mobile && flutter build ios --debug --no-codesign

# Reaplica fix-spm + permission macros (após flutter pub get)
bun --filter @raro/mobile run bootstrap:ios

# Wrapper completo (pub get + fix-spm + permissions)
bun --filter @raro/mobile run pub:get

# Rodar testes
bun --filter @raro/mobile run test
bun --filter @raro/mobile run test:contract

# Analyze
bun --filter @raro/mobile run analyze

# Codegen Riverpod 3
bun --filter @raro/mobile run codegen

# Pigeon regen (depois de editar pigeons/*.dart)
bun --filter @raro/mobile run pigeon
```

**Logs reais (para debug):**

```bash
# Build logs Xcode
ls -lt ~/Library/Developer/Xcode/DerivedData/Runner-*/Logs/Build/*.xcactivitylog | head -1
xclogparser parse --file <path> --reporter flatJson --output /tmp/b.json

# Device conectado
xcrun devicectl list devices

# App instalado
xcrun devicectl device info apps --device 0102030405 | grep -i raro
```

---

## 5. Arquivos importantes (referência rápida)

| Arquivo | Por quê |
|---|---|
| `CLAUDE.md` | Manual autoritativo. Anti-patterns §11. |
| `docs/Blueprint.md` | Decisões arquiteturais. Stack fixada. |
| `docs/decisions/0015-camera-native-bridge-strategy.md` | ADR camera bridge + addendum 2026-05-28 (seções A-H) |
| `docs/sessions/0005-camera-device-validation.md` | Último estado detalhado |
| `docs/sessions/0001-INDEX.md` | Índice de sessões |
| `docs/10-CHANGELOG.md` | Histórico append-only |
| `apps/mobile/scripts/fix-spm-ios-target.sh` | Patcha SPM iOS 13→15 (Flutter quirk) |
| `apps/mobile/scripts/bootstrap-ios-permissions.sh` | Reaplica permission_handler macros |
| `apps/mobile/ios/Podfile` | Macros `PERMISSION_*` no post_install |
| `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` | AVCaptureSession + observers + zoom mapping |
| `apps/mobile/lib/features/camera/presentation/camera_test_harness_screen.dart` | Harness para validation |
| `apps/mobile/lib/app.dart` | Flag `_forceHarness` permite harness em release |

---

## 6. Memórias persistentes (em `~/.claude/projects/.../memory/`)

Leia se relevante:

- `feedback_device_debug_use_real_logs_not_assumptions` — **CAPITAL.** Logs reais > suposições.
- `raro-pattern-permission-handler-ios-podfile-macros` — Por que Câmera não aparecia em Ajustes
- `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping` — Tudo sobre AVCapture iPhone 12
- `raro-pattern-flutter-debug-vs-release-on-device` — Restrições debug + TestFlight
- `raro-pattern-ios-platformview-camera-preview-black` — Preview preto + hybrid composition
- `raro-pattern-xcode-preaction-modifies-workspace` — Pre-actions Xcode armadilha
- `raro-pattern-flutter-spm-ios-13-hardcoded` — Bug Flutter 3.44 SPM
- `raro-pattern-ios-wake-word-no-native-api` — Wake word "Raro" (próxima feature provável)

---

## 7. Prompt sugerido para retomar (copie isto)

> Olá Claude. Estou retomando o desenvolvimento do RARO Camera após pausa em 2026-05-28.
>
> Leia primeiro `NEXT_SESSION.md` (este arquivo na root) — ele contém estado exato, próximos passos e erros a NÃO cometer.
>
> Depois leia em ordem:
> 1. `CLAUDE.md`
> 2. `docs/sessions/0005-camera-device-validation.md` (último estado)
> 3. `docs/decisions/0015-camera-native-bridge-strategy.md` addendum seções A-H
> 4. Memória `feedback_device_debug_use_real_logs_not_assumptions` (lição capital)
>
> Pretendo seguir **Opção A** do `NEXT_SESSION.md` — fechar Task 19 e fazer merge. Começar por G4 focus ring nativo (CALayer Swift, não Stack Flutter).
>
> Antes de implementar QUALQUER coisa:
> - Confirmar que estado atual está limpo (`git status`)
> - Verificar `xcrun devicectl list devices` se meu iPhone está conectado
> - Re-ler `CameraManager.swift` e `CameraPlatformView.swift` para entender estado atual antes de adicionar focus ring layer
>
> NÃO inventar fix sem logs reais. NÃO assumir comportamento de plugin sem README iOS Setup. Seguir as boas práticas catalogadas no anti-patterns CLAUDE.md §11.

---

## 8. Se algo der errado (recovery)

| Sintoma | Comando de recovery |
|---|---|
| Build iOS quebra com "Firebase iOS 15 vs 13" | `bun --filter @raro/mobile run bootstrap:ios` |
| Câmera para de aparecer em Ajustes | `bun --filter @raro/mobile run bootstrap:ios` + rebuild + reinstall |
| Build trava sem erro visível | `xclogparser parse --file <log>.xcactivitylog --reporter flatJson` |
| Xcode "Failed to launch — code signature" | Voltar Edit Scheme → Run → Build Configuration = **Debug** |
| Logs Xcode somem | Cmd+Shift+Y no Xcode |
| App não instala no iPhone | `xcrun devicectl device info apps --device 0102030405 \| grep raro` + Xcode Clean Build Folder (Shift+Cmd+K) |
| Pre-action quebrou algo | Verificar que script é sed-only (sem `flutter build` interno) |

---

**Última atualização:** 2026-05-28
**Branch ativa:** `feat/camera-native-bridge` (51 commits ahead de develop, publicada em origin)
**Próxima sessão sugerida:** 0006 (continuação Task 19 ou nova spec replay-buffer)
