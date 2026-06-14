# Treinar o modelo "Raro" numa GPU 4090 alugada (RunPod) — checklist leigo

> Plano B depois que a T4 grátis do Kaggle travou (10h sem terminar — VoxCPM é lento demais na T4).
> A RTX 4090 do RunPod é ~4-6× mais rápida. Custo total do treino: **~R$ 4-7**.
> Comandos reaproveitam o script JÁ VALIDADO no Kaggle (chegou a "Setup complete!" + treino + Loading VoxCPM),
> só trocando o ambiente (pod = root, disco em /workspace; sem firula de /tmp nem forçar T4).

---

## PARTE 1 — Criar a máquina (RunPod)

- [ ] 1. Acesse **console.runpod.io** → criar conta → confirmar e-mail.
- [ ] 2. **Billing → Add Credit** → cartão (BR comum funciona, cobra em US$) → carregar **US$ 10** → auto-pay **DESLIGADO**.
- [ ] 3. **Pods → Deploy**.
- [ ] 4. GPU: **RTX 4090** · Nuvem: **Community Cloud** (mais barata).
- [ ] 5. Template: **PyTorch 2.5+ / Python 3.11** (ex.: `runpod/pytorch:2.8...cuda12.8`). NÃO pegar template velho.
- [ ] 6. Disco (Volume): **30 GB** · dar nome · **Deploy On-Demand**.
- [ ] 7. Status → **Running** (1-2 min) → **Connect → Jupyter Lab**.
- [ ] 8. No Jupyter: **File → New → Terminal**.

---

## PARTE 2 — Rodar (colar no terminal do pod)

- [ ] 9. Cole o bloco inteiro abaixo e aperte Enter. (Prova rápida; ~20-40 min.)

> ⚠️ **Antes:** gere um token grátis do HuggingFace (huggingface.co/settings/tokens → Read) e troque `COLE_SEU_HF_TOKEN` abaixo. SEM ele, o download de ~22GB de ruído PENDURA (rate-limit anônimo → estimou 76h, GPU ociosa). Com token: baixa em segundos. (Validado 2026-06-13: foi a causa do único travamento real.)

```bash
set -e
export ROOT=/workspace/raro_run
export HF_HOME=/workspace/hf
export PIP_BREAK_SYSTEM_PACKAGES=1
# >>> destrava download HuggingFace (rate-limit anonimo + conexao pendurada) <<<
export HF_TOKEN="COLE_SEU_HF_TOKEN"
export HUGGING_FACE_HUB_TOKEN="$HF_TOKEN"
export HF_HUB_DISABLE_XET=1
export HF_HUB_DOWNLOAD_TIMEOUT=30
export HF_HUB_ETAG_TIMEOUT=30
mkdir -p "$ROOT/configs" "$HF_HOME" "$ROOT/raro_data"
cd "$ROOT"

# >>> INSTALAÇÃO (template RunPod bloqueia pip sem --break-system-packages) <<<
apt-get update -qq && apt-get install -y -qq espeak-ng libsndfile1 ffmpeg sox portaudio19-dev
pip install -q --break-system-packages "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"
# CRITICO: remover o backend "Xet" do HuggingFace — ele PENDURA o download de muitos
# arquivos pequenos (trava sempre em ~35%, conexoes CLOSE-WAIT, GPU ociosa), MESMO com token.
# Sem ele, o download HTTP classico voa (validado: 1h30 travado -> <1s). Ver HF_HUB_DISABLE_XET acima.
pip uninstall -y hf-xet hf_xet 2>/dev/null || true
python -c "import torch; assert torch.cuda.is_available(); cap=torch.cuda.get_device_capability(); print('GPU OK:', torch.cuda.get_device_name(0), 'cap', cap); assert cap[0]>=7, 'GPU velha (precisa sm_70+)'"
python -c "from huggingface_hub import whoami; import os; print('HF logado:', whoami(token=os.environ['HF_TOKEN'])['name'])" 2>&1 | head -1 || echo "(token so no env)"
command -v livekit-wakeword || { echo 'ERRO: livekit-wakeword nao instalou'; exit 1; }
# >>> fim da instalação <<<
# NAO usar HF_HUB_ENABLE_HF_TRANSFER/hf_transfer (deprecado, hang silencioso).

PROMPTS='  voice_design_prompts:
    - "A young adult woman, clear mid-pitch voice, moderate pace, calm"
    - "A young adult man, warm baritone, steady pace, friendly"
    - "A middle-aged woman, slightly low voice, relaxed pace, confident"
    - "A middle-aged man, deep voice, slow pace, authoritative"
    - "A teenage girl, bright high-pitched voice, quick pace, energetic"
    - "An elderly man, gravelly low voice, slow pace, measured"
    - "A woman speaking from a distance with light room reverb"
    - "A man speaking close to the mic, intimate"'
cat > configs/raro_gravar.yaml <<EOF
model_name: raro_gravar
target_phrases:
  - "raro gravar"
tts_backend: voxcpm
data_dir: $ROOT/raro_data
voxcpm_tts:
$PROMPTS
n_samples: 2000
n_samples_val: 500
model:
  model_type: conv_attention
  model_size: small
steps: 50000
target_fp_per_hour: 0.2
EOF
sed 's/raro_gravar/raro_parar/; s/raro gravar/raro parar/' configs/raro_gravar.yaml > configs/raro_parar.yaml
livekit-wakeword setup --config configs/raro_gravar.yaml
for c in raro_gravar raro_parar; do
  echo "===== treinando $c ====="; livekit-wakeword run configs/$c.yaml
  echo "===== avaliando $c ====="; livekit-wakeword eval configs/$c.yaml
done
echo "===== .ONNX GERADOS ====="
find "$ROOT" -name "*.onnx" -exec ls -lh {} \;
echo "===== METRICAS ====="
find "$ROOT" -name "*.json" | while read f; do echo "--- $f ---"; cat "$f"; done
echo "FIM."
```

- [ ] 10. Esperar terminar (pode fechar a aba; o job continua). Marcos: `GPU OK: ... cap (8, 9)` → `===== treinando raro_gravar =====` → `FIM.`.
- [ ] 11. Conferir que os **dois `.onnx`** apareceram na lista.

> ⚠️ Diferença vs Kaggle: aqui usamos `target_phrases` e `run/eval` recebem o caminho do config (SEM `--config`) — exatamente como o script que já rodou no Kaggle. NÃO usar `wake_phrase` nem `run --config`.

---

## PARTE 3 — Baixar e DESLIGAR

- [ ] 12. No painel de arquivos do Jupyter, navegue até `/workspace/raro_run/.../`, ache os `raro_gravar.onnx` e `raro_parar.onnx` + os `.json` → clique direito → **Download** (salva no Mac).
- [ ] 13. **DESLIGAR (CRÍTICO):** Pods → ícone de **lixeira (Terminate)** → confirmar.
      ⚠️ Só "Stop/Pause" **NÃO** para de cobrar. Sempre **Terminate** depois de baixar.
      Regra: Stop = táxi parado com taxímetro ligado. Terminate = desceu e fechou a corrida.

---

## PARTE 4 — Lote cheio (os números de verdade)

- [ ] 14. Se a prova terminou com `FIM.` e os `.onnx`: rode de novo trocando no bloco
      `n_samples: 2000` → `n_samples: 15000` e `n_samples_val: 500` → `n_samples_val: 3000`.
      (~1h30-3h na 4090; custo ~R$ 3-6.)
- [ ] 15. Me mande os 2 `.onnx` + `.json`, OU os números: **recall** (queremos >80%) e **FP/hora** (queremos baixo).

---

## Custo (RTX 4090 Community @ US$ 0,34/h · US$1≈R$5,40)

| | Tempo | Custo |
|---|---|---|
| Prova (2000) | ~20-40 min | ~R$ 0,60-1,25 |
| Lote cheio (15000) | ~1h30-3h | ~R$ 2,75-5,50 |
| **Total** | ~2-3h | **~R$ 4-7** |

Carrega US$ 10, sobra folgado.
