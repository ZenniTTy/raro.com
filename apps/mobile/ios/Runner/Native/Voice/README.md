# Native/Voice — estado dos componentes

## Vigente (produção)

- `VoiceManager.swift` + `AudioSessionCoordinator.swift` — reconhecimento de voz **foreground** via `SFSpeechRecognizer` (ADR-0022). Comandos `"raro gravar"` / `"raro parar"`, validado no iPhone 12. **É o caminho de produção.**

## Dormente — NÃO remover, NÃO reativar sem ADR

- `WakeWordDetector.swift`, `WakeWordPipeline.swift`, `OnnxModelSession.swift`
- Modelos em `../../Resources/`: `raro.onnx`, `embedding_model.onnx`, `melspectrogram.onnx`
- Dependência SPM `onnxruntime` (linkada, sem uso em produção)

Pipeline ONNX para wake-word **background** (tela bloqueada). Reprovado no device na sessão 0029 (4 modelos, nenhum dispara "Raro" na voz real). Background ficou **STANDBY** porque o dono negocia licença Sensory — se ela entrar, este scaffold pode ser reaproveitado.

- Nada em produção referencia estas classes (são órfãs, mas compilam sem custo de runtime).
- Mantidas dormentes por decisão do dono (Bloco 0.2, sessão pós-0030): remover exigiria cirurgia no `project.pbxproj` com risco de quebrar o build iOS que hoje funciona, e o ganho (~2,4 MB) só importa no release (Bloco 5).
- Histórico completo preservado no commit `01a1f67`.
- **Reabrir treino ONNX/OpenWakeWord = beco provado.** Só com ADR novo. Ver ADR-0023 (standby), sessão 0029, e memória `feedback_synthetic_eval_is_not_the_gate_device_is`.
