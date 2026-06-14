# 2026-06-14 — wakeword-detector-swift

> Spec da fatia "WakeWordDetector.swift" (S2.D parte 2 real). Brainstorming concluído (Context7 + WebSearch + inspeção dos grafos reais). Próximo passo após aprovação: `superpowers:writing-plans`.

## Status

`Approved`

## Owner / Implementer

- **Spec owner:** Eduardo Rodrigues (assina o WHAT)
- **Implementer agent:** `implementer` (TDD via `flutter-test-author` para a camada de teste nativa)
- **Validator agent:** `validator`

## Reading order (pre-flight obrigatório)

1. `docs/sessions/0026-s2d-wakeword-onnx-feature-extractors-bundled-io-contract.md` — estado real de partida (modelos + contrato de I/O)
2. `docs/superpowers/notes/raro-model-training.md` — **contrato de I/O dos 4 `.onnx`** (shapes/dtypes/streaming/limiares — fonte de verdade, não inventar)
3. `docs/superpowers/plans/2026-06-09-voice-wakeword-livekit-onnx.md` — plano-mãe (esta fatia entrega a Task 3 isolada; bloco "VALIDAÇÕES E CORREÇÕES (0024)" supersede detalhes inline)
4. `CLAUDE.md` (§10 gates de voz contínua, §13 workflow iOS terminal-first)
5. ADRs: `0023` (engine dedicada), `0009` (wake word "Raro"), `0022` (resto válido)

## Problem

A voz em **background** (tela bloqueada) exige um detector de wake-word próprio on-device (ADR-0023 — SFSpeech é foreground-only por restrição fundamental do iOS). Os 4 modelos ONNX já estão treinados (~92%) e versionados, e o contrato de I/O está validado, mas **falta a peça nativa que roda o pipeline**: `WakeWordDetector.swift` não existe. Sem ele, o áudio capturado pelo `AudioSessionCoordinator` não vira `WakeCommand`.

## Sizing (auto-sizing)

- [ ] **Quick**
- [x] **Medium** — 3 arquivos Swift novos + 1 XCTest + edição do `project.pbxproj` (4 modelos + arquivos novos). Sem novo bridge (o contrato Pigeon `voice_api` já existe e NÃO muda). Sem novo ADR (ADR-0023 já cobre ONNX Runtime).
- [ ] **Large**

## Q-table (perguntas antes de implementar)

| # | Question | Answer |
|---|----------|--------|
| 1 | A sessão chega ao gate de device (iPhone 12 físico)? | Sim — dono confirmou aparelho disponível. Sessão pode fechar com gate de aceite executado. |
| 2 | Escopo: só detector ou detector + reescrita do VoiceManager + câmera? | **Só detector + bundle + XCTest.** Reescrita do VoiceManager/câmera/flag Dart = sessão seguinte (Surgical Changes; se reprovar no gate, não joga fora a reescrita). |
| 3 | XCTest prova recall (fixtures de áudio) ou só cadeia/carga? | **Cadeia + carga (determinístico).** Recall é o gate oficial ao vivo no device (ADR-0023: "medido no device, não no Simulator"). Fixtures sintéticos dariam falsa cobertura. |
| 4 | EP do `embedding_model` (o contrato só travou mel=CPU, classifier=CoreML)? | **CoreML, com fallback CPU explícito e logado.** WebSearch: embedding é ~85% do custo de inferência → vale a ANE. Fallback evita bug silencioso. Confirmar no smoke do device. |
| 5 | Valores de dimensão dos grafos são confiáveis (herdados da 0026)? | **Re-validar no Passo 0** (`pip install onnx` + extração dos 4 grafos) antes de codar. Não confiar na inspeção de sessão anterior. |

## Observable goals (testes em device)

- [ ] **`WakeWordPipeline` (lógica pura, Simulator, determinístico):** acumula exatamente 1280 samples antes do mel; janela mel desliza step 8; embedding só roda com ≥76 frames; classificador só dispara com ≥16 embeddings montando `[1,16,96]`; limiar pino-exato (0.35→gravar, 0.33→não; 0.24→parar, 0.22→não); debounce (2 cruzamentos <2500ms → 1 comando).
- [ ] **`OnnxModelSession` + carga (device, serial):** os 4 modelos carregam de `Bundle.main` (vermelho se pbxproj errado); buffer conhecido pela cadeia completa → `score` finito, não-NaN, em `[0,1]`; EP por modelo confirmado (mel CPU/XNNPACK; embedding+classifier CoreML, fallback logado).
- [ ] **Gate de aceite (device, voz ao vivo, ADR-0023):** "Raro gravar"/"Raro parar" em várias distâncias/entonações → recall > 80%; áudio sem a palavra → FP baixo; coexistência voz↔gravação (foreground SFSpeech não pode brigar pelo mic). Prova por `pymobiledevice3 syslog live --match Runner` (contar `wake matched`).

## UI / protótipo (se aplicável)

- Tela do protótipo: — (peça nativa, sem UI nova nesta fatia; o indicador de escuta Dart já existe e não é tocado)
- Copy literal: — (sem copy nova)

## Architecture

Três unidades Swift novas + correção do bundle. Fronteiras com 1 responsabilidade cada:

```
AudioSessionCoordinator (EXISTE) --onFrame([Float])--> WakeWordDetector (fachada)
                                                              |
                                         monta + injeta nas peças abaixo
                                                              |
                      WakeWordPipeline (puro, stateful)   OnnxModelSession x4
                      - ring buffer mel (>=76 frames)     (wrapper fino por modelo)
                      - ring buffer embeddings (>=16)     - 1 ORTSession + EP certo
                      - limiar + debounce/cooldown        - ORTEnv compartilhado (singleton)
                      - depende de PROTOCOLOS, nao de ONNX - run(input) -> output
```

- **`OnnxModelSession`** — encapsula TODA a API ONNX (única peça que conhece `ORTSession`/`ORTValue`). Carrega 1 modelo do bundle com o EP escolhido; superfície mínima `run(input:) -> output`. `ORTEnv` é **singleton process-global** compartilhado pelas 4 sessões (validado: ONNX RT docs). `ORTSession.Run` é thread-safe após construção (validado) → reusar a sessão, chamar da `DispatchQueue` do coordinator sem reconstruir por frame.
- **`WakeWordPipeline`** — máquina de estados **pura**: ring buffers mel/embedding, decisão de janela, limiar/debounce. Depende de protocolos (`MelExtracting`/`Embedding`/`Classifying`), **não importa ONNX** → testável com fakes determinísticos sem device.
- **`WakeWordDetector`** — fachada: instancia as `OnnxModelSession` reais, injeta no pipeline, expõe a API que o `VoiceManager` consumirá **na sessão seguinte** (nesta fatia existe e é testado, mas não cabeado).

## Data flow (contrato 0026 — não inventar)

1. `onFrame([Float])` 16kHz mono → acumula até **1280 samples (80ms)**.
2. **mel** (`melspectrogram.onnx`, **CPU/XNNPACK**): in `input` `[1,samples]` → out `output` `[T,1,?,32]` (32 bins); normalização **`x/10+2`**; push no ring buffer mel (≥76).
3. **embedding** (`embedding_model.onnx`, **CoreML**+fallback): janela 76×32 → in `input_1` `[1,76,32,1]` → out `conv2d_19` `[1,1,1,96]`; step **8**; push no ring buffer embeddings (≥16).
4. **classificação** (`raro_gravar.onnx` + `raro_parar.onnx`, **CoreML**): `embeddings` `[1,16,96]` → 2 scores `[1,1]`. Dispara gravar se `≥0.34`, parar se `≥0.23` (limiares ótimos, **não 0.5**).
5. **decisão**: emite `WakeCommand.start/.stop` + debounce ~2500ms. RMS gate (0.026/0.012) = parâmetro **configurável, default OFF** nesta fatia (ligar só se device mostrar FP/bateria ruins — sem overengineering antecipado).

Nomes de tensor (`input`/`output`, `input_1`/`conv2d_19`, `embeddings`/`score`) **verificados nos 4 `.onnx` reais** (`strings`, 2026-06-14).

## Test strategy

- **Passo 0 (gate de entrada):** `pip install onnx` em venv → re-extrair shapes/dtypes dos 4 grafos. Diverge do contrato → corrigir contrato antes de codar.
- **Camada 1 (Simulator, determinístico):** `WakeWordPipeline` com fakes dos protocolos. Cobre toda a máquina de estados sem ONNX/device.
- **Camada 2 (device, serial):** `OnnxModelSession` carrega 4 modelos + score finito. **Rodar `-parallel-testing-enabled NO`** (memória `raro-pattern-ios-audioengine-xctest-flaky-parallel-sim` — paralelo é flaky). `OnnxModelSession` recebe `[Float]` puro (não toca `AVAudioEngine`) → não herda flakiness.
- **Camada 3 (device, voz viva):** gate de aceite ADR-0023.
- **Prova de execução real:** grep no output por `Test Suite '<Classe>' started` + contagem subindo. **Exit 0 NÃO prova que rodou** (memórias `raro-pattern-ios-xctest-pbxproj-4-insertions` + `feedback_device_debug_use_real_logs_not_assumptions`).

## Out of scope

- Reescrita do `VoiceManager.swift` (orquestração tap→detector→WakeCommand) — sessão seguinte.
- Toque cirúrgico na câmera (coexistência mic↔gravação) — sessão seguinte.
- Flip de `_voiceEngineAvailable=true` (voice_controller.dart:12) — só após o gate passar (ADR-0023).
- Remoção de `NSSpeechRecognitionUsageDescription` — só quando ONNX superseder o foreground SFSpeech.
- Lado Android — backlog Sprint 3.
- Débito herdado: gate §10 ffprobe Frente A (pré-roll combinado).

## Risks

| Risco | Mitigação |
|-------|-----------|
| `Bundle.main.url` retorna `nil` (4 `.onnx` fora do pbxproj) | XCTest de carga falha vermelho; a fatia INCLUI as inserções no pbxproj |
| Embedding cai em CPU sem ninguém saber | Fallback CoreML→CPU **explícito e logado** via `os_log` |
| Nomes de tensor errados em `runWithInputs` | Verificados nos grafos reais (2026-06-14) |
| Valores de dimensão herdados da 0026 sem re-checar | Passo 0: re-extrair com `pip install onnx` antes de codar |
| XCTest com AVAudioEngine flaky em sim paralelo | Rodar serial; `OnnxModelSession` desacoplado do engine; provar execução por grep, não exit 0 |
| Verde-falso do script `test:ios` (`tail` mascarando exit) | Já corrigido (commit 5210f62, pipefail+PIPESTATUS); conferir suíte no output |
| Arquivo Swift novo some do alvo (pbxproj) | 4 inserções por arquivo (produção E teste); verificar `Test Suite started` |
| Recall < 80% no gate | Plano B: lote cheio 15000 / +voice_design_prompts / gravações reais PT-BR. **NUNCA Picovoice** (recusado) |

## ADRs necessários

- [x] ADR existente: `0023-voice-engine-dedicated-not-sfspeechrecognizer.md` (cobre ONNX Runtime no Runner). `adr-guardian` confirma cobertura no Passo 0 do plano antes de tocar `project.pbxproj`/`Blueprint.md`.
- [ ] ADR novo: não necessário.

## References

- Sessão de partida: `docs/sessions/0026-s2d-wakeword-onnx-feature-extractors-bundled-io-contract.md`
- Contrato de I/O: `docs/superpowers/notes/raro-model-training.md`
- Plano-mãe: `docs/superpowers/plans/2026-06-09-voice-wakeword-livekit-onnx.md` (Task 3)
- ADRs: 0023, 0022, 0009
- Specs relacionadas: `2026-06-09-voice-wakeword-livekit-onnx-engine-design.md`
- Validação externa (2026-06-14): Context7 `/microsoft/onnxruntime-swift-package-manager`; ONNX RT threading docs; openWakeWord `utils.py`
- Memórias: `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`, `raro-pattern-ios-xctest-pbxproj-4-insertions`, `raro-pattern-ios-audioengine-xctest-flaky-parallel-sim`, `feedback_verify_device_install_before_test`
