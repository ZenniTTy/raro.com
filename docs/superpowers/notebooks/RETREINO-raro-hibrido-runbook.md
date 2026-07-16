# Runbook — Re-treino HÍBRIDO do `raro.onnx` (voz real do dono) — S2.F

> **Por que esta rodada (S2.F):** o `raro.onnx` toggle treinado 100% sintético (S2.D) pontua a voz REAL do dono em ~0.08 médio (nível de silêncio) — domain gap comprovado pelo cross-model control experiment (S2.E). Esta rodada injeta **213 clips reais** (40 "Raro" + 31 iscas, peso 3× via duplicação) no TREINO, com augmentation `rounds:2`. Alvo = toggle "Raro" único (Blueprint M03 L461, ADR-0024 — RELIDO, sem drift).

## Diferença vs rodadas anteriores (CRÍTICO)

| Rodada | Comando | Áudio |
|---|---|---|
| S2.D (gravar/parar/toggle) | `livekit-wakeword run configs/X.yaml` (tudo num passo) | 100% sintético |
| **S2.F (esta)** | **estágios SEPARADOS** `generate`→DROP→`augment`→`train` | sintético + **voz real** |

A separação é obrigatória: os reais entram ENTRE `generate` e `augment` (validado na fonte v0.2.1: `augment.py:201`, `features.py:47`).

## Pré-flight (confirmar ANTES de gastar GPU)

1. Config canônico = `configs/raro.yaml` (tem `augmentation.rounds: 2`, `n_samples: 4000`, 80 prompts, `custom_negative_phrases`).
2. Reais versionados em `docs/superpowers/notebooks/real-audio/{positive,negative}_train/` (120+93 wavs, naming `clip_900000+.wav` 6-dígitos, já validado contra os regexes).
3. Token HF read-only em mãos (fix do hang 22GB).
4. `PIP_BREAK_SYSTEM_PACKAGES=1` + template cu128/torch280 (5090 sm_120).
5. Crédito + AUTO-PAY OFF + plano de TERMINATE.

## Runbook (estágios separados — esta é a única forma de incluir a voz real)

```bash
set -e
export ROOT=/workspace/raro_run
export HF_HOME=/workspace/hf
export PIP_BREAK_SYSTEM_PACKAGES=1
export HF_TOKEN="<token-read-only-do-dono>"
export HUGGING_FACE_HUB_TOKEN="$HF_TOKEN"
mkdir -p "$ROOT"; cd "$ROOT"

# --- INSTALL (3 fixes de armadilha) ---
apt-get update -qq && apt-get install -y -qq espeak-ng libsndfile1 ffmpeg sox portaudio19-dev
pip install -q --break-system-packages "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"  # GOTCHA#2 PEP668
pip uninstall -y hf-xet hf_xet 2>/dev/null || true                                          # GOTCHA#1b Xet trava CDN
command -v livekit-wakeword || exit 1
python -c "import torch;assert torch.cuda.is_available();c=torch.cuda.get_device_capability();print('cap',c);assert c[0]>=7"  # GOTCHA#3

# --- TRAZER repo (config + reais) ---
git clone --branch feat/camera-native-bridge --depth 1 <repo-url> /workspace/raro.com
cp /workspace/raro.com/docs/superpowers/notebooks/configs/raro.yaml configs/raro.yaml
# (ajustar output_dir/data_dir no yaml se necessario para $ROOT)

# --- STAGE 1: setup (baixa ACAV/RIR/MUSAN 1x) ---
livekit-wakeword setup --config configs/raro.yaml   # vigiar contador AVANCANDO; congelado=hang

# --- STAGE 2: generate (cria sinteticos clip_000000..003999) ---
livekit-wakeword generate configs/raro.yaml

# --- STAGE 3: <<< DROP DOS REAIS >>> (entre generate e augment, FLAT, nomes 6-digitos) ---
REAL=/workspace/raro.com/docs/superpowers/notebooks/real-audio
OUT=$(python -c "import yaml;c=yaml.safe_load(open('configs/raro.yaml'));print(c.get('output_dir','output'))")/raro
cp "$REAL/positive_train/"*.wav "$OUT/positive_train/"
cp "$REAL/negative_train/"*.wav "$OUT/negative_train/"
# PROVA: contar que entraram
echo "positivos no split: $(ls "$OUT/positive_train/"clip_*.wav | wc -l) (deve incluir +120 reais 900000+)"
ls "$OUT/positive_train/"clip_9*.wav | wc -l   # deve ser 120
ls "$OUT/negative_train/"clip_9*.wav | wc -l   # deve ser 93

# --- STAGE 4: augment (augmenta TUDO incl reais -> _rN.wav -> features) ---
livekit-wakeword augment configs/raro.yaml
# PROVA CRITICA: o log "Saved (N, 16, 96)" de positive_train deve crescer com os reais.
# Esperado ~ (4000 + 120) * rounds(2) features positivas.

# --- STAGE 5-7: train / export / eval ---
nohup bash -c '
  livekit-wakeword train  configs/raro.yaml &&
  livekit-wakeword export configs/raro.yaml &&
  livekit-wakeword eval   configs/raro.yaml
' > /workspace/train.log 2>&1 &

# MONITORAR por DELTA (licao 0025: nunca "Running"; tempo = agora - inicio real;
# prova de vida = wc -c /workspace/train.log crescendo entre 2 momentos).
```

## Gate de aprovação (DEVICE/offline, NÃO o eval sintético)

O `eval.json` sintético é **MENTIROSO** para este fim (deu 91% e fez 0/4 na voz real na S2.D). **NÃO é o gate.**

1. Baixar `raro.onnx` novo → `apps/mobile/ios/Runner/Resources/raro.onnx`.
2. **Gate offline ($0, primeiro):** rodar o pipeline Python na voz CRUA do dono (os mesmos 40 clips de `real-audio/positive_train/`, take único sem duplicar) contra o `.onnx` novo. PASS = "Raro" sobe de ~0.08 médio para **disparar com folga** (alvo ≥0.5, mínimo o threshold de produção). Comparar os 6 que vazavam ANTES.
3. **Gate device:** `WakeWordRecallTests` no iPhone 12 (terminal-first). Blueprint L582 = >90% em silêncio.
4. Só DEPOIS: wiring background (sessão dedicada).

## Toques do dono

1. Conta RunPod + crédito + AUTO-PAY OFF.
2. Token HF read-only.
3. Criar a pod (5090/4090, cu128/torch280, disco 50GB) + me dar acesso (API key no `~/.runpod/config.toml`, NÃO no chat).
4. **TERMINATE no fim.**

## Custo estimado

~US$3 (medido S2.D: prova ~US$3). Carregar US$10 cobre run + 1 iteração. Risco real = hang do HF (fix #1) + VoxCPM lento (cancelou aos 60% na 0025).

## Referências

- Reais + proveniência: `docs/superpowers/notebooks/real-audio/README.md`
- Mecanismo real-audio (fonte v0.2.1): `augment.py:201`, `features.py:47`, `trainer.py:291`
- Config: `configs/raro.yaml`
- Memórias: `raro-pattern-wakeword-train-runpod-5090-hf-token`, `feedback_reread_blueprint_before_expensive_train`, `feedback_long_job_monitoring_measure_dont_assume`
