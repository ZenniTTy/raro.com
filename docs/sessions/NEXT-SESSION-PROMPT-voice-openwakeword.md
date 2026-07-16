# Prompt — Próxima sessão: integração iOS do wake-word ONNX (S2.D parte 2)

> # 🛑🛑 OBSOLETO — NÃO EXECUTAR (sessão 0029, 2026-06-21) 🛑🛑
> Este prompt manda escrever/integrar o **`WakeWordDetector.swift` ONNX**. Isso JÁ FOI FEITO (sessões 0027-0029) e **REPROVADO no device**: 4 modelos treinados, nenhum dispara "Raro" na voz real (pico 0.128). O caminho ONNX/openWakeWord para a palavra "Raro" é um **beco já provado** (custou ~US$11 + várias sessões). O app foi **revertido para SFSpeech foreground** (commit `7e9c0c9`). Background = **standby Sensory**.
>
> **Seguir este prompt = reabrir o beco-sem-saída.** O roadmap vigente é `docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md`. Pipeline ONNX preservado dormente em `01a1f67`. Ver ADR-0023 (Atualização 2026-06-21) e session log 0029. **Mantido só como histórico.**
>
> ---
>
> **ATUALIZADO na sessão 0026 (2026-06-14) [histórico]:** Os 4 modelos ONNX (pipeline de 3 estágios) JÁ ESTÃO versionados em `apps/mobile/ios/Runner/Resources/`, com contrato de I/O VALIDADO por inspeção direta dos `.onnx`. O treino e a obtenção dos modelos NÃO são mais o próximo passo; escrever o **`WakeWordDetector.swift`** é. **A Sprint 2 inteira foi mergeada em `develop` (PR #2); a branch `feat/camera-native-bridge` segue viva e idêntica à develop — continue nela.**

## ESTADO REAL (0026): modelos bundlados + contrato provado, falta a peça nativa

- ✅ **O wake-word é um PIPELINE DE 3 ESTÁGIOS ONNX em cadeia (NÃO 1 arquivo):** `melspectrogram.onnx` → `embedding_model.onnx` → `<classifier>.onnx`. Os 2 `.onnx` treinados na 0025 são **só o classifier** (estágio 3). A 0026 obteve os 2 feature-extractors genéricos que faltavam (do pacote `livekit-wakeword==0.2.1`, mesma versão do treino) — sem eles o detector não vai de áudio→embeddings.
- ✅ **Os 4 `.onnx` estão em `apps/mobile/ios/Runner/Resources/`** (versionados, ~2,6 MB): `melspectrogram.onnx`, `embedding_model.onnx`, `raro_gravar.onnx`, `raro_parar.onnx`. (Os de `docs/superpowers/notebooks/modelos-treinados/` são as cópias-fonte dos classifiers; usar os de `Resources/`.)
- ✅ **CONTRATO DE I/O VALIDADO** em `docs/superpowers/notes/raro-model-training.md` (seção "Contrato de I/O") — shapes/nomes/dtypes/opsets reais + sha256 de proveniência + algoritmo de streaming. **LER DAQUI, não inventar shapes.** Cadeia: áudio`[1,N]` → mel`[T,1,?,32]` (32 bins) → embedding`[?,1,1,96]` (janela 76×32, step 8) → classifier`[1,16,96]` → `score[1,1]`. Limiares ótimos: **gravar 0,34 / parar 0,23** (não 0.5). Memória `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`.
- ✅ **onnxruntime já no projeto** (SPM, 1.24.2). **`AudioSessionCoordinator.swift` existe** (mic 16kHz, provado sobreviver à tela bloqueada na 0024).
- ❌ **`WakeWordDetector.swift` NÃO existe** — é o trabalho desta sessão.
- ⚠️ **DÉBITO ABERTO (não esquecer):** os 4 `.onnx` estão no git mas **NÃO no `project.pbxproj`** (projeto não é file-system-synchronized) → ainda **não entram no bundle**; `Bundle.main.url(forResource:)` retorna `nil` até inseri-los. Fazer as inserções no pbxproj NO MESMO toque do detector (PBXFileReference + PBXBuildFile + Copy Bundle Resources `97C146EC...`) + smoke-test `Bundle.main` no device. Ver memória `raro-pattern-ios-xctest-pbxproj-4-insertions`.

## Tarefa: `WakeWordDetector.swift` (brainstorm → plano → TDD)

Pipeline **STATEFUL de 3 sessões ONNX**: `AudioSessionCoordinator` (mic 16kHz mono, 1280 samples/80ms) → **melspectrogram** (CPU/XNNPACK — operadores incompatíveis com CoreML) → ring-buffer de mel frames (≥76) → **embedding_model** (janela 76×32, step 8) → ring-buffer de embeddings (≥16) → **2 classifiers** gravar+parar (CoreML EP, `appendCoreMLExecutionProviderWithOptions:`) compartilhando mel+embedding → limiar ótimo por classe → disparar gravar/parar. **Gate:** detecção "Raro" >80% no iPhone 12 físico + coexistência voz↔gravação. Reprovou → Plano B (lote cheio 15000 / +voice_design_prompts 50-100), NÃO Picovoice.

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
