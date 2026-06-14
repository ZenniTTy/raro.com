# Modelos de wake-word "Raro" (ONNX)

Modelos on-device de detecção das frases de comando, treinados com `livekit-wakeword` 0.2.1 + VoxCPM.

| Arquivo | Frase | Recall (limiar ótimo) | Falsos pos./hora | Limiar ótimo |
|---|---|---|---|---|
| `raro_gravar.onnx` | "raro gravar" (START) | 91,4% | 0,18 | 0,34 |
| `raro_parar.onnx` | "raro parar" (STOP) | 92,2% | 0,18 | 0,23 |

> No limiar padrão (0.5) o recall é ~88%; use o **limiar ótimo** acima na integração iOS.
> Métricas completas em `*_eval.json` (validação sobre ~17h de áudio negativo).

## Proveniência (honestidade de origem)

- **Treino:** rodada de PROVA, `n_samples=2000` por classe (não o lote cheio de 15000).
- **Por que prova e não cheio:** o lote cheio (15000) foi tentado mas **cancelado** — a geração VoxCPM
  desacelerou (~3-4s/clip) e estouraria o saldo da GPU alugada antes de terminar (sessão 2026-06-13).
  Estes modelos de prova já bateram o gate (recall >80% + FP baixo), então são suficientes para a
  **primeira validação no iPhone**. Se a detecção no device for fraca, o Plano B é o lote cheio
  (ver `COMO-TREINAR-runpod-4090.md`) ou +voice_design_prompts (50-100).
- **Hardware:** RunPod RTX 5090 (prova). Custo ~US$3.
- **Arquitetura:** conv_attention/small. Backend TTS: voxcpm (PT-BR; Piper é english-only).

## Próximo passo

Integração iOS: `WakeWordDetector.swift` (carregar o .onnx, ligar ao `AudioSessionCoordinator`,
rodar a inferência, disparar gravar/parar). NÃO existe ainda — é a próxima sessão (S2.D),
feita com brainstorm → plano → TDD. onnxruntime já está integrado no projeto (SPM).
