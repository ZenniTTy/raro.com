# Áudio real do dono — treino híbrido do wake-word "Raro" (S2.F)

> Voz real de Eduardo Rodrigues gravada em 2026-06-21 para fechar o **domain gap** comprovado: o modelo `raro.onnx` treinado 100% sintético (VoxCPM) pontua a voz real do dono em ~0.08 médio (nível de silêncio). Cross-model control experiment (S2.E) provou que é treino-ruim, não a palavra. Esta pasta injeta a voz real no TREINO.

## Proveniência

| Item | Valor |
|---|---|
| Fonte | `~/Downloads/Testes.m4a` (gravado no iPhone, 2026-06-21 01:33) |
| Original | 126.4s, mono, 48kHz AAC, 1.08MB |
| Conteúdo | "Raro" repetido (~0-60s) + iscas do alfabeto (caro/barro/faro/varo/zaro...) (~60-108s) misturados |
| Rotulagem | whisper-cpp 1.9.1 (`ggml-small.bin`) PT-BR token-level + segmentação por energia (VAD) |

## Pipeline de processamento (reprodutível)

1. **`segment.py`** — corta `full_16k.wav` por energia (janelas 20ms, limiar adaptativo), separa por região temporal (pos 1-60s / neg 60-108.2s), pad 80ms. → 40 positivos + 31 negativos, nenhum colado >2.5s.
2. **`validate_clips.py`** — roda cada clip pelo pipeline ONNX real (mel→embedding→`raro.onnx`) e reporta score+rms. Confirmou: positivos médios 0.079, negativos 0.115 (domain gap reconfirmado na voz real). Achou 6 iscas que "vazam" (score >0.2) = hard-negatives valiosos.
3. **`prepare_train.py`** — filtro de qualidade (dur≥0.30s, rms≥0.012), peso 3x via **duplicação** (lib trava peso positivo em 1.0 — `trainer.py:291`), naming `clip_NNNNNN.wav` 6 dígitos (índices 900000+ p/ não colidir com sintéticos).

Artefatos: `manifest.json` (segmentação), `validated.json` (scores).

## Conteúdo desta pasta

| Pasta | Arquivos | O que é |
|---|---|---|
| `positive_train/` | 120 (`clip_900000.wav`+) | 40 takes "Raro" × 3 cópias |
| `negative_train/` | 93 (`clip_920000.wav`+) | 31 iscas (caro/barro/faro...) × 3 cópias |

**Sem test set real:** o estágio `augment` do livekit-wakeword degrada TODOS os splits (incl. `*_test/`) — `augment.py:127-131`, `features.py:47`. Um test real degradado não serve de gate honesto. O gate honesto é o **recall offline Python ($0)** rodando a voz CRUA contra o `.onnx` final.

## Como usar no RunPod (best practice, validada em fonte primária v0.2.1)

Ordem OBRIGATÓRIA — `generate` ANTES do drop, `augment` DEPOIS:

```bash
livekit-wakeword setup --config configs/raro.yaml   # baixa ACAV/RIR/MUSAN
livekit-wakeword generate configs/raro.yaml          # cria sinteticos clip_000000..003999
# DROP: copiar real-audio/{positive,negative}_train/* p/ output/raro/{positive,negative}_train/
cp real-audio/positive_train/*.wav output/raro/positive_train/
cp real-audio/negative_train/*.wav output/raro/negative_train/
livekit-wakeword augment configs/raro.yaml           # augmenta TUDO (sint+real) -> _rN.wav -> features
livekit-wakeword train  configs/raro.yaml
livekit-wakeword export configs/raro.yaml
livekit-wakeword eval   configs/raro.yaml
```

**Armadilhas que matam os reais SILENCIOSAMENTE (todas verificadas no código v0.2.1):**
- Naming fora de `clip_\d{6}\.wav` (ex: 7 dígitos, maiúsculo, sufixo) → ignorado sem erro (`augment.py:201`, `features.py:47`).
- Subpasta → invisível (glob flat, `augment.py:206`).
- Drop DEPOIS do augment → nunca extraído.
- Conferir log `Saved (N, 16, 96)` (`features.py:105`): N deve incluir os reais (sint × rounds + 213 × rounds).

## Best practice de proporção (fonte: CoreWorxLab/openWakeWord, 2026)

Reais weighted ~3x, ~20-50 takes, sintético mantido alto (diversidade = causa-raiz). NÃO baixar `n_samples` agressivamente. `augmentation.rounds: 2` empilha EQ+distortion+RIR+ruído (sem low-pass nativo; clips de bolso reais já trazem abafamento).
