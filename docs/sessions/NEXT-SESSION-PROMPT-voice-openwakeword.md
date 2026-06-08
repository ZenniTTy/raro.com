# Prompt — Próxima sessão: voz robusta com OpenWakeWord (S2.D)

> Cole o bloco abaixo como primeira mensagem da nova sessão. Ele já carrega o contexto canônico e as travas. Não é para ser lido como doc — é o prompt.

---

Sessão S2.D — **implementar a feature de voz funcional** migrando do SFSpeechRecognizer (beco-sem-saída comprovado) para **OpenWakeWord on-device**, conforme **ADR-0023 (Accepted)**.

**Comece por `/prime`** e leia, nesta ordem, antes de tocar qualquer código:
1. `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md` — a decisão de engine (autoritativa).
2. `docs/decisions/0022-voice-on-device-sfspeechrecognizer.md` — só engine foi superseded; **modo selecionável, dois comandos, contrato Pigeon engine-agnóstico e indicador sempre-visível permanecem válidos.**
3. `docs/sessions/0023-s2c-preroll-debts-voice-sfspeech-deadend-openwakeword-decision.md` — o que foi tentado, por que falhou, prova de mercado do concorrente.
4. Memória `raro-pattern-ios-wake-word-no-native-api` (método pymobiledevice3 de captura de log + inspeção do concorrente) e `raro-competitor-okcamera-replay-model`.

**Invariantes travados (não negociar):** wake word = `"Raro"` (ADR-0009, NUNCA "OkCamera"); comandos = `"Raro gravar"` / `"Raro parar"`; o **contrato Pigeon `apps/mobile/pigeons/voice_api.dart` e o `VoiceController` Dart NÃO mudam** (engine-agnósticos) — só `VoiceManager.swift` é reescrito.

**Estado de partida (já no branch `feat/camera-native-bridge`):** voz parqueada em estado seguro — `voice_controller.dart:12` tem `const bool _voiceEngineAvailable = false;` que força `VoiceIdle`. O esqueleto Dart (domain/repo/controller/indicador), o `RecordingController.toggle` (fonte única) e o contrato Pigeon estão prontos e testados (312 testes verdes).

**Arquitetura-alvo (modela o concorrente, device-validated):**
- **Uma `AVAudioSession .playAndRecord` ativa de forma persistente** (não reconstruir engine+tap por ciclo — esse era o erro do SFSpeech).
- Inferência OpenWakeWord via **ONNX Runtime + CoreML Execution Provider** sobre os buffers do tap.
- Gravação de vídeo **não pode monopolizar o mic** a ponto de matar a escuta (concorrente faz `isUsingBuiltInMicForRecording: NO`) — resolver o handoff mic↔gravação.
- `UIBackgroundModes: audio` + entitlement de background para captar com tela bloqueada (**risco App Store aceito pelo dono** — ver ADR-0023; preparar justificativa + indicador visível de escuta).

**Tarefas (use brainstorming → writing-plans → subagent-driven, com ADR já existente):**
1. Treinar/obter o modelo "Raro" (OpenWakeWord/LiveKit pipeline, TTS sintético Piper).
2. Integrar ONNX Runtime + CoreML EP no `Runner` (dep nativa nova — coberta pelo ADR-0023; confirmar com adr-guardian que não precisa ADR adicional, só registrar no Blueprint §2).
3. Reescrever `VoiceManager.swift`: substituir SFSpeechRecognizer pela inferência do modelo; sessão `PlayAndRecord` persistente; resolver handoff mic↔gravação.
4. **Gate de viabilidade obrigatório (ADR-0023):** no iPhone 12 físico provar (a) detecção de "Raro" >80% em silêncio, (b) coexistência voz+gravação sem matar a escuta, (c) tamanho do modelo aceitável no bundle. Se não atingir → reavaliar Porcupine com decisão de custo explícita do dono.
5. Flipar `_voiceEngineAvailable = true` só depois do gate passar.

**Regras do harness (sempre):** ordem ADR→TDD→implementer+validação independente→gates por task; Conventional Commits, NUNCA `--no-verify`; build/test iOS **terminal-first** (CLAUDE.md §13, com os 2 git overrides do SPM no sandbox); captura de log no device via `pymobiledevice3 syslog live` (idevicesyslog NÃO pega os_log de app). Quando chegar na etapa de iPhone 12 conectado, **avise o dono** que ele conecta.

**Débito herdado a fechar nesta sessão (ou registrar de novo):** gate §10 ffprobe formal da Frente A (pré-roll combinado pós-A2/A3) — provar DTS monotônico + áudio em ~0s no `vault/<id>.mp4` no iPhone 12. Comandos no ADR-0023/plan e no CLAUDE.md §10.

Confronte ambiguidade antes de agir. Stress-test propostas. Não infira.
