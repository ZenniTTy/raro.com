# Voice Wake-Word (LiveKit/ONNX) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a engine de voz SFSpeechRecognizer (beco-sem-saída) por um detector de wake-word dedicado on-device (modelo "Raro" treinado via LiveKit, rodando em ONNX Runtime + CoreML), copiando a arquitetura de áudio do concorrente, mantendo o contrato Pigeon e a camada Dart inalterados.

**Architecture:** Abordagem A — `AudioSessionCoordinator` (dono único da AVAudioSession) + `WakeWordDetector` (3 ONNX sessions sobre buffer 16kHz mono) + `VoiceManager` reescrito (orquestra tap→detector→WakeCommand) + toque cirúrgico na câmera para não monopolizar o mic. O contrato Pigeon (`voice_api.dart`) e toda a camada Dart NÃO mudam; o único toque Dart é flipar `_voiceEngineAvailable=true` após o gate de viabilidade passar no iPhone 12.

**Tech Stack:** Swift 6 (@preconcurrency AVFoundation), ONNX Runtime Swift Package Manager (`from: "1.16.0"`, produto `onnxruntime`, API `ORTEnv`/`ORTSessionOptions`/`ORTSession`), CoreML Execution Provider, AVAudioEngine tap, Pigeon v26.3.2 (contrato inalterado), Riverpod 3 codegen (Dart, inalterado).

**Estado já existente (NÃO recriar):**
- Camada Dart 100% cabeada e testada (312 testes verdes): `voice_controller.dart`, `voice_repository.dart`, `voice_flutter_api_provider.dart`, `voice_state.dart`, `voice_listening_indicator.dart`. Desligada por `const bool _voiceEngineAvailable = false;` (voice_controller.dart:12).
- Contrato Pigeon gerado: `VoiceHostApi(isAvailable/startListening/stopListening)`, `VoiceFlutterApi(onWakeDetected/onListeningStateChanged)`, enums `WakeCommand{start,stop}` / `VoiceListeningState{idle,listening,paused,unavailable}`.
- Ponte `VoiceHostApiImpl.swift` (Manager↔FlutterApi). Wiring em `AppDelegate.swift:35-40`. Utilitário `ObjCExceptionCatcher` (.h/.m) para installTap NSException.

**Gap real:** o `VoiceManager.swift` atual usa SFSpeechRecognizer (descartar). Falta: modelo "Raro", integração ONNX Runtime, `WakeWordDetector`, `AudioSessionCoordinator`, reescrita do `VoiceManager`, toque cirúrgico na câmera, gate de device, flip da flag.

---

## ⚠️ VALIDAÇÕES E CORREÇÕES (sessão 0024, 2026-06-11 — fonte primária + device)

Due-diligence antes de executar. **Estes fatos supersedem detalhes inline desatualizados nas Tasks abaixo:**

1. **CRUX DE BACKGROUND JÁ PROVADO no iPhone 12.** O `AudioSessionCoordinator` (mic-only, já commitado 37c863c) mantém o app vivo e recebendo áudio com a **tela bloqueada** (heartbeat contínuo, frames 50→600, zero `BackgroundTaskSuspended`). Prova em `docs/superpowers/notes/voice-background-crux-proof-iphone12.md`. A Task 4 (Coordinator) está essencialmente FEITA; o gate de background da Task 7 (4b) já tem evidência da fundação.
2. **onnxruntime resolvido = `1.24.2`** (NÃO `1.16.0` da spec/Task 2). Atualizar refs.
3. **CoreML EP EXISTE em 1.24.2** (o "spike" da Task 3 Step 0 está RESOLVIDO — existe). API REAL: `ORTIsCoreMLExecutionProviderAvailable()` (checar antes) + `appendCoreMLExecutionProviderWithOptions:` / `...WithOptionsV2:`. **O `appendCoreMLExecutionProvider(with:)` do código da Task 3 NÃO existe — corrigir.**
4. **melspectrogram tem incompatibilidade de operadores** conhecida entre plataformas → no iOS rodar o **mel em CPU/XNNPACK**, só o classifier no CoreML (seleção de EP POR modelo, não global). Smoke-test de carga dos 3-4 modelos no device é obrigatório antes de confiar.
5. **Ferramenta = `livekit-wakeword`** (real, melhor que openWakeWord: 100× menos FP/h, 60× menos falso-aceite, 17% mais detecção; exporta ONNX compatível com openWakeWord). A Task 1 deve usá-la.
6. **Treino exige Linux + CUDA** (Piper synthetic-gen + trainers são Linux/WSL2). **NÃO Mac.** Caminho prático = GPU Linux alugada (RunPod/Vast ~US$0,34/h, treino ~US$1-4). A memória `raro-pattern-wakeword-train-cpu-piper-no-colab` foi corrigida (o "CPU no Mac" briga com o tooling).
7. **Dependency hell:** pinar `livekit-wakeword`/openWakeWord em commit conhecido (~fev/2026) ou fork com patches (torchaudio 2.10+/Piper/speechbrain). Não usar `main` cru.
8. **Risco residual concentrado SÓ no modelo:** infraestrutura toda (background, ONNX, CoreML, integração) provada/disponível; o único não-garantido é a **qualidade do "Raro" PT-BR always-on** (recall >80% + FP baixo no iPhone — Task 7 gate). "Raro" é palavra comum → risco de FP. Só se prova treinando+testando. Plano B se reprovar = mais dados / frase distinta / aceitar custo.
9. **Picovoice recusado** pelo dono (custom keyword = Enterprise ~US$6k/ano; free tier = 1 device com marca d'água). Modelo próprio confirmado.
10. **NSSpeechRecognitionUsageDescription** foi restaurado no Info.plist (sessão 0024, d494179) porque o SFSpeech foreground segue ativo. **NÃO remover** enquanto o foreground SFSpeech existir (a Task 6 Step 2 manda remover — só remover quando o ONNX superseder DE FATO o foreground).

---

## File Structure

**Modelo + dep nativa**
- Create: `apps/mobile/ios/Runner/Resources/Raro.onnx` (ou conjunto mel/embed/classifier — ver Task 1) — modelo treinado
- Modify: `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` — XCRemoteSwiftPackageReference do ONNX Runtime + 4 inserções por XCTest novo + asset do modelo no Copy Bundle Resources
- Modify: `docs/Blueprint.md` (§2) — registrar ONNX Runtime
- Modify: `apps/mobile/ios/Runner/Info.plist` — `UIBackgroundModes: [audio]`

**Swift nativo (novo/reescrito)**
- Create: `apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift` — pipeline ONNX (mel→embed→classifier), score "Raro"
- Create: `apps/mobile/ios/Runner/Native/Voice/AudioSessionCoordinator.swift` — dono da AVAudioSession, tap, interrupções, ConfigurationChange
- Modify (reescrever): `apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift` — orquestra tap→detector→WakeCommand (remove SFSpeech)
- Modify: `apps/mobile/ios/Runner/Native/Voice/VoiceHostApiImpl.swift` — só se a assinatura dos callbacks do Manager mudar (manter mínima)
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift:35-40` — instanciar Coordinator + Manager novo
- Reuse: `apps/mobile/ios/Runner/Native/Voice/ObjCExceptionCatcher.{h,m}` — guard de installTap

**Câmera (toque cirúrgico)**
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift:277-291` — gravar sem monopolizar o mic (estratégia decidida no spike da Task 6)

**Testes**
- Create: `apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift` — carga do modelo + score determinístico
- Create: `apps/mobile/ios/RunnerTests/AudioSessionCoordinatorTests.swift` — ciclo de vida do tap (closures determinísticas)
- Modify: `apps/mobile/ios/RunnerTests/VoiceManagerTests.swift` — remover testes do parser SFSpeech, adicionar testes do orquestrador

**Dart (1 linha)**
- Modify: `apps/mobile/lib/features/voice/application/voice_controller.dart:12` — `_voiceEngineAvailable = true` (Task 8, SÓ após gate)

---

## Task 0: Confirmar ADR-0023 cobre integração ONNX via SPM (adr-guardian gate)

**Files:**
- Read: `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md`
- Modify (se necessário): `docs/Blueprint.md` (§2)

**Contexto:** O passo 2 da build sequence da spec exige confirmar se integrar ONNX Runtime (dep nativa nova via SPM) precisa só de registro no Blueprint §2 ou de ADR adicional. ADR-0023 já está Accepted e autoriza ONNX Runtime no Runner, mas o `adr-guardian` deve confirmar antes de tocar `project.pbxproj`/`Blueprint.md` (hook `warn-adr-drift` observa Blueprint).

- [ ] **Step 1: Rodar adr-guardian**

Dispatch do subagent `adr-guardian` com a pergunta: "Integrar ONNX Runtime via SPM no Runner (XCRemoteSwiftPackageReference) + registrar a lib no Blueprint §2 — está coberto pelo ADR-0023 (Accepted) ou exige ADR adicional / addendum?". Anexar `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md`.

Expected: GO (cobertura confirmada) OU instrução de addendum.

- [ ] **Step 2: Se GO, registrar ONNX Runtime no Blueprint §2**

Adicionar linha na tabela de stack do `docs/Blueprint.md` (§2), seguindo o formato das libs existentes:
```
| onnxruntime (SPM) | `1.16.0+` | engine de wake-word on-device (ADR-0023) — CoreML EP |
```

- [ ] **Step 3: Commit**

```bash
git add docs/Blueprint.md
git commit -m "docs(docs): registra onnx runtime no blueprint §2 (engine de voz, adr-0023)"
```

> Se o adr-guardian pedir addendum ao ADR-0023, criar o addendum ANTES do Step 2 e incluí-lo no mesmo commit (scope `docs`). Registrar também a evidência Sensory (concorrente usa SDK pago) como justificativa, conforme a spec sugere.

---

## Task 1: Treinar/obter o modelo "Raro" (LiveKit pipeline)

**Files:**
- Create: `apps/mobile/ios/Runner/Resources/` (diretório do(s) modelo(s) ONNX)
- Create: `docs/superpowers/notes/raro-model-training.md` (registro do procedimento + métricas)

**Contexto:** O detector precisa do modelo "Raro" em ONNX. Pipeline LiveKit-wakeword: geração sintética (VoxCPM PT-BR) + augmentation + treino + export ONNX, complementado com gravações reais se o gate exigir. O modelo do concorrente (`ok_camera.snsr`) é Sensory proprietário — inútil/ilegal; usamos só os parâmetros de referência (16kHz mono, ver memória `raro-competitor-okcamera-android-apk-teardown`).

> ⚠️ **Limitação honesta:** o treino roda fora do app (máquina Linux/Colab com GPU). Esta task produz o(s) arquivo(s) `.onnx`; não há código de produção aqui. Se o ambiente de treino não estiver disponível, esta task PAUSA e avisa o dono (decisão de infra).

> **DECISÃO TRAVADA (5a — confirmar com o dono no início):** wake-word puro só detecta a presença de uma frase. Para distinguir "Raro gravar" de "Raro parar" (spec Q7, dois comandos), treinamos **DOIS classificadores de frase inteira**: `raro_gravar.onnx` (→ `.start`) e `raro_parar.onnx` (→ `.stop`), compartilhando os estágios mel+embedding. Isso simplifica o Manager (modelo-A→start, modelo-B→stop) e é mais robusto que classificar o comando numa janela pós-wake (5b, descartada). Se o dono preferir 5b, ESTA task e as Tasks 3/5 mudam (1 modelo + janela) — confirmar ANTES do Step 1.

- [ ] **Step 1: Treinar via LiveKit-wakeword (DUAS frases)**

Seguir a pipeline LiveKit (`livekit-wakeword run configs/raro_gravar.yaml` e `configs/raro_parar.yaml`), idioma PT-BR (backend VoxCPM). Gerar dataset sintético (≥ vários milhares de clipes por frase) + negativos. Exportar ONNX compatível com runtime OpenWakeWord: estágios compartilhados `melspectrogram.onnx` + `embedding.onnx`, e DOIS classificadores `raro_gravar.onnx` / `raro_parar.onnx`. (Se a pipeline emitir modelos monolíticos por frase, manter 2 arquivos `.onnx` — um por comando.)

- [ ] **Step 2: Medir recall offline (pré-gate)**

Construir conjunto de teste com gravações reais de "Raro" (várias vozes/distâncias) e medir recall + falsos positivos com áudio longo sem a palavra. Registrar em `docs/superpowers/notes/raro-model-training.md`. Meta de referência: recall alto o suficiente para o gate device (>80%).

> Se o recall offline já vier < 80%, NÃO prosseguir para a integração: voltar ao dono com a decisão de plano B (mais dados / Porcupine / Sensory com custo) — a spec trava isso.

- [ ] **Step 3: Colocar os modelos no projeto + registrar contrato de I/O**

Copiar os `.onnx` para `apps/mobile/ios/Runner/Resources/`. Em `raro-model-training.md`, registrar para CADA estágio: nome EXATO do arquivo, nome dos tensores de input/output, shape exato, e se o classifier é **stateful** (acumula janela de N embeddings entre chamadas) ou **stateless** (recebe a janela inteira por chamada). Este contrato de I/O é o que a Task 3 implementa — a Task 3 NÃO inventa shapes, lê daqui.

> ⚠️ **Contrato de janela (resolve ambiguidade do detector):** um único frame de 80ms (1280 samples @16kHz) NÃO gera embeddings suficientes para o classifier OWW — o classifier precisa de uma janela deslizante de embeddings (tipicamente ~16-76 frames). Decidir aqui: o `WakeWordDetector` será **stateful** (mantém um ring buffer interno de embeddings e a cada `pushFrame(_:)` de 80ms atualiza a janela e devolve o score atual). Registrar o tamanho da janela emitido pela pipeline.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/ios/Runner/Resources/ docs/superpowers/notes/raro-model-training.md
git commit -m "feat(voice): adiciona modelo wake-word raro (onnx) + notas de treino"
```

---

## Task 2: Integrar ONNX Runtime via SPM no Runner

**Files:**
- Modify: `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` — XCRemoteSwiftPackageReference + packageProductDependencies(onnxruntime) no target Runner
- Modify: `apps/mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` E `apps/mobile/ios/Runner.xcodeproj/xcshareddata/swiftpm/Package.resolved` (pin nos DOIS — memória `raro-pattern-spm-package-resolved-divergent`)

**Contexto:** O Runner usa SPM para deps remotas (Firebase/RevenueCat via plugins; aqui é dep direta no Runner). Adicionar `microsoft/onnxruntime-swift-package-manager`. CLAUDE.md §13 manda fazer resolução/build via terminal (anti-loop SPM) — então o **default é editar o `project.pbxproj` à mão** + resolver no terminal. Xcode UI "Add Package" é só um fallback de conveniência (NÃO é um uso canônico listado na §13; §13 lista signing, debug, storyboards, scheme pre-actions).

> ⚠️ **Decisão técnica (SPM vs CocoaPods):** preferir SPM (XCRemoteSwiftPackageReference direto no Runner) por coerência com o projeto. Fallback documentado: `pod 'onnxruntime-objc'` no Podfile se o SPM remoto falhar no sandbox.

- [ ] **Step 1: Adicionar a referência SPM ao project.pbxproj (terminal-first)**

Editar `apps/mobile/ios/Runner.xcodeproj/project.pbxproj`, seguindo o formato EXATO dos blocos existentes:
- `XCRemoteSwiftPackageReference "onnxruntime-swift-package-manager"` com `repositoryURL = "https://github.com/microsoft/onnxruntime-swift-package-manager"` + `requirement { kind = upToNextMajorVersion; minimumVersion = 1.16.0; }`
- `XCSwiftPackageProductDependency` com `productName = onnxruntime` referenciando o package acima
- adicionar esse product dependency ao `packageProductDependencies` do target Runner e à lista `packageReferences` do PBXProject

> Fallback (conveniência): Xcode UI File > Add Package Dependencies > URL acima > Up to Next Major `1.16.0` > target Runner. Após usar a UI, fechar o Xcode e seguir o resto pelo terminal (§13).

- [ ] **Step 2: Resolver dependências (terminal, com os 2 git overrides)**

Run:
```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --config-only
```
Expected: resolução SPM sem "Could not resolve package dependencies"; `Package.resolved` passa a conter `onnxruntime`.

- [ ] **Step 3: Pin do ONNX nos DOIS Package.resolved**

Confirmar que ambos `Package.resolved` (do `.xcodeproj` E do `.xcworkspace`) contêm o pin do onnxruntime na mesma versão (memória `raro-pattern-spm-package-resolved-divergent`). Se divergirem, copiar o do workspace para o xcodeproj.

Run:
```bash
grep -l onnxruntime apps/mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved apps/mobile/ios/Runner.xcodeproj/xcshareddata/swiftpm/Package.resolved 2>/dev/null
```
Expected: ambos os caminhos listados.

- [ ] **Step 4: Smoke — compilar para simulator**

Run:
```bash
cd apps/mobile && flutter build ios --simulator --no-codesign
```
Expected: build sucede (ONNX Runtime linka sem erro).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/ios/Runner.xcodeproj/project.pbxproj apps/mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved apps/mobile/ios/Runner.xcodeproj/xcshareddata/swiftpm/Package.resolved
git commit -m "build(voice): integra onnx runtime via spm no runner (adr-0023)"
```

---

## Task 3: WakeWordDetector (pipeline ONNX) — TDD

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift`
- Test: `apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift`
- Modify: `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` (4 inserções p/ o XCTest novo + adicionar Raro.onnx ao bundle do alvo de teste E do Runner)

**Contexto:** O detector carrega os modelos ONNX (mel + embedding + 2 classificadores: gravar/parar) e expõe uma API **stateful**: `pushFrame([Float])` (frame de 80ms @16kHz mono) atualiza a janela interna de embeddings e devolve `WakeScores(start: Float, stop: Float)`. Lógica testável (carga + inferência sobre buffer conhecido) separada do hardware (tap fica no Coordinator). Usa `ORTEnv`/`ORTSessionOptions`/`ORTSession` (confirmado via Context7).

> **Decisão técnica:** o `WakeWordDetector` NÃO toca AVAudioEngine nem AVAudioSession — recebe `[Float]` 16kHz mono. É STATEFUL (mantém ring buffer de embeddings); por isso silêncio sustentado (várias chamadas) → score baixo estável. Dois classificadores → `scoreStart`/`scoreStop` num único struct, alinhado à decisão 5a da Task 1.

> ⚠️ **CoreML EP é SPIKE, não fato (Step 0):** a doc do pacote SPM (Context7) NÃO documenta `appendCoreMLExecutionProvider` nem garante que o binário SPM default inclua o CoreML EP. Antes de prescrever, o Step 0 confirma a API/disponibilidade na versão resolvida na Task 2. Se ausente, roda em CPU (decisão de build registrada) — NUNCA mascarar com `try?` silencioso.

- [ ] **Step 0: SPIKE — confirmar API/disponibilidade do CoreML EP**

Inspecionar os headers do pacote ONNX resolvido (Task 2) por símbolos de execution provider:
```bash
find apps/mobile/ios -path "*onnxruntime*" -name "*.h" 2>/dev/null | xargs grep -l -iE "coreml|executionprovider|appendexecution" 2>/dev/null
```
Registrar em `raro-model-training.md`: o método exato disponível (`appendCoreMLExecutionProvider(with:)` OU `appendExecutionProvider(_:options:)` OU NENHUM → só CPU). A Task 3 Step 4 usa o que existir; se nenhum, omite o EP e loga "running on CPU".

- [ ] **Step 1: Escrever o teste que falha**

Create `apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift`:
```swift
import XCTest
@testable import Runner

final class WakeWordDetectorTests: XCTestCase {
  func testLoadsModelsFromBundle() throws {
    let detector = try WakeWordDetector()
    XCTAssertTrue(detector.isLoaded)
  }

  func testSustainedSilenceProducesLowScores() throws {
    let detector = try WakeWordDetector()
    let silence = [Float](repeating: 0, count: 1280) // 80ms @16kHz
    var last = WakeScores(start: 1, stop: 1)
    for _ in 0..<40 { last = try detector.pushFrame(silence) } // ~3.2s de silêncio
    XCTAssertGreaterThanOrEqual(last.start, 0)
    XCTAssertLessThanOrEqual(last.start, 1)
    XCTAssertLessThan(last.start, 0.45, "silêncio não cruza o threshold de 'gravar'")
    XCTAssertLessThan(last.stop, 0.45, "silêncio não cruza o threshold de 'parar'")
  }
}
```

- [ ] **Step 2: Adicionar o XCTest ao alvo (4 inserções no pbxproj) + Raro.onnx ao bundle de teste**

Aplicar as 4 inserções no `project.pbxproj` (memória `raro-pattern-ios-xctest-pbxproj-4-insertions`), com 2 IDs novos únicos no namespace `CA0000...Exx`:
1. PBXBuildFile (~linha 44): `<ID-A> /* WakeWordDetectorTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = <ID-B> /* WakeWordDetectorTests.swift */; };`
2. PBXFileReference (~linha 118): `<ID-B> /* WakeWordDetectorTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WakeWordDetectorTests.swift; sourceTree = "<group>"; };`
3. PBXGroup RunnerTests children (grupo `331C8082294A63A400263BE5`): `<ID-B> /* WakeWordDetectorTests.swift */,`
4. PBXSourcesBuildPhase (`331C807D294A63A400263BE5`): `<ID-A> /* WakeWordDetectorTests.swift in Sources */,`

Garantir que `Raro.onnx` está no Copy Bundle Resources do target Runner (e acessível ao alvo de teste via `@testable import Runner` + Bundle(for:)).

- [ ] **Step 3: Rodar o teste e ver falhar**

Run:
```bash
bun run --filter '@raro/mobile' test:ios
```
Expected: FALHA de compilação ("cannot find 'WakeWordDetector' in scope"). Confirmar no output `Test Suite 'WakeWordDetectorTests' started` (senão as 4 inserções falharam — exit 0 não prova).

- [ ] **Step 4: Implementar o WakeWordDetector**

Create `apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift`:
```swift
import Foundation
import onnxruntime
import os.log

struct WakeScores { let start: Float; let stop: Float }

final class WakeWordDetector {
  private let log = OSLog(subsystem: "com.rarocamera/voice", category: "detector")
  private let env: ORTEnv
  private let melSession: ORTSession
  private let embedSession: ORTSession
  private let startSession: ORTSession
  private let stopSession: ORTSession
  private(set) var isLoaded = false
  private(set) var usingCoreML = false
  private var embeddingWindow: [[Float]] = []   // ring buffer de embeddings (janela do classifier)

  init() throws {
    env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
    let options = try ORTSessionOptions()
    usingCoreML = WakeWordDetector.tryEnableCoreML(options, log: log)
    melSession = try WakeWordDetector.session(env: env, options: options, resource: "melspectrogram")
    embedSession = try WakeWordDetector.session(env: env, options: options, resource: "embedding")
    startSession = try WakeWordDetector.session(env: env, options: options, resource: "raro_gravar")
    stopSession = try WakeWordDetector.session(env: env, options: options, resource: "raro_parar")
    os_log("detector loaded (coreml=%{public}@)", log: log, type: .info, usingCoreML ? "yes" : "no — CPU")
    isLoaded = true
  }

  // CoreML EP é condicional: o Step 0 (spike) determinou se a API existe nesta versão.
  // Substituir o corpo conforme o spike: se o método existir, habilita e retorna true;
  // se NÃO existir, retorna false (roda em CPU) — sem mascarar com try? silencioso.
  private static func tryEnableCoreML(_ options: ORTSessionOptions, log: OSLog) -> Bool {
    do {
      try options.appendCoreMLExecutionProvider(with: ORTCoreMLExecutionProviderOptions())
      return true
    } catch {
      os_log("CoreML EP unavailable, running on CPU: %{public}@", log: log, type: .error,
             error.localizedDescription)
      return false
    }
  }

  private static func session(env: ORTEnv, options: ORTSessionOptions, resource: String) throws -> ORTSession {
    guard let path = Bundle(for: WakeWordDetector.self).path(forResource: resource, ofType: "onnx") else {
      throw NSError(domain: "com.rarocamera/voice", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "modelo \(resource).onnx ausente no bundle"])
    }
    return try ORTSession(env: env, modelPath: path, sessionOptions: options)
  }

  // Stateful: cada frame de 80ms (1280 samples) → mel → embedding → empurra na janela →
  // classifica gravar/parar sobre a janela acumulada. Devolve os 2 scores.
  func pushFrame(_ frame: [Float]) throws -> WakeScores {
    let mel = try runMel(frame)
    let embedding = try runEmbedding(mel)
    embeddingWindow.append(embedding)
    let windowSize = WakeWordDetector.classifierWindow
    if embeddingWindow.count > windowSize { embeddingWindow.removeFirst(embeddingWindow.count - windowSize) }
    guard embeddingWindow.count == windowSize else { return WakeScores(start: 0, stop: 0) }
    let start = try classify(startSession, window: embeddingWindow)
    let stop = try classify(stopSession, window: embeddingWindow)
    return WakeScores(start: start, stop: stop)
  }
}
```

> ⚠️ **Ajuste obrigatório (lê de `raro-model-training.md`, NÃO inventa):** os nomes de recurso (`melspectrogram`/`embedding`/`raro_gravar`/`raro_parar`), `classifierWindow` (tamanho da janela emitido pela pipeline), e os corpos `runMel`/`runEmbedding`/`classify` (montagem de `ORTValue` com os shapes/nomes de tensor exatos via `ORTValue(tensorData:elementType:shape:)` + `session.run(withInputs:outputNames:runOptions:)`). A API de CoreML EP em `tryEnableCoreML` segue o que o Step 0 confirmou — se o spike achou que não há método, este helper retorna `false` direto (sem chamar API inexistente). Implementar `runMel`/`runEmbedding`/`classify`/`classifierWindow` como `private` neste mesmo arquivo, com os shapes de `raro-model-training.md`.

- [ ] **Step 5: Rodar o teste e ver passar**

Run:
```bash
bun run --filter '@raro/mobile' test:ios
```
Expected: PASS em `WakeWordDetectorTests`. Confirmar `Test Suite 'WakeWordDetectorTests' started` + 2 testes executados.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(voice): wakeworddetector com pipeline onnx + coreml ep"
```

---

## Task 4: AudioSessionCoordinator (dono da AVAudioSession) — TDD parcial

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Voice/AudioSessionCoordinator.swift`
- Test: `apps/mobile/ios/RunnerTests/AudioSessionCoordinatorTests.swift`
- Modify: `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` (4 inserções p/ o XCTest novo)
- Reuse: `apps/mobile/ios/Runner/Native/Voice/ObjCExceptionCatcher.{h,m}`

**Contexto:** O Coordinator é o dono único da AVAudioSession (`.playAndRecord`), instala/remove o tap, faz downsample para 16kHz mono, observa interrupções (ligação/Siri) e `AVAudioEngineConfigurationChange` (o engine se auto-desliga em mudança de config — confirmado via WebSearch — e precisa ser religado). Expõe closures determinísticas (`onFrame`, `onInterruption`) testáveis sem hardware, no padrão `CameraManagerFocusTests` (XCTestExpectation invertida).

> **Decisão técnica (validada):** cada consumidor do tap usa seu PRÓPRIO `AVAudioConverter` (16kHz mono p/ detector; formato cheio p/ trilha de vídeo se a Estratégia 1 vencer). Saída de samples é variável; callback do converter usa `.noDataNow`/`nil` para não entrar em loop (confirmado via WebSearch). O `installTap` é envolvido em `ObjCExceptionCatcher` (pode lançar NSException).

> ⚠️ **Categoria de áudio:** há tensão entre `.playAndRecord` (voz precisa) e `.ambient` (botão de volume usa, memória `raro-pattern-ios-volume-button-kvo`). O Coordinator centraliza a categoria; reavaliar interação com o volume na Task 6/gate.

- [ ] **Step 1: Escrever o teste que falha (ciclo de vida determinístico)**

Create `apps/mobile/ios/RunnerTests/AudioSessionCoordinatorTests.swift`:
```swift
import XCTest
@preconcurrency import AVFoundation
@testable import Runner

final class AudioSessionCoordinatorTests: XCTestCase {
  func testStopDoesNotEmitFramesAfterStop() {
    let coordinator = AudioSessionCoordinator()
    let unexpected = XCTestExpectation(description: "no frame after stop")
    unexpected.isInverted = true
    var frameCount = 0
    coordinator.onFrame = { _ in frameCount += 1; unexpected.fulfill() }
    coordinator.stop()
    wait(for: [unexpected], timeout: 0.3)
    XCTAssertEqual(frameCount, 0)
  }

  func testTargetFormatIs16kMono() {
    let coordinator = AudioSessionCoordinator()
    XCTAssertEqual(coordinator.targetSampleRate, 16000)
    XCTAssertEqual(coordinator.targetChannels, 1)
  }

  func testConfigChangeDelegatesRestartInsteadOfSelfRestart() {
    let coordinator = AudioSessionCoordinator()
    let expect = XCTestExpectation(description: "onShouldRestart fires on config change")
    coordinator.onShouldRestart = { expect.fulfill() }
    NotificationCenter.default.post(
      name: .AVAudioEngineConfigurationChange, object: coordinator.valueForEngineUnderTest())
    // running==false (nunca demos start), então NÃO deve disparar — pina que o guard `running` protege
    let inverted = XCTestExpectation(description: "no restart when not running")
    inverted.isInverted = true
    coordinator.onShouldRestart = { inverted.fulfill() }
    wait(for: [inverted], timeout: 0.2)
  }
}
```

> ⚠️ **Ajuste do teste:** `valueForEngineUnderTest()` é um helper de teste opcional — se preferir não expor o engine, remover o `testConfigChange...` e validar a delegação de restart apenas no gate device (Task 7). O invariante essencial (Coordinator NÃO se reinicia sozinho) está garantido pelo código (`handleConfigChange`/`handleInterruption` só chamam `onShouldRestart?()`, nunca `start()`).

- [ ] **Step 2: 4 inserções no pbxproj (XCTest novo)**

Mesmas 4 inserções da Task 3 Step 2, para `AudioSessionCoordinatorTests.swift`, com 2 novos IDs únicos `CA0000...Exx`.

- [ ] **Step 3: Rodar e ver falhar**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: FALHA de compilação ("cannot find 'AudioSessionCoordinator'"). Confirmar `Test Suite 'AudioSessionCoordinatorTests' started`.

- [ ] **Step 4: Implementar o Coordinator**

Create `apps/mobile/ios/Runner/Native/Voice/AudioSessionCoordinator.swift`:
```swift
import Foundation
@preconcurrency import AVFoundation
import os.log

final class AudioSessionCoordinator {
  let targetSampleRate: Double = 16000
  let targetChannels: AVAudioChannelCount = 1

  var onFrame: (([Float]) -> Void)?
  var onInterruptionBegan: (() -> Void)?
  // O Coordinator NÃO se reinicia sozinho — delega ao orquestrador (VoiceManager),
  // que é o dono único da transição de estado (evita dessincronia — memória
  // raro-pattern-flutter-async-native-state-needs-notifier).
  var onShouldRestart: (() -> Void)?

  private let log = OSLog(subsystem: "com.rarocamera/voice", category: "audio")
  private let engine = AVAudioEngine()
  private var converter: AVAudioConverter?
  private var running = false
  private let queue = DispatchQueue(label: "com.rarocamera.voice.audio")

  init() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleConfigChange(_:)),
      name: .AVAudioEngineConfigurationChange, object: engine)
  }

  func start() -> Bool {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth])
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      os_log("session setup failed: %{public}@", log: log, type: .error, error.localizedDescription)
      return false
    }
    let input = engine.inputNode
    let inFormat = input.outputFormat(forBus: 0)
    guard inFormat.sampleRate > 0, inFormat.channelCount > 0,
          let outFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                        sampleRate: targetSampleRate,
                                        channels: targetChannels, interleaved: false) else {
      return false
    }
    converter = AVAudioConverter(from: inFormat, to: outFormat)
    let raised = ObjCExceptionCatcher.catchException {
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: inFormat) { [weak self] buffer, _ in
        self?.handleBuffer(buffer, outFormat: outFormat)
      }
      self.engine.prepare()
    }
    if let raised = raised {
      os_log("installTap raised: %{public}@", log: log, type: .error, raised.localizedDescription)
      return false
    }
    do { try engine.start() } catch {
      input.removeTap(onBus: 0); return false
    }
    running = true
    return true
  }

  func stop() {
    queue.sync {
      guard running else { return }
      engine.inputNode.removeTap(onBus: 0)
      engine.stop()
      running = false
    }
  }

  private func handleBuffer(_ buffer: AVAudioPCMBuffer, outFormat: AVAudioFormat) {
    guard let converter = converter,
          let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: 4096) else { return }
    var consumed = false
    var error: NSError?
    converter.convert(to: out, error: &error) { _, status in
      if consumed { status.pointee = .noDataNow; return nil }
      consumed = true
      status.pointee = .haveData
      return buffer
    }
    if let error = error {
      os_log("convert error: %{public}@", log: log, type: .error, error.localizedDescription); return
    }
    guard let channel = out.floatChannelData?[0] else { return }
    let frames = Array(UnsafeBufferPointer(start: channel, count: Int(out.frameLength)))
    onFrame?(frames)
  }

  @objc private func handleInterruption(_ note: Notification) {
    guard let info = note.userInfo,
          let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
    if type == .began {
      onInterruptionBegan?()
    } else {
      // NÃO reinicia aqui — delega ao orquestrador, que re-chama start() e re-emite estado.
      onShouldRestart?()
    }
  }

  @objc private func handleConfigChange(_ note: Notification) {
    guard running else { return }
    os_log("engine config change — delegating restart", log: log, type: .info)
    onShouldRestart?()
  }

  deinit { NotificationCenter.default.removeObserver(self) }
}
```

> ⚠️ **Ajuste:** a categoria `.measurement` + `.mixWithOthers` é a hipótese de partida para coexistir com a câmera; o gate device (Task 7) confirma ou ajusta a categoria/options. `ObjCExceptionCatcher.catchException` é o nome autoritativo (header `+ catchException:`), já usado no VoiceManager atual.

- [ ] **Step 5: Rodar e ver passar**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS em `AudioSessionCoordinatorTests` (2 testes). Confirmar `Test Suite ... started`.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Voice/AudioSessionCoordinator.swift apps/mobile/ios/RunnerTests/AudioSessionCoordinatorTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(voice): audiosessioncoordinator dono da avaudiosession + tap 16khz"
```

---

## Task 5: Reescrever VoiceManager (orquestrador) — TDD

**Files:**
- Modify (reescrever): `apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift`
- Modify: `apps/mobile/ios/Runner/Native/Voice/VoiceHostApiImpl.swift` (só se mudar assinatura de callback)
- Modify: `apps/mobile/ios/RunnerTests/VoiceManagerTests.swift` (remover testes do parser SFSpeech, adicionar testes do orquestrador)
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift:35-40`

**Contexto:** O `VoiceManager` reescrito conecta Coordinator → Detector → WakeCommand, mantendo as closures que `VoiceHostApiImpl` espera (`onCommand: (VoiceCommand) -> Void`, `onStateChanged: (VoiceListeningState) -> Void`, `isAvailable`, `start`, `stop`, `isRecordingActive`). Aplica os parâmetros de calibração do concorrente: score ≥ 0.45, debounce 2500ms, cooldown inicial 2500ms, RMS gate antes da inferência. DOIS comandos: o detector emite "wake"; a distinção start/stop segue a decisão da spec (Q7: dois comandos "Raro gravar"/"Raro parar"). Como o detector de wake-word puro só detecta a wake word, a distinção start/stop precisa de um segundo modelo OU de um classificador de comando — **decisão de arquitetura abaixo**.

> **Decisão 5a TRAVADA (Task 1):** dois classificadores (`raro_gravar`→.start, `raro_parar`→.stop). O `WakeWordDetector.pushFrame` devolve `WakeScores(start, stop)`; o Manager mapeia qual cruzou o threshold. Sem placeholder de comando único.

- [ ] **Step 1: Reescrever os testes (remover parser SFSpeech, pinar o orquestrador)**

Modify `apps/mobile/ios/RunnerTests/VoiceManagerTests.swift` — remover `testParserMatchesGravarStart/PararStop/IgnoresNonCommand` (o `VoiceCommandParser` é descartado). Adicionar:
```swift
import XCTest
@testable import Runner

final class VoiceManagerTests: XCTestCase {
  func testDoesNotStartWhenRecordingActive() {
    let manager = VoiceManager(wakeWord: "Raro")
    manager.isRecordingActive = { true }
    var states: [VoiceListeningState] = []
    manager.onStateChanged = { states.append($0) }
    manager.start()
    // com gravação ativa, a estratégia de handoff decide; pino o invariante:
    // o manager NUNCA reporta .unavailable só por estar gravando.
    XCTAssertFalse(states.contains(.unavailable))
  }

  func testDebounceSuppressesRapidDuplicateWakes() {
    let manager = VoiceManager(wakeWord: "Raro")
    var commands: [VoiceCommand] = []
    manager.onCommand = { commands.append($0) }
    manager.handleDetection(command: .start, score: 0.9, atUptime: 0)
    manager.handleDetection(command: .start, score: 0.9, atUptime: 1.0) // < 2.5s debounce
    XCTAssertEqual(commands.count, 1, "debounce 2500ms suprime o 2º wake")
  }

  func testScoreBelowThresholdIsIgnored() {
    let manager = VoiceManager(wakeWord: "Raro")
    var commands: [VoiceCommand] = []
    manager.onCommand = { commands.append($0) }
    manager.handleDetection(command: .start, score: 0.30, atUptime: 0) // < 0.45
    XCTAssertEqual(commands.count, 0)
  }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: FALHA de compilação (`handleDetection`/novo VoiceManager não existem). Confirmar `Test Suite 'VoiceManagerTests' started`.

- [ ] **Step 3: Reescrever o VoiceManager**

Substituir o corpo de `apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift` (remover SFSpeech, `VoiceCommandParser`, `SFSpeechAudioBufferRecognitionRequest`, etc.). Manter `enum VoiceCommand { case start; case stop }`, a herança `NSObject` (preservar p/ compatibilidade do bridging) e as closures públicas. Implementar:
```swift
import Foundation
@preconcurrency import AVFoundation
import os.log

enum VoiceCommand { case start; case stop }

final class VoiceManager: NSObject {
  var onCommand: ((VoiceCommand) -> Void)?
  var onStateChanged: ((VoiceListeningState) -> Void)?
  var isRecordingActive: (() -> Bool)?

  private let log = OSLog(subsystem: "com.rarocamera/voice", category: "wake")
  private let wakeWord: String
  private let coordinator = AudioSessionCoordinator()
  private var detector: WakeWordDetector?

  // calibração (ref. concorrente Sensory, memória raro-competitor-okcamera-android-apk-teardown)
  private let scoreThreshold: Float = 0.45
  private let debounceSeconds: TimeInterval = 2.5
  private let rmsStart: Float = 0.026
  private var lastCommandUptime: TimeInterval = -.infinity
  private var startedAtUptime: TimeInterval = 0

  init(wakeWord: String) { self.wakeWord = wakeWord; super.init() }

  func isAvailable(_ completion: @escaping (Bool) -> Void) {
    let modelOK: Bool
    do { try ensureDetector(); modelOK = detector?.isLoaded == true }
    catch {
      os_log("detector load failed: %{public}@", log: log, type: .error, error.localizedDescription)
      modelOK = false
    }
    requestMicPermission { ok in completion(ok && modelOK) }
  }

  // padrão iOS17+ / legado (espelha o VoiceManager atual, sem símbolo fantasma)
  private func requestMicPermission(_ completion: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission { completion($0) }
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission { completion($0) }
    }
  }

  func start() {
    do { try ensureDetector() } catch {
      os_log("detector load failed: %{public}@", log: log, type: .error, error.localizedDescription)
      onStateChanged?(.unavailable); return
    }
    coordinator.onFrame = { [weak self] frame in self?.process(frame: frame) }
    coordinator.onInterruptionBegan = { [weak self] in self?.onStateChanged?(.paused) }
    coordinator.onShouldRestart = { [weak self] in self?.restartListening() }
    startedAtUptime = ProcessInfo.processInfo.systemUptime
    onStateChanged?(coordinator.start() ? .listening : .unavailable)
  }

  func stop() {
    coordinator.stop()
    onStateChanged?(.idle)
  }

  // dono único da transição: religa o engine e re-emite o estado (config change / fim de interrupção)
  private func restartListening() {
    startedAtUptime = ProcessInfo.processInfo.systemUptime
    onStateChanged?(coordinator.start() ? .listening : .unavailable)
  }

  private func ensureDetector() throws {
    if detector == nil { detector = try WakeWordDetector() }
  }

  private func process(frame: [Float]) {
    let now = ProcessInfo.processInfo.systemUptime
    guard now - startedAtUptime > debounceSeconds else { return }  // cooldown inicial
    let rms = sqrt(frame.reduce(0) { $0 + $1 * $1 } / Float(max(frame.count, 1)))
    guard rms >= rmsStart else { return }  // VAD barato antes da inferência
    let scores: WakeScores
    do { scores = try detector?.pushFrame(frame) ?? WakeScores(start: 0, stop: 0) }
    catch {
      os_log("inference error: %{public}@", log: log, type: .error, error.localizedDescription)
      return
    }
    // dois classificadores: maior score acima do threshold vence
    if scores.start >= scores.stop {
      handleDetection(command: .start, score: scores.start, atUptime: now)
    } else {
      handleDetection(command: .stop, score: scores.stop, atUptime: now)
    }
  }

  func handleDetection(command: VoiceCommand, score: Float, atUptime now: TimeInterval) {
    guard score >= scoreThreshold else { return }
    guard now - lastCommandUptime >= debounceSeconds else { return }
    lastCommandUptime = now
    os_log("wake detected: %{public}@ score=%.2f", log: log, type: .info,
           command == .start ? "start" : "stop", score)
    onCommand?(command)
  }
}
```

> ⚠️ **Ajustes:** (1) remover qualquer instrumentação DBG residual do arquivo antigo. (2) `requestMicPermission` espelha o branch `#available` que o VoiceManager atual já tem (VoiceManager.swift:55-61) — sem símbolo fantasma. (3) `process` usa `pushFrame`→`WakeScores` (contrato da Task 3); a regra "maior score vence" é a calibração de partida — o gate device pode exigir thresholds separados por comando.

- [ ] **Step 4: Atualizar AppDelegate (instanciar com o novo Manager)**

Modify `apps/mobile/ios/Runner/AppDelegate.swift:35-40` — a assinatura pública do VoiceManager (`init(wakeWord:)`, `isRecordingActive`, closures) é preservada, então o wiring muda pouco. Confirmar que `isAvailable` agora é o do novo Manager (callback). Manter `voiceManager.isRecordingActive = { [weak hostApi] in hostApi?.cameraManager.isRecording ?? false }`.

- [ ] **Step 5: Rodar e ver passar**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS em `VoiceManagerTests` (3 testes novos). Confirmar `Test Suite ... started`.

- [ ] **Step 6: Analyze + smoke build**

Run:
```bash
bun run --filter '@raro/mobile' analyze && cd apps/mobile && flutter build ios --simulator --no-codesign
```
Expected: analyze 0 issues; build sucede.

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Voice/VoiceManager.swift apps/mobile/ios/Runner/Native/Voice/VoiceHostApiImpl.swift apps/mobile/ios/Runner/AppDelegate.swift apps/mobile/ios/RunnerTests/VoiceManagerTests.swift
git commit -m "feat(voice): reescreve voicemanager como orquestrador onnx (remove sfspeech)"
```

---

## Task 6: Toque cirúrgico na câmera + Info.plist background

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift:277-291`
- Modify: `apps/mobile/ios/Runner/Info.plist`

**Contexto:** Para a escuta sobreviver durante a gravação, a câmera não pode monopolizar o mic de forma que derrube a AVAudioSession do Coordinator. A spec deixou DUAS estratégias (tap único compartilhado vs. método do concorrente: parar tap da escuta e alimentar o detector pela gravação). **A API exata NÃO é `isUsingBuiltInMicForRecording` (confirmado: não é property pública).** Esta task investiga no device (spike) qual estratégia funciona, então é parcialmente investigativa.

> ⚠️ **CLAUDE.md §11:** não improvisar. O caminho concreto (ex.: `session.automaticallyConfiguresApplicationAudioSession = false` na AVCaptureSession + Coordinator dono da sessão; OU `AVCaptureDeviceInput.multichannelAudioMode`; OU não adicionar o audio input na AVCaptureSession e injetar o áudio da gravação a partir do tap do Coordinator) é decidido pelo spike device da Task 7, não aqui.

- [ ] **Step 1: Adicionar UIBackgroundModes ao Info.plist**

Modify `apps/mobile/ios/Runner/Info.plist` — adicionar:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```
(Background audio NÃO exige .entitlements separado — só esta chave. Memória/leitura confirmam.)

- [ ] **Step 2: Atualizar a purpose string de microfone (contexto wake-word)**

Modify `apps/mobile/ios/Runner/Info.plist:31-32` — `NSMicrophoneUsageDescription` para refletir o uso de escuta contínua (espelhar o concorrente: "A Raro Camera usa o microfone para detectar o comando de voz e gravar áudio."). Remover `NSSpeechRecognitionUsageDescription` (não usamos mais Speech framework).

- [ ] **Step 3: Preparar o ponto cirúrgico (sem decidir a API ainda)**

Marcar em `CameraManager.swift:277-291` o ponto onde a estratégia entra. Implementação concreta no Step seguinte depende do spike. Para o smoke não regredir, deixar o comportamento atual (mic na AVCaptureSession) até o spike validar a alternativa.

- [ ] **Step 4: Smoke build (não regredir)**

Run: `cd apps/mobile && flutter build ios --simulator --no-codesign`
Expected: build sucede.

- [ ] **Step 5: Commit (parcial — Info.plist + marcação)**

```bash
git add apps/mobile/ios/Runner/Info.plist apps/mobile/ios/Runner/Native/Camera/CameraManager.swift
git commit -m "feat(voice): uibackgroundmodes audio + purpose string mic (wake-word continuo)"
```

> A implementação final do handoff de mic é fechada no Step de device da Task 7, junto com a prova de coexistência. Commit dedicado lá.

---

## Task 7: GATE DE VIABILIDADE no iPhone 12 (PAUSAR — dono conecta o device)

**Files:**
- Modify (conforme spike): `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` (estratégia de handoff vencedora)
- Create: `docs/superpowers/notes/voice-gate-iphone12.md` (evidência: logs, ffprobe, recall)

**Contexto:** Pré-condição OBRIGATÓRIA do flip (spec + ADR-0023). Mede no iPhone 12 físico (não Simulator): (a) detecção "Raro" >80% em silêncio + falsos positivos baixos; (b) coexistência voz+gravação sem matar a escuta + vídeo com áudio; (c) tamanho do modelo+lib aceitável no bundle.

- [ ] **Step 1: GATE §10 device — PARAR e avisar o dono**

> ⚠️ **PARAR AQUI e avisar o dono** que a próxima etapa é manual no iPhone 12. Não prosseguir sem confirmação + device conectado.

- [ ] **Step 2: Build profile + instalar no device (terminal-first)**

Run (com os 2 git overrides do SPM):
```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --profile
xcrun devicectl device install app --device <udid> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <udid> com.rarocamera
```
(debug não roda standalone — usar profile; memória `raro-pattern-flutter-debug-vs-release-on-device`)

- [ ] **Step 3: Medir detecção (a) com log instrumentado**

Capturar `os_log` subsystem `com.rarocamera/voice` via `pymobiledevice3`:
```bash
python3 -m pymobiledevice3 syslog live | grep -iE "com.rarocamera/voice|wake detected|score"
```
Falar "Raro gravar"/"Raro parar" N vezes (várias vozes/distâncias). Contar detecções / total ≥ 80%. Rodar áudio sem a palavra X min, contar falsos positivos. Registrar em `voice-gate-iphone12.md`.

- [ ] **Step 4: Medir coexistência (b) + escolher estratégia de handoff**

Gravar vídeo com a escuta ativa. Confirmar no log que o estado permanece `listening` (não `paused`) durante REC. Puxar o `.mp4` e provar trilha de áudio:
```bash
xcrun devicectl device copy from --device <udid> --domain-type appDataContainer --source <vault-path>/<id>.mp4 --destination /tmp/raro_gate.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate -of default=noprint_wrappers=1 /tmp/raro_gate.mp4
```
Expected: trilha de áudio presente E escuta sobreviveu. Se a Estratégia 1 (tap único) der glitch, aplicar a Estratégia 2 (concorrente) em `CameraManager.swift` e re-testar. Fechar a implementação do handoff aqui.

- [ ] **Step 4b: Medir detecção em BACKGROUND / tela bloqueada**

Com o app rodando, **bloquear a tela** (ou enviar o app para background) e falar "Raro gravar". Confirmar no syslog que `wake detected: start` ainda dispara com a tela bloqueada (UIBackgroundModes:audio mantendo o tap vivo). Repetir com "Raro parar". Registrar em `voice-gate-iphone12.md`. Este é o Observable goal de background da spec (linha 115) — sem ele, o gate não cobre o caso de uso central (celular guardado).

- [ ] **Step 4c: Validar interrupção (paused → listening)**

Com a escuta ativa, disparar uma interrupção (ligar para o device / acionar Siri) e confirmar no log: estado vai a `paused` no início e volta a `listening` ao fim (o `onShouldRestart` do Coordinator → `restartListening` do Manager). Registrar.

- [ ] **Step 5: Medir tamanho (c)**

```bash
du -sh build/ios/iphoneos/Runner.app
```
Registrar tamanho do `.app` e do(s) modelo(s). Confirmar aceitável.

> ⚠️ **Se (c) reprovar (lib ONNX full ~64MB inflou o bundle):** NÃO há task de redução planejada por padrão (custom/reduced build é trabalho não-trivial). Levar ao dono a decisão: (i) aceitar o tamanho, ou (ii) abrir uma task de custom build do ONNX Runtime (operator reduction, só ios-arm64). Registrar a decisão.

- [ ] **Step 6: Decisão de GATE**

Registrar em `voice-gate-iphone12.md`: PASS (a≥80% E b OK E c aceitável) ou FAIL.
- **PASS** → seguir para Task 8 (flip).
- **FAIL em (a)** → PARAR, voltar ao dono: plano B (treino melhor / Porcupine / Sensory com custo). NÃO flipar.

- [ ] **Step 7: Commit (handoff final + evidência)**

```bash
git add apps/mobile/ios/Runner/Native/Camera/CameraManager.swift docs/superpowers/notes/voice-gate-iphone12.md
git commit -m "feat(voice): fecha handoff mic-gravacao + evidencia do gate iphone 12"
```

---

## Task 8: Flip _voiceEngineAvailable + não-regressão

**Files:**
- Modify: `apps/mobile/lib/features/voice/application/voice_controller.dart:12`

**Contexto:** ÚNICO toque na camada Dart. Só após o gate PASS (Task 7). Liga o caminho real: o controller passa a respeitar `ControlMode.voice`, chamar `isAvailable`/`startListening`.

- [ ] **Step 1: Flip da flag**

Modify `apps/mobile/lib/features/voice/application/voice_controller.dart:12`:
```dart
const bool _voiceEngineAvailable = true;
```

- [ ] **Step 2: Rodar a suíte Dart completa (não-regressão dos 312)**

Run: `bun run --filter '@raro/mobile' test`
Expected: PASS. O teste `voice_controller_test.dart` que pinava "engine gated off → startListening NUNCA chamado" vai precisar de atualização — ajustar esse teste para o novo comportamento (com flag true + controlMode=voice + isAvailable=true → startListening chamado 1x).

- [ ] **Step 3: Ajustar o teste de gating (se quebrou)**

Modify `apps/mobile/test/features/voice/voice_controller_test.dart` — o caso que assumia `verifyNever(repo.startListening)` com engine off agora deve refletir engine on. Pinar: flag true + controlMode=voice + available=true → `verify(repo.startListening).called(1)`. Manter os outros casos (controlMode=volume → stop; available=false → VoiceUnavailable).

- [ ] **Step 4: Rodar tudo de novo**

Run: `bun run --filter '@raro/mobile' test && bun run --filter '@raro/mobile' analyze`
Expected: PASS + 0 issues.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/voice/application/voice_controller.dart apps/mobile/test/features/voice/voice_controller_test.dart
git commit -m "feat(voice): liga engine de voz (flip _voiceengineavailable) apos gate iphone 12"
```

---

## Task 9: Fechar débito Frente A (ffprobe pré-roll) se aberto

**Files:**
- Read: `docs/sessions/0023-s2c-preroll-debts-voice-sfspeech-deadend-openwakeword-decision.md`

**Contexto:** Débito herdado: o gate §10 ffprobe formal da Frente A (pré-roll combinado pós-A2/A3) não foi rodado isoladamente. Provar DTS monotônico + áudio em ~0s no `vault/<id>.mp4`.

- [ ] **Step 1: Verificar se já fechou**

Checar se há evidência ffprobe do pré-roll combinado em sessions/notes recentes. Se já fechado, marcar e pular.

- [ ] **Step 2: Se aberto — GATE §10 device (PAUSAR)**

> ⚠️ Reusar o device do gate da Task 7. Gravar 1 clipe com pré-roll, puxar o `.mp4` combinado, rodar:
```bash
ffprobe -v error -show_entries packet=dts_time -select_streams v:0 -of csv /tmp/raro_preroll.mp4 | head
ffprobe -v error -select_streams a:0 -show_entries stream=start_time -of default=noprint_wrappers=1 /tmp/raro_preroll.mp4
```
Expected: DTS monotônico crescente + áudio start ~0s.

- [ ] **Step 3: Commit (se houve evidência nova)**

```bash
git add docs/superpowers/notes/voice-gate-iphone12.md
git commit -m "docs(docs): evidencia ffprobe pré-roll frente a (debito 0023 fechado)"
```

---

## Pós-implementação

- [ ] `/verify-slice` (analyze + test + design-fidelity se tocou tela)
- [ ] Atualizar `docs/10-CHANGELOG.md` (entrada da feature de voz)
- [ ] `/session-end` (fecha session log, define próxima sessão)
- [ ] PR do branch `feat/camera-native-bridge`

## Self-Review notes (do autor do plano)

- **Cobertura da spec:**
  - Observable goals → modelo carrega (Task 3), "Raro gravar"→start / "Raro parar"→stop (Task 5+7 device), escuta sobrevive REC + vídeo com áudio (Task 7 Step 4), interrupção→paused→listening (Task 4), permissão negada→unavailable + REC manual ok (Task 5), background (Task 6+7), 312 testes verdes (Task 8). ✓
  - Q-table: Q1 background → Task 6/7; Q2 engine LiveKit/ONNX → Task 1-3; Q4 handoff (2 estratégias) → Task 6/7 spike; Q5 Abordagem A → Task 3/4/5; Q6 Pigeon/Dart inalterado → só Task 8 flip; Q7 dois comandos → Task 5 decisão 5a. ✓
  - Riscos: detecção PT-BR → gate (a) Task 7; bateria → RMS gate Task 5 + medir Task 7; tamanho lib → gate (c) Task 7; handoff glitch → 2 estratégias Task 7; ConfigurationChange → Task 4. ✓
  - Build sequence (9 passos) → Tasks 1-9. ✓
- **Ordem de dependências:** Task 0 (ADR) → 1 (modelo) → 2 (SPM) → 3 (detector, precisa do modelo+SPM) → 4 (coordinator) → 5 (manager, precisa de 3+4) → 6 (câmera+plist) → 7 (gate device, fecha handoff) → 8 (flip, só após gate PASS) → 9 (débito).
- **Pontos a confirmar pelo implementer (incertezas honestas, não fingidas):**
  1. **Decisão 5a TRAVADA** (dois modelos `raro_gravar`/`raro_parar`). Reconfirmar com o dono no início da Task 1 só se quiser 5b (muda quantos modelos treinar). O contrato `WakeWordDetector.pushFrame → WakeScores(start,stop)` é consistente entre Tasks 3 e 5.
  2. **Shapes/nomes exatos do modelo** — só conhecidos após a Task 1; registrados em `raro-model-training.md`; Tasks 3 lê de lá (não inventa). Inclui o tamanho da janela do classifier (`classifierWindow`) e se é stateful.
  3. **API de coexistência de mic** — `isUsingBuiltInMicForRecording` NÃO é pública (confirmado via WebSearch); estratégia decidida no spike device (Task 7 Step 4). Plano B se ambas estratégias falharem: gravar áudio a partir do tap do Coordinator em vez do audio input na AVCaptureSession.
  4. **API CoreML EP** — NÃO confirmada na doc do pacote SPM (Context7); é SPIKE explícito (Task 3 Step 0). Se ausente, roda em CPU com log (sem `try?` silencioso). Impacta o risco de tamanho (Task 7 Step 5).
  5. **Categoria AVAudioSession** (`.playAndRecord`+`.mixWithOthers`+`.measurement` vs interação com volume `.ambient`) — validar no device (Task 7).
  6. **Dono único de estado** — o Coordinator NUNCA chama `start()` sozinho; delega via `onShouldRestart`/`onInterruptionBegan` ao VoiceManager, que re-emite o estado (evita dessincronia — memória async-native-state-needs-notifier).
- **Correções aplicadas pós-review adversarial (2026-06-09):** removido símbolo fantasma `AVAudioApplicationCompat` (→ branch `#available(iOS17)` real); `ObjCExceptionCatcher.catch`→`.catchException`; CoreML EP rebaixado a spike + `do/catch` com log (sem `try?`); placeholder de comando único eliminado (→ `WakeScores`/dois classificadores); conflito de dono de estado resolvido (Coordinator delega restart); `VoiceManager` mantém `NSObject`; step de gate de background + interrupção adicionados (Task 7 4b/4c); citação falsa de §13 sobre "Add Package" corrigida.
- **Não-regressão:** 312 testes Dart são o gate do flip (Task 8); os XCTest nativos novos exigem confirmar `Test Suite started` (exit 0 não prova — memória pbxproj-4-insertions).
