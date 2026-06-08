# 0023 — S2.C: débitos do pré-roll fechados + voz (SFSpeechRecognizer = beco-sem-saída no device) → decisão de migrar p/ OpenWakeWord

- **Data:** 2026-06-08 (atravessou 2026-06-07 noite)
- **Duração:** sessão muito longa (várias compactações), com extenso ciclo de device debug
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `2f6bea2`, `e1c5bc3`, `148c09a`, `18510ad`, `efc4349`, `50b4704`, `c04a822`, `43bbb62`, `d70a327`, `180652a`, `68b2da6`, `2d9929d`, `873d2aa`, `df699a4`, `55b5c0f`, `9d19e90`, `61b131d`, `d5985fe`, `019def2`, `9169526`, `acbafa5`, `ea0c40d`, `90fd123`, `0deba3c`, `5c6934c` (25 commits)

## Objetivo

Sprint 2 Sessão S2.C, duas frentes declaradas upfront: **(A)** limpar os 3 débitos do pré-roll combinado (nome cosmético, áudio-priming AAC, DTS não-monotônico nas emendas); **(B)** entregar a feature de voz — "Raro gravar"/"Raro parar" acionando o mesmo save do botão REC, como camada por cima (não no lugar).

## Contexto inicial

Pré-roll embutido no REC fechado e device-validated na 0022 (gate §10 ffprobe passou no iPhone 12). Voz era greenfield (só `VoiceConfig.wakeWord='Raro'` + stub Pigeon). Investigação de produto guiada por **dump real do app concorrente "Ok Câmera"** no Galaxy M54 (Android) no início da sessão: confirmou modelo de voz selecionável + engine nativa sem lib paga + background persistente (Android-only, achava-se).

## O que foi feito

### Fase de planejamento (brainstorming → spec → plan → verificação adversarial)
- **Spec** (`2f6bea2`) + **plan** (`e1c5bc3`) S2.C via skills superpowers. Decisões travadas com o dono: modo selecionável (fiel ao protótipo), engine SFSpeechRecognizer on-device, toggle extraído pro RecordingController (fonte única), default Voz ON, volume = Sprint 3, dois comandos, mic-gate = device decide.
- **Verificação adversarial do plano** (workflow 4 agentes) achou **6 blockers** corrigidos ANTES de codar (`148c09a`): enum Pigeon sem sufixo, `AVAudioApplication` iOS17+ precisa guard `#available` (target é iOS 15), tap idempotente, guarda programática de mic, Riverpod async-em-build via `ref.listen`, keepAlive nos controllers, honestidade sobre passthrough-DTS. **Pagou-se: a implementação rodou limpa.**

### Frente A — débitos do pré-roll (PRONTA, código)
- **A1** (`18510ad`): combinado salva como `raro_<uuid>.mp4` (sem infixo `replay_`) + teste Dart `idFromPathForTest`.
- **A2** (`efc4349` + `50b4704`): IDR por chunk via AMBAS keyframe keys (`AVVideoMaxKeyFrameIntervalKey` + `...DurationKey`); `replayFps` ligado ao `config.fps` real (corrige frame-count em 30fps). XCTest `ReplayExportSettingsTests` PROVADO rodando (suite started + assert, não só exit 0).
- **A3** (`c04a822`): retiming da composition ancorado na trilha de VÍDEO + áudio clampado → DTS monotônico + alinha áudio. Honesto: passthrough não reescreve DTS → gate §10 ffprobe decide (fallback re-encode documentado).

### Frente B — voz com SFSpeechRecognizer (IMPLEMENTADA, mas provou ser beco-sem-saída no device)
- B0 ADR-0022 (`43bbb62`, adr-guardian GO) + addendum design (`61b131d`); B1 contrato Pigeon `voice_api` (`d70a327`); B2 domain `VoiceState`+`VoiceRepository` (`180652a`); B4 `RecordingController.toggle` fonte única (`68b2da6`, 114 testes); B3 `VoiceManager.swift` SFSpeechRecognizer nativo (`2d9929d`, 24 XCTests, pegou bug latente: `VoiceApi.g.swift` não estava no target Xcode); B5 `VoiceController` reativo (`873d2aa`); B6 indicador de escuta (`df699a4`, 310 testes); B7 Volume desabilitado "em breve" (`55b5c0f`); fix design-fidelity alpha 0.35 (`9d19e90`).

### Ciclo de device debug (o coração desta sessão)
Validação no iPhone 12 físico revelou bugs em cascata que SÓ aparecem no device (testes não pegam voz/áudio nativo). Sequência de fixes guiados por **log real** (não chute):
1. `d5985fe`: crash `installTapOnBus` NSException não-capturável por Swift do/catch → ObjCExceptionCatcher (ObjC @try/@catch) + format nil + `.default` mode. **Crash sumiu.**
2. `019def2`: refator pra "manter engine vivo entre ciclos" (validado contra fontes) → corrigiu o loop `pausado↔escutando`. **MAS estava errado pro on-device (ver aprendizados).**
3. `9169526`: separa pausa-por-gravação (resume rápido) de pausa-por-erro (backoff) → corrige inflação de backoff.
4. `acbafa5`/`ea0c40d`/`90fd123`: instrumentação DBG + debounce do 1110 + reconstruir engine+tap por ciclo.

### Investigação device do concorrente iOS (destravou a decisão)
Com o dono observando que o concorrente capta voz com **tela bloqueada/background** no iOS, investiguei o app dele (`fmdev.okcamera`) via **`pymobiledevice3`** (instalado nesta sessão — `idevicesyslog` NÃO captura os_log de app; pymobiledevice3 captura o unified log em iOS 26 sem tunnel). Achados device-validated: Info.plist `UIBackgroundModes:['audio']` + SEM `NSSpeechRecognitionUsageDescription`; os_log dele ZERO eventos Speech-framework, usa AudioToolbox/AudioQueue (mic cru) + `Background entitlement:YES`; mantém UMA sessão PlayAndRecord persistente + gravação não toma o mic (`isUsingBuiltInMicForRecording:NO`). **Prova de mercado: o concorrente NÃO usa SFSpeechRecognizer.**

### Decisão de stack (ADR-0023, `0deba3c`, adr-guardian GO)
**Migrar engine de voz para wake-word dedicada on-device — OpenWakeWord/LiveKit-wakeword (Apache 2.0, grátis, sem custo per-usuário) via ONNX Runtime + CoreML EP.** Pesquisa de custo: Picovoice Porcupine free tier = 3 MAU (inútil), pago ~US$6K+/ano (conflita R$9,90/mês). Background audio incluído (modela o concorrente, com nota de risco App Store, aceito pelo dono). Supersede só a escolha de engine do ADR-0022; resto (modo, comandos, contrato Pigeon engine-agnóstico, indicador) permanece.

### Estado seguro (`5c6934c`)
Voz com SFSpeechRecognizer parqueada: `VoiceController` gated off (`_voiceEngineAvailable=false` → sempre `VoiceIdle`), indicador auto-escondido (VoiceIdle=shrink), DBG removido do VoiceManager+camera_screen. REC normal. 312 testes verdes, analyze 0.

## O que NÃO foi feito (e por quê)

- **Gate §10 formal da Frente A (ffprobe do combinado pós-A2/A3):** rebuilds foram feitos no device, mas o `ffprobe` formal provando DTS monotônico + áudio em ~0s no `vault/<id>.mp4` **não foi rodado isoladamente** (a sessão foi consumida pelo debug da voz). **Débito:** validar antes de declarar a Frente A 100% fechada. Comandos no ADR-0023/plan.
- **Voz FUNCIONAL:** NÃO entregue. SFSpeechRecognizer provou ser beco-sem-saída no iOS para wake-word contínuo (ver aprendizados). Voz parqueada em estado seguro; engine nova (OpenWakeWord) é a próxima sessão dedicada.
- **Volume control:** Sprint 3 (card desabilitado).
- **Merge → develop:** segurado (PR #2 draft).

## Aprendizados / surpresas

- **SFSpeechRecognizer é beco-sem-saída para wake-word contínuo no iOS (device-validated + prova de mercado).** Com `requiresOnDeviceRecognition=true`, o endpointer on-device exige stream LIMPO desde o onset; reusar tap entre requests → `kAFAssistantErrorDomain 1110` em todo request após o 1º (funciona EXATAMENTE 1×). O concorrente (que funciona no iOS) NÃO usa Speech framework — usa engine dedicada sobre mic cru. Eu bati no mesmo muro que fez ELE escolher outra engine. Memória `raro-pattern-ios-wake-word-no-native-api` atualizada com tudo.
- **`idevicesyslog` NÃO captura os_log de app; `pymobiledevice3 syslog live` SIM (iOS 26, sem tunnel).** Investir na ferramenta certa de captura autônoma destravou o diagnóstico — cada chute custava ~1 rebuild de 5-17min; o log real fechou a causa em minutos. Reforça `feedback_device_debug_use_real_logs_not_assumptions`.
- **Inspecionar app concorrente no iOS é possível e valioso:** `pymobiledevice3 apps query <bundleid>` (Info.plist revela engine via usage descriptions + background modes) + `syslog live` (frameworks que ele usa). devicectl NÃO lista apps da App Store. Não dá pull do .app (sandbox), mas Info.plist + os_log já provam a arquitetura.
- **6 fixes nativos no mesmo componente = sinal de arquitetura errada (systematic-debugging §4.5), não bug.** O dono cortou o ciclo de chutes pedindo log real → investigação do concorrente → decisão de engine. Lição: quando empaca, parar de consertar e questionar a ferramenta.
- **Verificação adversarial do plano (6 blockers) e do ADR (adr-guardian GO) pagaram-se** — a Frente A e o esqueleto da voz rodaram limpos; os problemas foram todos no runtime nativo que nenhuma análise estática pega.

## Próximos passos

- **Próxima sessão (voz robusta):** implementar OpenWakeWord (ADR-0023) — treinar modelo "Raro" (TTS sintético), integrar ONNX Runtime + CoreML EP no Runner, reescrever `VoiceManager.swift` (contrato Pigeon + VoiceController Dart NÃO mudam, engine-agnósticos), sessão PlayAndRecord persistente, resolver handoff mic↔gravação (coexistência como o concorrente), background audio + entitlement. Gate de viabilidade: detecção "Raro" >80%, coexistência voz+REC, tamanho do modelo. Flip `_voiceEngineAvailable=true`.
- **Gate §10 ffprobe da Frente A:** rodar a prova formal do combinado pós-A2/A3 no iPhone 12 (DTS monotônico + áudio ~0s).
- **Backlog Sprint 2:** volume button, RevenueCat sandbox, share, analytics. Android nativo do replay = Sprint 3.

## Referências

- **ADRs:** ADR-0022 (voz SFSpeechRecognizer — engine superseded), **ADR-0023 (engine dedicada OpenWakeWord + background — NOVO)**.
- **Specs/plans:** `docs/superpowers/specs/2026-06-07-voice-trigger-and-preroll-debts-design.md`, `docs/superpowers/plans/2026-06-07-voice-trigger-and-preroll-debts.md`.
- **Memórias atualizadas:** `raro-pattern-ios-wake-word-no-native-api` (confirmação device + método pymobiledevice3 de inspeção do concorrente), `raro-competitor-okcamera-replay-model` (seção de voz, dump Android).
- **Arquivos nativos:** `VoiceManager.swift`, `VoiceHostApiImpl.swift`, `ObjCExceptionCatcher.h/.m`, `ReplayBuffer.swift`, `RecordingPipeline.swift`, `CameraManager.swift`, `AppDelegate.swift`.
- **Arquivos Dart:** `features/voice/*`, `recording_controller.dart`, `camera_screen.dart`, `control_mode_card.dart`, `settings_screen.dart`.
- **PRs:** nenhum novo (PR #2 segue draft).
