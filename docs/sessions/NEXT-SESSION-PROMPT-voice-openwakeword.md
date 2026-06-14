# Prompt — Próxima sessão: integração iOS do wake-word ONNX (S2.D parte 2)

> **ATUALIZADO na sessão 0025 (2026-06-13).** Os 2 modelos ONNX JÁ FORAM TREINADOS e passaram o gate (~92%) — ver `docs/superpowers/notebooks/modelos-treinados/` (com README de proveniência) + sessão 0025. O treino NÃO é mais o próximo passo; a **integração iOS** é.

## ESTADO REAL (0025): modelos prontos, falta a peça nativa

- ✅ **`raro_gravar.onnx` (recall 91,4%, FP-h 0,18, limiar ótimo 0,34)** + **`raro_parar.onnx` (92,2%, FP-h 0,18, limiar ótimo 0,23)** em `docs/superpowers/notebooks/modelos-treinados/`. São de PROVA (n_samples=2000) — suficientes p/ 1ª validação no device; lote cheio é Plano B se reprovar. **Usar o limiar ótimo de cada `*_eval.json`, não o 0.5 default.**
- ✅ **onnxruntime já no projeto** (SPM). **`AudioSessionCoordinator.swift` existe** (mic 16kHz, provado sobreviver à tela bloqueada na 0024).
- ❌ **`WakeWordDetector.swift` NÃO existe** — é o trabalho desta sessão.

## Tarefa: `WakeWordDetector.swift` (brainstorm → plano → TDD)

Pipeline: carregar `.onnx` → `AudioSessionCoordinator` (mic 16kHz mono) → mel em CPU/XNNPACK + classifier em CoreML EP (`appendCoreMLExecutionProviderWithOptions:`) → ring-buffer de features → limiar ótimo → disparar gravar/parar. **Gate:** detecção "Raro" >80% no iPhone 12 físico + coexistência voz↔gravação. Reprovou → Plano B (lote cheio 15000 / +voice_design_prompts 50-100), NÃO Picovoice.

---
## (Contexto histórico — voz BACKGROUND/foreground SFSpeech, mantido abaixo)

Sessão S2.D — **implementar a voz em BACKGROUND** (tela bloqueada) com detector próprio on-device (livekit-wakeword/ONNX). **A voz FOREGROUND (app aberto) já está pronta e funcionando — NÃO refazer.**

**Comece por `/prime`** e leia, nesta ordem, antes de tocar qualquer código:
1. `docs/sessions/0024-s2c-voice-sfspeech-works-recycle-fix-deadend-refuted.md` — o estado real: SFSpeech foreground FUNCIONA (o "beco-sem-saída" da 0023 foi REFUTADO; era bug de reciclo nosso). Crux de background PROVADO no device.
2. `docs/superpowers/notes/voice-background-crux-proof-iphone12.md` — prova de que o mic-próprio sobrevive à tela bloqueada (fundação do background).
3. `docs/superpowers/plans/2026-06-09-voice-wakeword-livekit-onnx.md` — **ler o bloco "⚠️ VALIDAÇÕES E CORREÇÕES (sessão 0024)" no topo: ele supersede detalhes inline desatualizados.**
4. Memórias `raro-pattern-sfspeech-continuous-no-recycle-per-error`, `raro-pattern-ios-wake-word-no-native-api` (seção BACKGROUND), `raro-pattern-wakeword-train-cpu-piper-no-colab` (corrigida: GPU Linux, não Mac).

**Estado real de partida (branch `feat/camera-native-bridge`, tudo pushado):**
- **Foreground SFSpeech: LIGADO e validado** — `voice_controller.dart:12` tem `_voiceEngineAvailable = true`. "Raro gravar"/"Raro parar" funcionam com o app aberto (8 wake matched no device, reciclo 521→7). **NÃO mexer no foreground sem motivo.**
- **`AudioSessionCoordinator` (mic-próprio 16kHz) já commitado (37c863c) e PROVADO** mantendo o app vivo com tela bloqueada. ONNX Runtime já integrado (SPM, 1.24.2).
- **⚠️ O app instalado no iPhone 12 está com a sonda de teste (voz off) — REBUILDAR antes de testar:** `flutter build ios --profile` + `xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app` (confirmar `App installed:` + container novo ANTES de pedir teste — gate §10).

**Invariantes travados:** wake word `"Raro"` (ADR-0009); comandos `"Raro gravar"`/`"Raro parar"`; contrato Pigeon `voice_api.dart` + `VoiceController` Dart NÃO mudam (engine-agnósticos).

**Fatos validados em fonte primária (0024) — usar, não re-descobrir:**
- SFSpeech é **foreground-only** (erro 1700 em background, restrição fundamental iOS) → background EXIGE detector próprio. Câmera não roda em background → mic deve ser desacoplado da câmera (o Coordinator já é).
- onnxruntime **1.24.2**; **CoreML EP existe**: `ORTIsCoreMLExecutionProviderAvailable()` + `appendCoreMLExecutionProviderWithOptions:` (o `appendCoreMLExecutionProvider(with:)` NÃO existe). O **melspectrogram roda em CPU/XNNPACK** no iOS (incompatibilidade de operadores), só o classifier no CoreML.
- Ferramenta = **`livekit-wakeword` 0.2.1** (melhor que openWakeWord: 100× menos FP/h). **PT-BR EXIGE VoxCPM** (Piper é english-only) → GPU CUDA: Kaggle T4 (grátis, lento) ou RunPod/Vast 4090 (~US$1-4), NÃO Mac. Acurácia multilíngue menor → `voice_design_prompts` 50-100. **Kit turnkey pronto em `docs/superpowers/notebooks/`** (2 configs + `train-raro.sh` + runbook).
- **NÃO remover `NSSpeechRecognitionUsageDescription`** do Info.plist enquanto o SFSpeech foreground existir (a Task 6 Step 2 do plano manda remover — só quando o ONNX superseder DE FATO o foreground).
- **Picovoice recusado** pelo dono (custom keyword = Enterprise ~US$6k/ano).

**Tarefas (brainstorming → writing-plans → subagent-driven; ADR-0023 já existe, premissa foreground refutada mas background continua válido):**
1. Treinar o modelo "Raro" (livekit-wakeword, GPU Linux alugada): `raro_gravar.onnx` + `raro_parar.onnx` + mel/embedding compartilhados.
2. `WakeWordDetector.swift` (pipeline ONNX, stateful ring-buffer de embeddings) — corrigir a API CoreML conforme acima.
3. Ligar `AudioSessionCoordinator` → `WakeWordDetector` → `VoiceManager` (orquestrador), mantendo o foreground SFSpeech ou substituindo-o pelo ONNX (que cobre foreground+background) — decidir no gate.
4. **Gate de viabilidade no iPhone 12 (ADR-0023):** detecção "Raro" >80% + FP baixo + coexistência voz+gravação. Se reprovar → plano B (mais dados / frase distinta), NÃO Picovoice.

**Regras do harness (sempre, reforçadas pela auditoria da 0024):** ordem ADR→TDD→implementer+validação independente; **rodar a SUÍTE COMPLETA (`bun run --filter '@raro/mobile' test`) APÓS CADA commit** (não batched — a 0024 deixou 2 bugs latentes que só o pre-push pegou); **confirmar install no device ANTES de pedir teste**; build/test iOS terminal-first (CLAUDE.md §13, 2 git overrides SPM); log no device via `pymobiledevice3 syslog live --match Runner`; Conventional Commits, NUNCA `--no-verify`. Quando chegar no iPhone 12, **avise o dono** que ele conecta.

**Débito herdado:** gate §10 ffprobe da Frente A (pré-roll combinado pós-A2/A3) — provar DTS monotônico + áudio ~0s no `vault/<id>.mp4`.

Confronte ambiguidade antes de agir. Stress-test propostas. Não infira.
