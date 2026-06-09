# 2026-06-09 — voice-wakeword-livekit-onnx-engine

> Spec da feature de voz funcional (S2.D): migração da engine de wake-word do SFSpeechRecognizer (beco-sem-saída comprovado) para um modelo dedicado on-device (LiveKit/ONNX), copiando a arquitetura de áudio do concorrente (provada por teardown iOS+Android), mantendo o contrato Pigeon e a camada Dart inalterados. Brainstorming conduzido em 2026-06-09 com inspeção do concorrente no device do dono.

## Status

`Approved` — brainstorming concluído 2026-06-09; pré-condição de implementação é o gate de viabilidade no iPhone 12.

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues (assina o WHAT)
- **Implementer agent:** `implementer` (Swift nativo) + `flutter-test-author` (TDD do contrato Dart, que já existe)
- **Validator agent:** `validator`

## Reading order (pre-flight obrigatório)

1. `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md` — decisão de engine (autoritativa)
2. `docs/decisions/0022-voice-on-device-sfspeechrecognizer.md` — só a engine foi superseded; modo selecionável, dois comandos, contrato Pigeon engine-agnóstico e indicador sempre-visível PERMANECEM válidos
3. `docs/sessions/0023-s2c-preroll-debts-voice-sfspeech-deadend-openwakeword-decision.md` — o que falhou e por quê
4. `CLAUDE.md` (manual autoritativo) + `docs/Blueprint.md` (§2 stack)
5. Memórias: `raro-competitor-okcamera-android-apk-teardown` (parâmetros reais do concorrente), `raro-competitor-okcamera-replay-model`, `raro-pattern-ios-wake-word-no-native-api`, `raro-pattern-flutter-async-native-state-needs-notifier`, `raro-preroll-rec-design-s2c`

## Problem

A feature de voz é diferencial central do RARO (comando hands-free "Raro gravar"/"Raro parar"). A engine escolhida no ADR-0022 (SFSpeechRecognizer com `requiresOnDeviceRecognition=true`) provou-se inviável para wake-word contínuo no iPhone 12 físico: `kAFAssistantErrorDomain 1110` em todo request após o 1º (funciona exatamente 1×), teto de ~1min/sessão, endpointer exige onset limpo. O ADR-0023 decidiu migrar para um modelo dedicado on-device. Esta spec define COMO, à luz da evidência extraída do concorrente.

## Evidência de campo (teardown do concorrente "Ok Câmera")

Inspeção conduzida no brainstorming 2026-06-09 nos devices do dono:

**iOS (`fmdev.okcamera`, v1.5)** — via `pymobiledevice3` syslog + Info.plist:
- Grava vídeo SEM monopolizar o mic: `isUsingBuiltInMicForRecording: NO` (repetido)
- Detecção 100% on-device (zero rede durante a fala)
- NÃO usa Speech/CoreSpeech da Apple (o daemon `corespeechd`/Siri é SUSPENSO quando o app grava: "VoiceTrigger cannot be turned on since there is other app recording")
- Zero ONNX/CoreML/ANE/TFLite atribuível ao app → engine proprietária autossuficiente
- Toca beep de confirmação no wake (`AudioQueueNewOutput`); `UIBackgroundModes: ['audio']`; `MinimumOSVersion 18.0`

**Android (`br.com.okcamera.goldgravar`, v71.1)** — via `adb pull` + `jadx` + `apktool` (APK não-criptografado revelou o que o iOS escondeu):
- **Engine = Sensory TrulyNatural 7.5** (`libSnsr.so` + modelo `assets/ok_camera.snsr`, "licensed to OK Camera PL")
- **Sensory é SDK comercial PAGO** → mesma barreira do Porcupine (rejeitado no ADR-0023 por custo vs R$9,90/mês). Por isso RARO NÃO copia a engine, só a arquitetura.
- Parâmetros reais (referência de calibração): 16kHz mono, chunks 20ms (320 samples), score mínimo 0.45, debounce 2500ms, cooldown inicial 2500ms, RMS gate 0.026/0.012, normalização de frase para dedup, beep no wake
- Handoff mic↔gravação: `enqueueExternalPcm` — PARA o `AudioRecord` da escuta quando a gravação começa e alimenta a engine via fila de PCM da própria gravação (NÃO mantém dois consumidores do mic simultâneos)
- Background: `foregroundServiceType` CAMERA+MICROPHONE + `PARTIAL_WAKE_LOCK`
- É TOGGLE (uma palavra alterna start/stop). RARO difere: DOIS comandos distintos.

Detalhe completo em `raro-competitor-okcamera-android-apk-teardown`.

## Decisão de engine

**LiveKit/ONNX (Apache 2.0, grátis), rodando via ONNX Runtime + CoreML Execution Provider.**

- Sensory (o que o concorrente usa) e Porcupine estão FORA por custo (conflitam com R$9,90/mês).
- OpenWakeWord puro está enfraquecido: notebook oficial quebrado desde nov/2025 (issue #296), English-only, embedding do Google possivelmente nunca viu PT-BR.
- LiveKit-wakeword: treina o modelo "Raro" em 1 comando, exporta ONNX drop-in no mesmo runtime, suporta PT-BR (VoxCPM), SDK Swift de referência, falso-positivo ~100× menor que OpenWakeWord. ADR-0023 cita "OpenWakeWord/LiveKit-wakeword" como par válido — LiveKit está dentro do aprovado.
- ONNX Runtime integra via **Swift Package Manager** (`microsoft/onnxruntime-swift-package-manager`), coerente com o Runner que já usa SPM (não CocoaPods). Validado via Context7.

## Sizing (auto-sizing)

- [x] **Large** (novo binário/dep nativa ONNX Runtime + reescrita de bridge nativa + treino de modelo) — exige `/new-plan` + ADR-0023 (já Accepted) + gate de device. `adr-guardian` confirma se a integração ONNX Runtime precisa só registrar no Blueprint §2 ou ADR adicional.

## Q-table (decisões travadas no brainstorming 2026-06-09)

| # | Question | Answer |
|---|----------|--------|
| 1 | Background com tela bloqueada? | SIM, igual concorrente (foreground modificado/minimizado/tela bloqueada). Só morre se app for morto no app-switcher (limite iOS). Não se preocupar com aprovação da loja (decisão do dono). |
| 2 | Engine de detecção? | LiveKit/ONNX grátis (não Sensory/Porcupine pagos, não OpenWakeWord puro). |
| 3 | Detector exato do concorrente? | Identificado: Sensory TrulyNatural 7.5. Inviável por custo. Copiamos só a arquitetura de áudio. |
| 4 | Áudio do vídeo durante escuta? | Tap único compartilhado (16kHz mono p/ detector + 48kHz estéreo p/ trilha) OU método do concorrente (parar mic da escuta, alimentar engine pela gravação). Spike decide. |
| 5 | Organização do nativo? | Abordagem A: `AudioSessionCoordinator` dono único da AVAudioSession + `WakeWordDetector` + `VoiceManager` orquestrador. |
| 6 | Contrato Pigeon / Dart muda? | NÃO. Engine-agnóstico. Só flipa `_voiceEngineAvailable=true` após o gate. |
| 7 | Toggle ou dois comandos? | Dois comandos: "Raro gravar" / "Raro parar" (ADR-0022, mais explícito que o toggle do concorrente). |

## Arquitetura (Abordagem A — aprovada)

Camadas (topo Dart → base CoreAudio):

1. **Dart (INALTERADO):** `VoiceController`, `VoiceRepository`, `voice_listening_indicator`, `RecordingController.toggle` (fonte única). 312 testes verdes. Flip `_voiceEngineAvailable=true` (`voice_controller.dart:12`) é o único toque, após o gate.
2. **Contrato Pigeon (INALTERADO):** `voice_api.dart` — `VoiceHostApi(isAvailable/startListening/stopListening)`, `VoiceFlutterApi(onWakeDetected(WakeCommand)/onListeningStateChanged(VoiceListeningState))`, enums `WakeCommand{start,stop}` / `VoiceListeningState{idle,listening,paused,unavailable}`.
3. **Swift nativo (REESCRITO/NOVO):**
   - `VoiceHostApiImpl` — ponte Pigeon fina (existe, ajustar)
   - ⭐ `VoiceManager` — orquestra tap → detector → emite `WakeCommand` (reescrito, sem SFSpeech)
   - ⭐ `AudioSessionCoordinator` — DONO ÚNICO da `AVAudioSession`; resolve handoff mic↔gravação; observa interrupções e `AVAudioEngineConfigurationChange` e religa o engine
   - ⭐ `WakeWordDetector` — pipeline ONNX **stateful** (melspectrogram → embedding → **DOIS classificadores**); buffer 16kHz mono → `WakeScores{start, stop}`. Decisão 5a (ver §Decisões): wake-word puro só detecta presença de UMA frase, então treinamos dois classificadores de frase inteira — `raro_gravar.onnx` (→ `WakeCommand.start`) e `raro_parar.onnx` (→ `WakeCommand.stop`) — compartilhando os estágios mel+embedding.
   - ⭐ Assets no bundle (4 arquivos `.onnx`, ~200KB-1MB cada): estágios genéricos `melspectrogram.onnx` + `embedding_model.onnx` (vêm do pacote livekit-wakeword, compartilhados) + classificadores treinados `raro_gravar.onnx` + `raro_parar.onnx`.
4. **Câmera (TOQUE CIRÚRGICO):** `CameraManager`/`RecordingPipeline` — gravar sem monopolizar o mic via AVAudioSession (replicar `isUsingBuiltInMicForRecording: NO`).
5. **iOS/CoreAudio:** `AVAudioSession .playAndRecord` persistente, mic tap, `UIBackgroundModes: audio`, ONNX Runtime + CoreML EP.

Mudança estrutural vs. SFSpeech: o `AudioSessionCoordinator` vira dono único da sessão (antes a voz configurava e nunca revertia — causa dos 6 fixes em cascata da session 0023); a câmera negocia o mic com ele.

## Fluxo de dados

**Detecção contínua:** mic tap → downsample 16kHz mono → VAD/RMS gate (0.026/0.012, poupa bateria) → 3× ONNX (mel→embed→classif) → score ≥ threshold? → beep + `onWakeDetected` → Dart → `RecordingController.toggle`.

**Handoff mic↔gravação (2 estratégias, spike decide):**
- **Estratégia 1 (tap único compartilhado):** um tap alimenta dois consumidores via dois `AVAudioConverter` independentes (16kHz mono p/ detector, formato cheio p/ trilha do vídeo).
- **Estratégia 2 (método do concorrente):** ao gravar, parar o tap da escuta e alimentar o detector com o PCM da própria gravação (fila desacoplada). Menos consumidores simultâneos do mic.

## Máquina de estados

`idle` (modo≠Voz/parado, indicador oculto) · `listening` (tap+detector ativos) · `paused` (interrupção temporária) · `unavailable` (sem permissão/modelo).
- `idle→listening`: modo Voz ON + permissão concedida
- `listening→paused`: interrupção de áudio (ligação/Siri/outro app) → `paused→listening` ao terminar (Coordinator reativa)
- `*→unavailable`: permissão de mic negada/revogada OU modelo não carrega
- **★ gravar NÃO muda o estado** (continua `listening` graças ao mic compartilhado) — elimina a transição "grava→paused" que o SFSpeech era obrigado a fazer
- **Background:** permanece `listening` (sessão persistente + UIBackgroundModes:audio). Indicador laranja de mic do iOS aparece (inescapável, aceitável). App morto no switcher → processo encerra → idle no próximo launch.

## Observable goals (testes verificáveis)

- [ ] Modelo "Raro" carrega do bundle e `WakeWordDetector` inicializa sem erro (unit Swift/XCTest)
- [ ] Falar "Raro gravar" em silêncio dispara `onWakeDetected(.start)` → gravação inicia (device, log os_log subsystem `com.rarocamera/voice`)
- [ ] Falar "Raro parar" durante gravação dispara `onWakeDetected(.stop)` → gravação para
- [ ] Gravando, a escuta permanece `listening` (não vira `paused`) E o vídeo sai com trilha de áudio (ffprobe no .mp4)
- [ ] Interrupção (ligação) → `paused` → retoma `listening` ao terminar
- [ ] Permissão negada → `unavailable` + REC manual segue 100% funcional
- [ ] Detecção com app em background/tela bloqueada (confirmar no log)
- [ ] Contrato Dart inalterado: 312 testes existentes continuam verdes após flip

## Gate de viabilidade (iPhone 12 físico — pré-condição do flip)

Obrigatório ANTES de `_voiceEngineAvailable=true` (ADR-0023). Medido no device, não no Simulator:
- **(a)** detecção de "Raro" > 80% em silêncio (várias vozes/distâncias) + falsos positivos baixos rodando áudio sem a palavra
- **(b)** coexistência voz + gravação sem matar a escuta E vídeo com áudio
- **(c)** tamanho do modelo + lib ONNX aceitável no bundle (.app final)

**Plano B se falhar (a):** treinar melhor o modelo (mais dados/voz feminina) OU reavaliar Porcupine/Sensory com decisão de custo explícita do dono. NÃO ligar a voz sem passar o gate.

Calibração inicial (referência do concorrente): score ~0.45, debounce 2500ms, cooldown inicial 2500ms, RMS gate 0.026/0.012, chunk 20ms.

## Tratamento de erros

Nunca engolir erro (logar via os_log + tratar). Qualquer falha da voz NUNCA derruba câmera/REC manual.
- Permissão negada / modelo não carrega → `unavailable`, REC manual funciona
- ONNX CoreML EP indisponível → fallback automático CoreML→CPU; se nem CPU → `unavailable`
- Interrupção / mic roubado → `paused`, retoma depois
- Falso positivo → threshold + VAD reduzem; toggle idempotente (guard de fase já existe no Dart)

## Refinamentos técnicos (CoreAudio, validados via Context7/WebSearch)

- Cada consumidor do tap precisa do PRÓPRIO `AVAudioConverter` (estado independente, contagem de samples de saída variável; não assumir sincronia entre trilhas)
- Observar `AVAudioEngineConfigurationChange` e religar o engine (auto-desliga em mudança de config) → responsabilidade do `AudioSessionCoordinator`
- Callback do converter: protocolo `.noDataNow`/retornar `nil` para não entrar em loop
- ONNX Runtime via SPM (`from: "1.16.0"`+); `ORTSession` + CoreML EP via `AppendExecutionProvider("CoreML", ...)` (a API legada `OrtSessionOptionsAppendExecutionProvider_CoreML` foi removida na 1.20.0)

## UI / protótipo

- Indicador de escuta sempre-visível quando modo Voz ON (ADR-0022): teal "DIGA "RARO" PARA GRAVAR" (listening), "VOZ PAUSADA" (paused), "ATIVAR VOZ NAS CONFIGURAÇÕES" (unavailable), oculto (idle). Já implementado em `voice_listening_indicator.dart`.
- Beep de confirmação no wake (copiar comportamento do concorrente).
- Wake word = "Raro" (ADR-0009, hard rule em `raro_shared`). Comandos "Raro gravar"/"Raro parar".

## Out of scope

- Versão Android da voz (Sprint 3; o teardown já adianta parâmetros). Esta spec é iOS.
- Reuso do modelo/lib Sensory (proprietário, pago, ilegal).
- Push-to-talk / foreground-only como modo separado (background é o alvo).
- Mudança no contrato Pigeon ou na camada Dart.
- Débito herdado do pré-roll Frente A (gate §10 ffprobe) — tratado em paralelo, não bloqueia esta spec mas deve fechar antes de Frente A 100%.

## Risks

| Risco | Mitigação |
|-------|-----------|
| LiveKit/ONNX não detecta "Raro" em PT-BR com qualidade (>80%) | Gate (a) obrigatório; plano B treino melhor / Porcupine com decisão de custo |
| Bateria do always-listening em background | RMS/VAD gate antes da inferência (ref. concorrente 0.026/0.012); embedding no ANE via CoreML EP; medir Energy Log |
| Tamanho da lib ONNX no bundle (~64MB xcframework full) | Custom/reduced build (operator reduction, só ios-arm64); medir no gate (c) |
| Handoff mic↔gravação com glitch de áudio no iOS | 2 estratégias no design; spike no device decide qual sem glitch |
| Treino do modelo "Raro" (Linux-only, voz PT-BR limitada no Piper) | LiveKit usa VoxCPM (PT-BR); complementar com gravações reais se necessário; medir recall no gate |
| `AVAudioEngineConfigurationChange` derruba o engine silenciosamente | Coordinator observa a notificação e religa |

## ADRs necessários

- [x] ADR-0023 (Accepted) — engine dedicada on-device. Cobre LiveKit/ONNX + background + ONNX Runtime no Runner.
- [ ] `adr-guardian` confirma se integrar ONNX Runtime (dep nativa nova via SPM) precisa só registrar no Blueprint §2 ou ADR adicional.
- [ ] Considerar addendum ao ADR-0023 registrando a evidência Sensory (concorrente usa SDK pago) — justifica documentalmente por que não copiamos a engine.

## Build sequence (alto nível; detalhe no plan)

1. Treinar/obter os modelos "Raro" (LiveKit pipeline, VoxCPM PT-BR + gravações reais se preciso) → `raro_gravar.onnx` + `raro_parar.onnx` (+ estágios genéricos `melspectrogram.onnx`/`embedding_model.onnx` do pacote) — Decisão 5a
2. Integrar ONNX Runtime via SPM no Runner + registrar no Blueprint §2 (confirmar com adr-guardian)
3. `WakeWordDetector` (pipeline ONNX stateful, buffer 16kHz, `WakeScores{start, stop}`) + XCTest de carga dos modelos
4. `AudioSessionCoordinator` (dono da sessão, interrupções, ConfigurationChange) + 1 das 2 estratégias de handoff
5. Reescrever `VoiceManager` (tap → detector → WakeCommand), remover SFSpeech + DBG residual
6. Toque cirúrgico na câmera (não monopolizar mic)
7. **Gate de viabilidade no iPhone 12** (a/b/c) — dono conecta o device
8. Flip `_voiceEngineAvailable=true` só após gate passar; rodar 312 testes
9. Fechar débito Frente A (ffprobe pré-roll) se ainda aberto

## References

- ADRs: 0023 (engine dedicada), 0022 (design de voz, engine superseded), 0009 (wake word "Raro"), 0003 (pré-roll)
- Session: `docs/sessions/0023-s2c-preroll-debts-voice-sfspeech-deadend-openwakeword-decision.md`
- Blueprint §2 (stack — registrar ONNX Runtime)
- Spec relacionada: `docs/superpowers/specs/2026-06-07-voice-trigger-and-preroll-debts-design.md`
- Memórias: `raro-competitor-okcamera-android-apk-teardown`, `raro-competitor-okcamera-replay-model`, `raro-pattern-ios-wake-word-no-native-api`, `raro-pattern-flutter-async-native-state-needs-notifier`, `raro-preroll-rec-design-s2c`
- Context7: `/microsoft/onnxruntime-swift-package-manager` (integração SPM + CoreML EP)
