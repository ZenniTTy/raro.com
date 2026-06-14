# 0022 — Voz on-device com SFSpeechRecognizer (modo selecionável, foreground, dois comandos)

- **Data:** 2026-06-08
- **Status:** Accepted
- **Relaciona:** ADR-0009 (wake word "Raro"), ADR-0011 (controle por volume — modo alternativo, Sprint 3), ADR-0003 + Addendum 2026-06-07 (pré-roll embutido no REC), ADR-0020 (pipeline unificado de captura)
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sprint 2 Sessão S2.C — ligar o segundo gatilho do save (voz). O briefing (Seção 5.4), o protótipo (onboarding "Diga Raro", Settings "Controle de Gravação", hint da câmera) e o ADR-0009 exigem acionamento por voz. A feature era greenfield: só existia `VoiceConfig.wakeWord='Raro'` em `raro_shared` e um stub Pigeon (`voicePing`/`voiceReady`). Decisão informada por dump real do app concorrente "Ok Câmera" no Galaxy M54 (2026-06-07/08).

## Contexto

A voz precisa acionar o MESMO save do botão REC (gravação com pré-roll), como camada por cima do botão — não no lugar dele. Três questões de stack/contrato exigem decisão irreversível registrada:

1. **Qual engine de wake word?** Validado por WebSearch + Apple Forums (memória `raro-pattern-ios-wake-word-no-native-api`): nenhuma API Apple suporta wake word custom nativamente; nem `SFSpeechRecognizer` nem `SpeechAnalyzer` (iOS 26+). Limites duros do `SFSpeechRecognizer`: ~1.000 requests/device/hora, teto de ~1 min por sessão (restart obrigatório), modelo on-device pode não estar baixado (`supportsOnDeviceRecognition`).

2. **Dump do concorrente (prova de mercado):** o "Ok Câmera" (`br.com.okcamera.goldgravar`) NÃO usa engine dedicada — zero `.so` de Porcupine/Picovoice/Vosk/Whisper no APK; o único serviço de voz ativo é o do Google (`GsaVoiceInteractionService`, do sistema). Ou seja, o concorrente resolve com a API nativa do Android (`android.speech.SpeechRecognizer`), o paralelo Android do `SFSpeechRecognizer`. Modelo dele: voz é DEFAULT sempre-ligado, com foreground service persistente (notif "Escuta de voz") e diálogo de saída "Manter ouvindo em 2º plano". Esse background-persistente é Android-only.

3. **Modelo de ativação:** o protótipo RARO traz Settings "Controle de Gravação" com modo Voz/Volume **selecionáveis** (toggle), não o voz-default-escondido do concorrente — que o próprio dono do RARO criticou como confuso ("hidden system state").

## Opções consideradas

1. **SFSpeechRecognizer on-device + transcript match (escolhida).**
   - Prós: sem custo recorrente (não conflita com R$ 9,90/mês); sem dependência nova; on-device = privacidade + sem cota de servidor na prática; validado pelo mercado (concorrente usa equivalente nativo).
   - Contras: falso-positivo médio em PT (mitigável exigindo wake + verbo); restart loop obrigatório; sem wake word API real (workaround por transcript matching).

2. **Picovoice Porcupine (engine dedicada paga).**
   - Prós: wake word treinada custom, falso-positivo baixo.
   - Contras: custo recorrente conflita com a precificação; dependência nova exigiria ADR de stack próprio. Reservado para v2.0 SE métricas de produção forem ruins.

3. **WhisperKit on-device (gratuita).**
   - Prós: mais preciso que SFSpeechRecognizer.
   - Contras: modelo ~150MB, latência maior; foi pensado para transcrição completa, não wake word. Overkill para v1.0.

## Decisão

**Engine: `SFSpeechRecognizer` com `requiresOnDeviceRecognition = true`** + transcript matching. Verificar `supportsOnDeviceRecognition` antes de assumir. Picovoice/Whisper ficam como v2.0 atrás de ADR novo, gatilhados só por métricas ruins de produção (detecção <80% em silêncio OU falso-positivo >5%).

**Modelo: selecionável (fiel ao protótipo + ADR-0009), default Voz ON.** Settings "Controle de Gravação" governa: modo Voz ON ativa o listener; modo Volume (Sprint 3, ADR-0011) o desativa. O botão REC sempre funciona como base, independente do modo. NÃO é o voz-default-escondido do concorrente: o indicador de escuta é SEMPRE visível quando Voz ON (consertando o "hidden state").

**Ciclo: restart loop com backoff.** Restart automático antes do teto de ~1 min; backoff exponencial (max 60s) em erro/rate-limit; qualquer falha vira estado `paused` SEMPRE visível na UI — nunca silencioso.

**Foreground-only no iOS.** Background é inviável sem o entitlement `com.apple.developer.avfoundation.multitasking-camera-access` (aprovação manual Apple) + restrições de mic em background. A voz do RARO roda com o app em foreground. (O concorrente faz background no Android; iOS não permite.)

**Dois comandos distintos:** "Raro gravar" (start) e "Raro parar" (stop) — mais explícito que o wake-único do concorrente. Enum de contrato `WakeCommand { start, stop }`. "Raro parar" exige o recognizer ativo DURANTE a gravação, disputando o microfone com o `AVCaptureAudioDeviceInput` da gravação (risco MÉDIO-ALTO de áudio degradado no `.mp4`). **Por padrão, o VoiceManager bloqueia a escuta enquanto a gravação está ativa** (guarda programática `isRecordingActive`), tornando "parar por voz" condicional a um device gate: se o gate provar que escutar durante REC mantém o áudio limpo, a guarda é relaxada e "Raro parar" entra em v1.0; se degradar, "parar por voz" vai para Sprint 3 e v1.0 entrega "Raro gravar" + parar por botão.

**Contrato Pigeon `voice_api` expandido** (substitui o stub):
- `VoiceHostApi` (Dart→Swift): `isAvailable()` (async, autorização speech+mic + on-device), `startListening()`, `stopListening()`.
- `VoiceFlutterApi` (Swift→Dart): `onWakeDetected(WakeCommand)`, `onListeningStateChanged(VoiceListeningState)`.
- `VoiceListeningState { idle, listening, paused, unavailable }`.
- NÃO expõe transcript cru (YAGNI + privacidade) — só o sinal do comando detectado.

## Consequências

- **Positivas:**
  - Zero custo recorrente; sem dependência nova; on-device (privacidade).
  - Modelo selecionável transparente — diferencial sobre o concorrente (escuta visível, não escondida).
  - Fonte única de gravação (`RecordingController.toggle`) chamada por tap E por voz → não divergem.
- **Negativas:**
  - Falso-positivo médio em PT (mitigado: exige wake + verbo, não a palavra solta).
  - Restart loop adiciona complexidade; rate-limit pode pausar a escuta (mas o estado `paused` é visível).
  - "Raro parar" durante REC é incerto até o device gate (conflito de mic).
  - `AVAudioSession` compartilhado entre voz e gravação exige coordenação (guarda `isRecordingActive`).
- **Como reverter:** desabilitar o modo Voz no Settings (UI). Para trocar de engine (Picovoice/Whisper), ADR novo com nova dependência.

## Implementação

- `VoiceConfig.wakeWord = 'Raro'` em `raro_shared` (já existe).
- `ControlMode { voice, volume }` em `raro_shared` (já existe); `RecordingSettings.controlMode` default `voice` (já persistido).
- Native `com.rarocamera/voice`: `VoiceManager.swift` (SFSpeechRecognizer + AVAudioEngine + restart loop + backoff + `VoiceCommandParser` + guarda `isRecordingActive`); `VoiceHostApiImpl.swift`; registro no `AppDelegate`.
- Dart: `features/voice/` (`VoiceState`, `VoiceRepository`, `VoiceController` Notifier reativo `keepAlive`, indicador de escuta sempre-visível).
- `Info.plist`: `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` (já presentes).
- Mic permission: `AVAudioApplication.requestRecordPermission` (iOS 17+) com guard `#available`, fallback `AVAudioSession.requestRecordPermission` (iOS 15/16). Deployment target = iOS 15.0.

## Evolução de design (2026-06-08, validada com o dono)

O protótipo modelou apenas o estado "escutando" (hint estático `DIGA "RARO" PARA GRAVAR` com ícone de câmera de 42px). Como a voz tem estados que o protótipo não previu (pausado, indisponível), o indicador de escuta evoluiu — decisão explícita do dono no design-fidelity gate da S2.C:

- **Ponto de estado em vez do ícone estático.** No modo voz, o `VoiceListeningIndicator` mostra um ponto colorido (teal=escutando, cinza=pausado/indisponível) em vez do ícone de câmera de 42px do protótipo. Justificativa: o ponto comunica o ESTADO da escuta — exatamente o conserto da "escuta escondida" do concorrente que motivou a feature. O ícone estático não comunicaria pausado/indisponível. Divergência consciente do protótipo, com propósito.
- **Copy nova oficial:** `VOZ PAUSADA` (estado paused) e `ATIVAR VOZ NAS CONFIGURAÇÕES` (estado unavailable) — sem contraparte no protótipo (que assumia voz sempre funcional). Cumprem o requisito "estado sempre visível, nunca silencioso". Aprovadas como copy oficial da feature. (Migração para i18n/.arb é backlog do projeto inteiro, não bloqueia.)
- **Fidelidade preservada onde existe:** o estado "escutando" mantém o texto exato do protótipo (`DIGA "RARO" PARA GRAVAR`, aspas curvas, alpha 0.35) e a tela de Settings "Controle de Gravação" bate com o protótipo no card Voz (o card Volume está desabilitado "em breve" — Volume = Sprint 3, ADR-0011).

## Referências

- [Briefing Seção 5.4](../briefing/original-briefing.md)
- [Blueprint Seção 1 — Divergência #1](../Blueprint.md)
- [Protótipo HTML](../briefing/prototype/Prototipo-RARO.html) (onboarding voz, Settings, hint)
- ADRs: [0009](0009-wake-word-raro.md), [0011](0011-volume-control-not-bluetooth.md), [0003](0003-replay-buffer-native.md)
- Memórias: `raro-pattern-ios-wake-word-no-native-api`, `raro-competitor-okcamera-replay-model`, `raro-pattern-flutter-async-native-state-needs-notifier`
- Spec: [docs/superpowers/specs/2026-06-07-voice-trigger-and-preroll-debts-design.md](../superpowers/specs/2026-06-07-voice-trigger-and-preroll-debts-design.md)
