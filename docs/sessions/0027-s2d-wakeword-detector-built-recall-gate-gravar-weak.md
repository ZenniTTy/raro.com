# 0027 — S2.D parte 2: WakeWordDetector.swift construído (Tasks 0-6) + gate de recall offline → raro_gravar fraco (re-treino com hard negatives)

- **Data:** 2026-06-15 → 2026-06-18
- **Duração:** ~longa (multi-dia, com pausas; computador travou 1×)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** `5ca45e6`, `00f8a31`, `39b1d9c`, `3fd36ae`, `7bff33e`, `586d4d8`, `3e59951`, `eca45c6`, `cedb926`, `0132cfc`, `6c6ac71`

## Objetivo

Implementar `WakeWordDetector.swift` (S2.D parte 2 real): o pipeline ONNX de 3 estágios que transforma áudio do mic em `WakeCommand`, seguindo brainstorm → spec → plano TDD → subagent-driven, e rodar o gate de aceite (ADR-0023: detecção "Raro" >80% no iPhone 12).

## Contexto inicial

Entrada (0026): 4 modelos ONNX no disco+git (2 classifiers RunPod ~92% + 2 feature-extractors do pacote pip), contrato de I/O validado, `AudioSessionCoordinator` provado, `WakeWordDetector` inexistente. Débito aberto: os 4 `.onnx` fora do `project.pbxproj`.

## O que foi feito

**Detector ONNX completo (Tasks 0-6), TDD subagent-driven, validado no iPhone 12 físico:**

- **Task 0 (gate de entrada):** re-validei os shapes dos 4 grafos com `pip install onnx` (não confiei na 0026) — batem com o contrato. adr-guardian: GO (ADR-0023 cobre ONNX no Runner; Blueprint §2 já registra; sem ADR novo).
- **Tasks 1-3 — `WakeWordPipeline.swift`** (máquina de estados pura, protocolos `MelExtracting`/`Embedding`/`Classifying`, testável sem ONNX): acúmulo de áudio→mel @1280 samples (`00f8a31`+`39b1d9c`); janela deslizante mel→embedding 76×32 step 8 (`3fd36ae`); thresholds 0.34/0.23 + debounce + bound do `embeddingBuffer` a 16 (`7bff33e`). **9 testes verdes no iPhone 12.**
- **Bug de debounce pego por cross-check com o dump Ok Camera** (`586d4d8`): o valor inicial `25` ("~2s") estava errado; o teardown prova 2500ms; 2500/125ms = **20 embeddings**. Corrigido com trace matemático + 2 testes de fronteira (19 bloqueia / 20 libera).
- **Task 4 — 4 `.onnx` no pbxproj** (`3e59951`): fechou o débito silencioso da 0026. **Verificado por mim:** `find Runner.app -name "*.onnx"` = 4/4 no bundle do device.
- **Task 5 — `OnnxModelSession.swift`** (`eca45c6`): wrapper fino do ORT, `ORTEnv` singleton, EP por modelo. **3 assinaturas corrigidas contra a API real 1.24.2** (módulo `OnnxRuntimeBindings` não `onnxruntime`; `appendCoreMLExecutionProvider(with:)`; `outputNames: Set`). Descobriu+corrigiu que o onnxruntime SPM estava declarado mas **não linkado** no Frameworks phase. **2 testes verdes no iPhone 12** (4 modelos carregam + inferência real → score finito).
- **Task 6 — `WakeWordDetector.swift`** (`cedb926`+`0132cfc`): fachada com 3 adapters (mel normaliza x/10+2; classifier com guard `isFinite`/empty → return 0). os_log nos adapters mel/embedding (anti silent-failure, recomendação de review). **2 testes verdes no iPhone 12.**

**Gate de recall offline (a peça decisiva, `6c6ac71`):**

- Construí `WakeWordRecallTests.swift` que decodifica WAVs reais (AVAudioFile+AVAudioConverter, fiel ao `AudioSessionCoordinator`) e alimenta no `detector.process()` — **sem tocar o mic**. 8 fixtures gravadas pelo dono (4 "Raro gravar" + 4 "Raro parar"), rotuladas e validadas por audição.
- **Resultado no iPhone 12:** `parar 3/4` ✅ (scores 0.50-0.73), `gravar 0/4` ❌ (máx 0.213, precisa 0.34). **O pipeline ONNX FUNCIONA; o problema é específico do modelo `raro_gravar`.**

**Diagnóstico completo (workflow adversarial + scores brutos no device):**

- Instrumentei `onScoresForTesting` + A/B `classifierProvider` (CoreML vs CPU). **CoreML ≈ CPU** (0.213 vs 0.211) → fp16 descartado.
- **Experimento mel A/B offline (Python, $0):** mel-1280 (Swift) vs mel-1760 (openWakeWord correto) → **scores idênticos** (0.211 = 0.211). Mel-context descartado como causa. Prova limpa §10.
- **Pesquisa WebSearch + Context7** (Picovoice, openWakeWord, papers arXiv prefix-bias, patentes Amazon, livekit-wakeword): causa-raiz = **falta de `custom_negative_phrases`** (os configs `raro_gravar.yaml`/`raro_parar.yaml` NÃO têm hard negatives; o gerador auto só faz substituição de 1 palavra, nunca a frase-irmã). "Raro gravar"/"Raro parar" é o caso clássico **"prefix bias"** (compartilham onset "Raro") — solucionável com hard-negative mining, não limite do framework.
- **Esclarecimento (pedido do dono):** o limiar **0.34 é do NOSSO modelo ONNX, NÃO comparável ao 0.45 do Ok Camera** (engine Sensory paga, escala diferente). Copiar 0.45 seria erro de categoria. O que se copia do dump (debounce 2500ms + arquitetura) já está aplicado.

## O que NÃO foi feito (e por quê)

- **Gate de aceite ao vivo (Task 7) — NÃO concluído.** Substituído pelo gate de recall offline (mais seguro). O re-treino é pré-requisito antes de re-tentar voz ao vivo.
- **ERRO GRAVE meu — o probe quebrou a voz que funcionava (revertido):** para testar o detector ao vivo, montei um probe que **desligou o SFSpeech foreground** (via trava em `VoiceHostApiImpl`) e **pedi teste antes de confirmar o canal de log** (`pymobiledevice3` fora do PATH). O dono ficou sem voz. **Revertido por completo** (probe não-commitado), versão limpa reinstalada (container `ACC2B1DB`), voz restaurada. Repeti 2 erros já documentados: derrubar o que funciona antes de provar o substituto + pedir teste antes de confirmar estado. Memórias `feedback_verify_device_install_before_test` + `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`.
- **Re-treino do `raro_gravar` — NÃO feito** (é o próximo passo; envolve GPU + tempo do dono).
- **Bug do mel-context (Swift 1280 isolado vs openWakeWord 1760) — NÃO corrigido.** É real mas simétrico (não causa a assimetria); A/B provou que não muda os scores. Corrigir antes de re-derivar limiares finais (baixa prioridade).
- **ADR-0023 addendum sobre design de 2 classifiers — NÃO escrito.** A pesquisa sugere que rodar 2 frases-comando como 2 wake-words paralelos é off-label (o ideal é 1 gate "Raro" + 2ª etapa de disambiguação). Fica como Rung 4 (fallback se re-treino com hard negatives não resolver).
- **Drift de memória — mapeado, NÃO corrigido ainda** (a corrigir junto deste session-end): `raro-pattern-wakeword-onnx-3stage-pipeline-shapes` ainda diz "bug latente: extractors não versionados" (já resolvido).
- **Débito herdado:** gate §10 ffprobe Frente A (pré-roll).

## Aprendizados / surpresas

- **Green unit tests ≠ funciona.** O detector passou em todos os testes de unidade (silêncio, carga, inferência) mas NÃO reconhecia "Raro gravar". Só áudio real provou. O gate de recall offline foi a peça que separou "plumbing certo" de "modelo bom".
- **Confirmar barato antes de gastar caro.** O dono me cobrou 3× ("tem certeza? pesquisou? comparou com o dump?") e estava certo todas: (1) instrumentar scores no device antes de re-treinar; (2) experimento mel A/B de $0 antes de GPU; (3) esclarecer que 0.34≠0.45. Cada cobrança evitou retrabalho ou um erro de categoria.
- **A causa-raiz real só apareceu com WebSearch/Context7**, não com memória: hard negatives ausentes nos configs. Eu tinha concluído "re-treinar" de forma rasa; a pesquisa achou o QUE mudar no re-treino (custom_negative_phrases), não só "mais amostras".
- **iPhone bloqueado trava XCTest no device** ("Unlock ZenniTTy to Continue") — explicou retroativamente vários hangs que eu estava atribuindo a flake de infra. Medir o erro real (ler o log) em vez de assumir.
- **`timeout` não existe no macOS** (é GNU) — exit 127.

## Próximos passos

- **Re-treinar `raro_gravar` (Rung 3, ~US$3-4 RunPod 5090, recipe provado):** adicionar `custom_negative_phrases: ["raro parar"]` ao `raro_gravar.yaml` (e `["raro gravar"]` ao parar) — **a mudança load-bearing**; + lote cheio n_samples 2000→15000; + voice_design_prompts 50-100; optional model_size small→medium. Validar com o `WakeWordRecallTests` (já versionado) em voz real multi-speaker, NÃO síntese.
- **Antes do re-treino:** corrigir o bug do mel-context (1280→1760) para não treinar contra front-end quebrado.
- **Se re-treino com hard negatives não resolver o cross-firing:** Rung 4 — ADR-0023 addendum, 1 gate "Raro" + 2ª etapa (reusar SFSpeech foreground do ADR-0022).
- **Wiring do detector ao mic (background) = sessão dedicada** com spec própria (single mic owner + RMS gate + mic-handoff). NÃO fazer como fatia — quebra a voz que funciona.
- Débito herdado: gate §10 ffprobe Frente A.

## Referências

- Spec: `docs/superpowers/specs/2026-06-14-wakeword-detector-swift-design.md`
- Plano: `docs/superpowers/plans/2026-06-14-wakeword-detector-swift.md`
- Contrato I/O: `docs/superpowers/notes/raro-model-training.md`
- Harness de recall: `apps/mobile/ios/RunnerTests/WakeWordRecallTests.swift` + `Fixtures/`
- ADRs: 0023 (engine dedicada), 0022 (SFSpeech foreground, resto válido)
- Memórias: `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`, `raro-competitor-okcamera-android-apk-teardown`, `feedback_verify_device_install_before_test`, `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`
- Sessão anterior: `0026-s2d-wakeword-onnx-feature-extractors-bundled-io-contract.md`

0 `--no-verify`.
