# 0023 — Engine de voz: wake-word dedicada on-device (NÃO SFSpeechRecognizer)

- **Data:** 2026-06-08
- **Status:** **STANDBY desde 2026-06-21 (sessão 0029) — engine ONNX REPROVADA no device. Ver Atualização 2026-06-21 no topo.** (Histórico: Accepted → CONDICIONAL/BACKGROUND-ONLY desde 2026-06-11.)
- **Relaciona:** **Supersede a escolha de engine do [ADR-0022](0022-voice-on-device-sfspeechrecognizer.md)** (que escolheu SFSpeechRecognizer). Demais decisões do ADR-0022 (modo selecionável, foreground, dois comandos, contrato Pigeon, indicador sempre-visível) permanecem válidas.
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sessão S2.C, validação no iPhone 12 físico (iOS 26.5) + investigação device-validated do app concorrente no iOS.

> ## 🛑 ATUALIZAÇÃO 2026-06-21 (sessão 0029) — engine ONNX REPROVADA no device; ADR em STANDBY
>
> A decisão central deste ADR (migrar o wake-word de background para **livekit-wakeword/ONNX**) foi **executada e reprovada**. Treinaram-se **4 modelos** (gravar / parar / toggle sintético / toggle híbrido com voz real do dono) e **nenhum dispara "Raro" na voz real no iPhone 12** — pico de score 0.128 vs limiar usável; gate offline AUC máx 0.54, melhor "Raro" 0.497 (não cruza 0.5). Causa provada por device: a palavra **"Raro" (2 sílabas, muitas rimas PT-BR: caro/barro/faro/claro/carro)** é o limite do pipeline openWakeWord — não a falta de voz real no treino (o híbrido com voz real piorou/empatou). Detalhes: sessão 0029, `PLANO-MESTRE-finalizacao-entrega-cliente.md`.
>
> **Consequência:** o background do wake-word fica em **STANDBY**. O dono está **negociando licença com a Sensory** (a engine que o concorrente "Ok Câmera" usa — memória `raro-competitor-sensory-voicehub-ios-sdk-gated`) como caminho alternativo para o background. O app entrega hoje **só foreground via SFSpeech (ADR-0022)**. Pipeline ONNX preservado dormente no commit `01a1f67` (não está no caminho de produção; reverter foi o commit `7e9c0c9`). **NÃO reabrir treino ONNX nem `WakeWordDetector.swift` sem um ADR novo** — é um beco já provado (custou ~US$11 + várias sessões). A decisão de produto (foreground-only vs Sensory vs mudar a palavra) está **ABERTA** com o cliente.
>
> ## ⚠️ ATUALIZAÇÃO 2026-06-11 (sessão 0024) — premissa FOREGROUND refutada; escopo deste ADR reduzido a BACKGROUND
>
> A premissa central deste ADR (que o SFSpeechRecognizer é **beco-sem-saída** para wake-word, baseada no sintoma "funciona EXATAMENTE 1×" da seção Contexto abaixo) **foi REFUTADA por log limpo + device na sessão 0024.** O "funciona 1×" NÃO era limitação do endpointer/onset da Apple — era um **bug de arquitetura no nosso código**: reciclar a `recognitionTask` a cada erro benigno `1110` (no-speech). Corrigido sem trocar de engine (token de ciclo + ring buffer, commit `a43421a`); SFSpeech foreground agora **funciona** (8 wake matched no iPhone 12). Memória `raro-pattern-sfspeech-continuous-no-recycle-per-error`.
>
> **Escopo válido deste ADR agora = SÓ background/tela-bloqueada**, onde o SFSpeech realmente NÃO serve (foreground-only por restrição fundamental do iOS — erro 1700 em background; validado em fonte primária Apple). O dono decidiu **manter** este ADR para a feature de background (necessária), implementada com livekit-wakeword/ONNX. **Para foreground, vale o ADR-0022 (SFSpeechRecognizer, validado).** A seção "Contexto" abaixo é mantida como registro histórico do diagnóstico da época (parcialmente refutado).

## Contexto

O ADR-0022 escolheu `SFSpeechRecognizer` (`requiresOnDeviceRecognition=true`) + transcript matching para a wake word "Raro". A implementação (sessão S2.C) **bateu em muro após ~6 fixes nativos**, com diagnóstico fechado por log real do device (capturado via `pymobiledevice3 syslog live`, já que `idevicesyslog` não captura `os_log` de app):

1. **Crash:** `installTapOnBus` lança `NSException` não-capturável pelo `do/catch` do Swift → abort. Mitigado com `ObjCExceptionCatcher` (ObjC `@try/@catch`) + tap com `format: nil`.
2. **Loop `paused↔listening`:** restart loop tratava silêncio/erro como falha.
3. **Causa-raiz final (3 análises adversariais convergiram + Apple docs):** com `requiresOnDeviceRecognition=true`, o endpointer on-device **exige um stream de áudio limpo desde o onset**. A voz funciona EXATAMENTE 1× (1º request, logo após `audioEngine.start()`); todo request subsequente retorna `kAFAssistantErrorDomain 1110 "No speech detected"` instantaneamente, mesmo com áudio fluindo (contador `taps` subindo). Reconstruir engine+tap por ciclo removeu o 1110, mas o handoff gravação→voz ainda deixava a escuta presa.

### Prova de mercado (decisiva)

Investigação device-validated do concorrente **"Ok Câmera" no iOS** (`fmdev.okcamera`, App ID 6758306427) — cujo wake-word FUNCIONA no iPhone — via `pymobiledevice3 apps query` + `syslog live` (2026-06-08):

- **Info.plist dele:** `UIBackgroundModes: ['audio']` + `NSMicrophoneUsageDescription="Precisamos do microfone para detectar a frase de ativação"`, mas **SEM `NSSpeechRecognitionUsageDescription`** → ele **não toca o Speech framework da Apple**.
- **os_log dele em ação:** **ZERO eventos** `localspeechrecognition`/`kAFAssistant`/`SFSpeech`. Usa `AudioToolbox` (457×) + `AudioToolboxCore` + `AudioSession` + `AudioQueue` (mic cru de baixo nível) + `Background entitlement: YES`.
- **Handoff mic↔gravação:** mantém **UMA sessão `PlayAndRecord` ativa permanentemente** (não reconstrói por ciclo) e, ao gravar vídeo, `isUsingBuiltInMicForRecording: NO` / `AudioSessionRecording: NO` — a gravação dele **não toma o mic via `AVAudioSession`**, então voz e gravação coexistem.

**Conclusão:** o concorrente bateu no mesmo muro do `SFSpeechRecognizer` e escolheu uma **engine de wake-word dedicada sobre mic cru**. Continuar no `SFSpeechRecognizer` para wake-word contínuo no iOS é beco-sem-saída comprovado.

## Opções consideradas

1. **OpenWakeWord / LiveKit-wakeword (escolhida).**
   - Licença **Apache 2.0, 100% gratuita, SEM per-MAU** — compatível com o modelo R$ 9,90/mês.
   - On-device via **ONNX Runtime + CoreML Execution Provider** (ANE/GPU/CPU). Wake-word custom "Raro" treinável a partir de TTS sintético (Piper).
   - Arquitetura idêntica à do concorrente (modelo on-device sobre mic cru, sem Speech framework).
   - Contras: exige treinar o modelo "Raro" + integrar ONNX Runtime (mais setup que um SDK pronto); maturidade iOS menor que Porcupine.

2. **Picovoice Porcupine.**
   - SDK iOS maduro, wake-word custom pronta, fácil integração.
   - **Contra fatal:** free tier = **3 usuários ativos/mês** (inútil em produção); pago não-público ("contact sales"), estimado **~US$ 6.000+/ano** — conflita diretamente com R$ 9,90/mês. Foundation tier é só para startups <5 anos/<20 funcionários.

3. **Continuar com SFSpeechRecognizer (status quo ADR-0022).**
   - Descartado: provado inviável para wake-word contínuo (1110-after-first, limite 1 min/sessão, endpointer exige onset limpo). O concorrente não usa por esses motivos.

## Decisão

**Migrar a engine de wake-word para um modelo dedicado on-device, preferencialmente OpenWakeWord/LiveKit-wakeword (Apache 2.0, sem custo per-usuário), via ONNX Runtime + CoreML Execution Provider.** Treinar o modelo custom para "Raro".

Arquitetura de áudio espelhando o concorrente (validado):
- **Uma sessão `AVAudioSession` `.playAndRecord` ativa de forma persistente** (não reconstruir por ciclo).
- A gravação de vídeo (`AVCaptureSession`) **não deve monopolizar o mic via `AVAudioSession`** de forma que mate a escuta — investigar capturar o áudio do vídeo por caminho que coexista (o concorrente faz `isUsingBuiltInMicForRecording: NO`).
- `UIBackgroundModes: audio` + entitlement de background **obrigatórios** (ver seção "Background / tela bloqueada" abaixo — captura com tela bloqueada é requisito, modelando o concorrente).

Mantido do ADR-0022: modo selecionável (Voz/Volume), default Voz ON, dois comandos ("Raro gravar"/"Raro parar"), contrato Pigeon `voice_api` (start/stop/isAvailable + onWakeDetected/onListeningStateChanged — agnóstico de engine, não muda), indicador de escuta sempre-visível.

### Background / tela bloqueada (modelar o concorrente) — SUPERSEDE o "foreground-only" do ADR-0022

O concorrente capta voz com **tela bloqueada e app em background** (observado no device pelo dono; confirmado pelo Info.plist `UIBackgroundModes: ['audio']` + `Background entitlement: YES`). O ADR-0022 assumiu "foreground-only no iOS" — **revogado aqui**. A voz nova deve rodar em background com `UIBackgroundModes: audio` + entitlement de áudio, espelhando o concorrente, para captar "Raro" com a tela bloqueada (caso de uso real: pesca/esporte com o telefone guardado).

**⚠️ RISCO App Store (decisão consciente do dono, aceito):** microfone contínuo em background no iOS é alvo de **revisão manual rigorosa da Apple**. A Apple historicamente rejeita apps que usam `UIBackgroundModes: audio` para escutar o microfone em background sem reproduzir áudio (guideline de uso indevido de background). O concorrente (`fmdev.okcamera`) está publicado fazendo isso — então é **viável** (passou no App Review), mas é um **risco de aprovação** que o RARO assume conscientemente. Mitigações a preparar para o App Review: justificativa clara de uso (captura mãos-livres para o caso de uso declarado), indicador visível de que está escutando (privacidade), e possivelmente tocar um áudio inaudível/keep-alive como o padrão de apps de gravação. Avaliar na submissão.

> **Validação de viabilidade obrigatória antes de comprometer:** prototipar OpenWakeWord/ONNX no iPhone 12 e confirmar (a) detecção de "Raro" >80% em silêncio, (b) coexistência voz+gravação sem matar a escuta, (c) tamanho do modelo aceitável no bundle. Se OpenWakeWord não atingir, reavaliar Porcupine com decisão de custo explícita do dono.

## Consequências

- **Positivas:** sem custo recorrente (compatível com a precificação); arquitetura comprovada pelo concorrente; sem os limites do Speech framework (1 min/sessão, endpointer, 1110-loop); voz+gravação coexistem.
- **Negativas:** treinar modelo custom "Raro" + integrar ONNX Runtime no iOS é mais trabalhoso que um SDK pronto; maturidade iOS do OpenWakeWord a validar; adiciona dependência nativa (ONNX Runtime ~poucos MB).
- **Como reverter:** se OpenWakeWord falhar a validação de viabilidade, Porcupine (com decisão de custo do dono) ou re-escopar voz.

## Implementação (próxima sessão dedicada)

- Treinar modelo "Raro" (OpenWakeWord/LiveKit pipeline — TTS sintético).
- Integrar ONNX Runtime + CoreML EP no `Runner` (nova dep nativa → este ADR cobre).
- Reescrever `VoiceManager.swift`: substituir `SFSpeechRecognizer` pela inferência do modelo sobre buffers do tap (sessão `PlayAndRecord` persistente). O contrato Pigeon `voice_api` e o `VoiceController` Dart **não mudam** (engine-agnósticos).
- Resolver o handoff mic↔gravação (coexistência).
- Remover a instrumentação DBG temporária do `VoiceManager`/`camera_screen`.

## Addendum 2026-06-09 — engine do concorrente identificada (Sensory) via teardown Android

O teardown do APK Android do concorrente (`br.com.okcamera.goldgravar` v71.1, via `adb pull` + `jadx` + `apktool`) identificou a engine de wake-word que o syslog iOS não revelava (FairPlay): **Sensory TrulyNatural 7.5** — lib nativa `libSnsr.so` + modelo `assets/ok_camera.snsr` ("licensed to OK Camera PL"). Isso explica retroativamente o "zero ONNX/CoreML/ANE atribuível ao app" visto no iOS (Sensory é engine proprietária autossuficiente).

**Impacto na decisão (reforça, não muda):** Sensory é SDK comercial pago (sem preço público, contrato enterprise) → mesma categoria de rejeição do Porcupine (conflita com R$ 9,90/mês). Confirma documentalmente por que RARO copia só a **arquitetura de áudio** do concorrente (sessão persistente, gravação que não monopoliza o mic, background audio — provados por log iOS), e usa engine própria **grátis** (LiveKit-wakeword, citada na Decisão como par válido de "OpenWakeWord/LiveKit-wakeword"). OpenWakeWord puro foi enfraquecido como opção (notebook oficial quebrado desde nov/2025 — issue #296; English-only). Detalhe completo: memória `raro-competitor-okcamera-android-apk-teardown`.

## Referências

- [ADR-0022](0022-voice-on-device-sfspeechrecognizer.md) (engine superseded; resto válido), [ADR-0009](0009-wake-word-raro.md) (wake word "Raro")
- Memória `raro-pattern-ios-wake-word-no-native-api` (atualizada 2026-06-08 com a confirmação device + método de inspeção do concorrente via pymobiledevice3)
- Evidência: log device em `/tmp/raro-voz-fix.txt`, `/tmp/okcam-voice.txt`, `/tmp/okcam-rec.txt` (sessão S2.C); Info.plist do concorrente via `pymobiledevice3 apps query fmdev.okcamera`
- OpenWakeWord: https://github.com/dscripka/openWakeWord (Apache 2.0) · LiveKit-wakeword: https://github.com/livekit/livekit-wakeword
- Picovoice pricing: https://picovoice.ai/pricing/ (free tier 3 MAU; pago contact-sales ~$6K+/ano)
