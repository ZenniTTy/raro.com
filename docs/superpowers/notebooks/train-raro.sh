#!/usr/bin/env bash
# =============================================================================
# train-raro.sh — kit turnkey de treino do wake-word "Raro" (livekit-wakeword 0.2.1)
# =============================================================================
# Treina os DOIS classificadores (raro_gravar.onnx + raro_parar.onnx) via VoxCPM PT-BR.
#
# API/comandos/config VALIDADOS em fonte primária (github.com/livekit/livekit-wakeword +
# docs.livekit.io + PyPI, 2026-06-11). NÃO validado por execução real (o ambiente de autoria
# não tem GPU) → na 1ª rodada CONFIRA: caminhos de saída dos .onnx/metrics, comportamento do
# `setup`, e permissões do apt. Ajuste se o tool divergir — NÃO assuma.
#
# Requisitos: Linux + GPU CUDA (VoxCPM exige; Piper seria english-only). Python 3.11+.
#   Venues: Kaggle (T4/P100, grátis, 9h/sessão) OU RunPod/Vast (4090, ~US$0,34/h).
#   NÃO roda no Mac (sem CUDA).
#
# Uso:
#   bash train-raro.sh            # treino completo (n_samples dos YAMLs = 15000)
#   QUICK=1 bash train-raro.sh    # prova RÁPIDA (n_samples=2000) p/ validar pipeline + recall cedo
#   WORK=/tmp bash train-raro.sh  # define onde ficam caches/dados/saídas (disco com espaço)
#
# ⚠️ Kaggle (lição da 1ª rodada real, 2026-06-12): use WORK=/tmp, NUNCA /kaggle/working —
#   /kaggle/working tem cota de ~20GB e o setup baixa ~17GB de dados (ACAV+RIRs) → "No space
#   left on device". O /tmp fica no overlay raiz (~1.1TB livre). O script roda TUDO (dados,
#   cwd, output) dentro de $WORK. Saídas finais: copie os .onnx/.json p/ /kaggle/working no fim.
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="$HERE/configs"

# --- 0. caches em disco com ESPAÇO (evita 'disco cheio' — erro da sessão de treino anterior) -----
WORK="${WORK:-$PWD}"
export HF_HOME="${HF_HOME:-$WORK/.cache/hf}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$WORK/.cache}"
export HF_HUB_ENABLE_HF_TRANSFER=1
mkdir -p "$HF_HOME" "$XDG_CACHE_HOME"
echo "[info] WORK=$WORK · HF_HOME=$HF_HOME"

# --- 1. system deps (Ubuntu/Debian; Kaggle/RunPod rodam como root) -------------------------------
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq espeak-ng libsndfile1 ffmpeg sox portaudio19-dev

# --- 2. livekit-wakeword PINADO + voxcpm (PT-BR exige voxcpm; piper é english-only) --------------
pip install -q "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"

# --- 3. GPU CUDA obrigatória p/ VoxCPM (falha CEDO com mensagem clara) ----------------------------
python - <<'PY'
import sys
try:
    import torch
except Exception as e:
    sys.exit(f"[erro] torch nao importou: {e}")
if not torch.cuda.is_available():
    sys.exit("[erro] SEM GPU CUDA. VoxCPM (PT-BR) exige CUDA. Use Kaggle (T4/P100) ou RunPod/Vast (4090). NAO roda no Mac.")
print("[ok] GPU:", torch.cuda.get_device_name(0))
PY

# --- 4. copia configs p/ um dir de run; QUICK patcha n_samples p/ prova rápida --------------------
RUN_DIR="$WORK/raro_run"; rm -rf "$RUN_DIR"; mkdir -p "$RUN_DIR/configs"; cp "$CFG_DIR"/*.yaml "$RUN_DIR/configs/"
if [ "${QUICK:-0}" = "1" ]; then
  echo "[info] QUICK=1 → n_samples=2000 (prova de pipeline + sinal precoce; recall menor que o treino cheio)"
  sed -i 's/^n_samples: .*/n_samples: 2000/; s/^n_samples_val: .*/n_samples_val: 500/' "$RUN_DIR"/configs/*.yaml
fi
# data_dir explícito no disco grande (sem isso o setup baixa ~17GB no cwd → estourou /kaggle/working)
for f in "$RUN_DIR"/configs/*.yaml; do
  grep -q '^data_dir:' "$f" || printf '\ndata_dir: %s/raro_data\n' "$WORK" >> "$f"
done
mkdir -p "$WORK/raro_data"
# cd para o run dir: o output/ do treino é relativo ao cwd — precisa estar no disco grande também
cd "$RUN_DIR"

# --- 5. baixa modelos/dados base (mel/embedding/negativos) — uma vez (compartilhado) -------------
livekit-wakeword setup --config configs/raro_gravar.yaml
# (se o treino do raro_parar reclamar de dado faltando, rode tambem:
#   livekit-wakeword setup --config configs/raro_parar.yaml )

# --- 6. treina os DOIS comandos (1 modelo por frase — decisão 5a) --------------------------------
for cfg in raro_gravar raro_parar; do
  echo "=========================================================="
  echo "=== ($cfg) RUN: generate -> augment -> train -> export ==="
  echo "=========================================================="
  livekit-wakeword run "configs/${cfg}.yaml"
  echo "=== ($cfg) EVAL: recall + FP/hora + curva DET ==="
  livekit-wakeword eval "configs/${cfg}.yaml"
done

# --- 7. coleta as saídas (find robusto: não assume o dir exato de saída) --------------------------
echo ""
echo "================== SAÍDAS =================="
echo "[.onnx]"; find "$RUN_DIR" -name "*.onnx" -printf "  %p (%s bytes)\n" 2>/dev/null || true
echo "[metrics json]"; find "$RUN_DIR" -name "*.json" 2>/dev/null | sed 's/^/  /' || true
echo "==========================================="
echo ""
echo "[GATE] Baixe raro_gravar.onnx + raro_parar.onnx + os metrics JSON."
echo "       recall offline >80% e FP/hora baixo (~<0.5)?  SIM -> integrar no iOS."
echo "       NÃO -> Plano B (raro-model-training.md): subir n_samples/model_size,"
echo "              reforçar negativos PT-BR, +voice_design_prompts (50-100), gravações reais."
