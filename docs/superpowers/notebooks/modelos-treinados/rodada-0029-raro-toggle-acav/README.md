# Modelo wake-word "Raro" (toggle único) — rodada 0029

> Detector de palavra única **"Raro"** (toggle: dizer "Raro" inicia OU encerra gravação), conforme [ADR-0024](../../../../decisions/0024-voice-single-raro-toggle.md) + Blueprint M03. Substitui o par `raro_gravar`/`raro_parar` (dois comandos, abandonado por cross-fire — ver ADR-0024).

## Proveniência

- **Lib:** `livekit-wakeword==0.2.1` (VoxCPM TTS sintético PT-BR)
- **Config:** [`configs/raro.yaml`](../../configs/raro.yaml) — `target_phrases: ["raro"]`, 80 `voice_design_prompts` (diversidade BR), `custom_negative_phrases` rima-PT (caro/faro/barro/raio/...), `n_samples: 4000`, **COM ACAV** (negativos genéricos — FP robusto para escuta em background)
- **GPU:** RunPod RTX 5090, torch 2.8/cu128
- **Treinado:** 2026-06-20

## Eval (SINTÉTICO — NÃO é o gate)

```json
recall: 0.815 (threshold 0.5) → 0.882 (threshold ótimo 0.17)
fpph:   0.0   (threshold 0.5) → 0.17 (threshold ótimo)
n_positive: 1000, n_negative: 31124, validation_hours: 17.29
```

⚠️ **O eval sintético JÁ enganou** (rodada anterior: 91% sintético → 0% na voz real). O **gate de aprovação é o device** (iPhone 12 com gravações reais de "Raro"), não estes números. FPPH 0,0 (vs 2,08 do `raro_parar` sem ACAV) confirma que o ACAV deixou a fronteira "não-é-Raro" robusta — necessário para background.

## Pendente (próxima sessão)

1. Refatorar `WakeWordDetector`/`WakeWordPipeline` de 2 classifiers → 1 (`raro`) + evento toggle único (app alterna estado).
2. Gravações reais do dono dizendo só "Raro" (4-6×) → fixtures.
3. Re-bundle `raro.onnx` no app (remover `raro_gravar`/`raro_parar` + pbxproj).
4. Gate `WakeWordRecallTests` adaptado no iPhone 12 + params do concorrente (debounce 2500ms, RMS gate).

## Risco conhecido (ADR-0024)

"Raro" é curto (2 sílabas) → FP maior em PT-BR (rimas). Mitigado por ACAV + negativos-rima + debounce + RMS gate. Validar FP real no device antes de produção.
