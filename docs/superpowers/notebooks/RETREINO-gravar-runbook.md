# Runbook — Re-treino raro_gravar (+ raro_parar) com lote cheio + diversidade

> **Por que esta rodada existe (sessão 0027):** o modelo de PROVA (n_samples=2000, 14 prompts, sem hard negatives) REPROVOU no gate de voz REAL no iPhone 12 — `raro_gravar` topou em score 0.213 (precisa 0.34). Falha de **recall** por **gap síntese→voz real**, NÃO cross-fire. Provado por experimento offline ($0): CoreML≈CPU (fp16 descartado), mel A/B idêntico (mel-context descartado), scores brutos no device. Sintaxe `custom_negative_phrases` verificada em fonte primária (livekit-wakeword v0.2.1 `config.py:122` + `generate.py:390-391`).

## Mudanças aplicadas aos configs (já commitadas, $0)

| Mudança | Por quê | Impacto |
|---|---|---|
| **voice_design_prompts 14→80** (ambos) | Diversidade de locutores fecha o gap síntese→real (causa-raiz) | 🔴 LOAD-BEARING |
| **n_samples=15000 de verdade** | A 0025 rodou só 2000 via heredoc; o YAML 15000 NUNCA foi executado | 🔴 LOAD-BEARING |
| `custom_negative_phrases` no **parar** (`["raro gravar"]×3+var`) | Mata o cross-fire dele (0.339 num clip de gravar); parar tem folga de recall | 🟡 seguro |
| `custom_negative_phrases` no **gravar** (`["raro parar"]×3` modesto) | Insurance; modesto pois compartilha onset "raro" e pode deprimir recall fraco | 🟡 condicional |
| **model_size = small (NÃO mudar p/ medium)** | Medium piora overfit no sintético (alarga o gap síntese→real) | ❌ não fazer |

**FORA desta rodada (sessão separada):** treinar com voz REAL (livekit-wakeword é TTS-only; 8 clips é pouco; usar como gate de validação, que já é o `WakeWordRecallTests`).

## Pré-flight (confirmar ANTES de gastar GPU)

1. **Config canônico = `configs/*.yaml`** (NÃO o heredoc do `COMO-TREINAR-runpod-4090.md`, que hardcoda 2000 — foi o que treinou o modelo fraco). Rodar via `train-raro.sh` (copia `configs/*.yaml`, default mantém 15000) OU `livekit-wakeword run configs/<m>.yaml` direto.
2. **Na pod, ANTES de treinar:** `grep -c custom_negative_phrases configs/*.yaml` (=1 cada); `grep '^n_samples:' configs/*.yaml` (=15000); contar prompts (~80). Se algo errado, PARAR.
3. **Token HF read-only em mãos** (fix do hang de 22GB).
4. **`PIP_BREAK_SYSTEM_PACKAGES=1`** + template **cu128/torch280** (5090 sm_120 quebra em torch antigo).
5. **Crédito US$10 + AUTO-PAY OFF + plano de TERMINATE** (Stop não para cobrança).

## Runbook RunPod (passo a passo)

```bash
# STEP 5 — terminal da pod (Jupyter):
export PIP_BREAK_SYSTEM_PACKAGES=1            # GOTCHA #2 (PEP668)

# STEP 6 — HF (GOTCHA #1: anon rate-limit pendura 22GB ~76h @ GPU 0%):
export HF_TOKEN=<token-read-only-do-dono>
export HUGGING_FACE_HUB_TOKEN=$HF_TOKEN

# STEP 7 — system deps:
apt-get update -qq && apt-get install -y -qq espeak-ng libsndfile1 ffmpeg sox portaudio19-dev

# STEP 8 — instalar lib pinada + remover hf-xet (GOTCHA #1b: Xet trava CDN, CLOSE-WAIT):
pip install -q --break-system-packages "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"
pip uninstall -y hf-xet hf_xet 2>/dev/null || true   # NÃO usar hf_transfer (deprecado, hang)
command -v livekit-wakeword || exit 1

# STEP 9 — GPU self-check (GOTCHA #3: P100 sm_60 morre tarde; 4090=sm_89/5090=sm_120 OK):
python -c "import torch;assert torch.cuda.is_available();c=torch.cuda.get_device_capability();print('cap',c);assert c[0]>=7"

# STEP 10 — pôr os configs editados na pod (git clone do branch OU colar os 2 YAML).
#           VERIFICAR (pré-flight item 2) antes de treinar.

# STEP 11 — SETUP (baixa mel/embedding/negativos 1×; ÚNICO que usa --config):
livekit-wakeword setup --config configs/raro_gravar.yaml
#   ⚠️ vigiar o contador de download AVANÇANDO; congelado = hang do Xet/rate-limit.

# STEP 12 — TRAIN + EVAL dos 2 (config POSICIONAL, não --config). nohup p/ sobreviver a SSH drop:
nohup bash -c '
  livekit-wakeword run  configs/raro_gravar.yaml &&
  livekit-wakeword eval configs/raro_gravar.yaml &&
  livekit-wakeword run  configs/raro_parar.yaml &&
  livekit-wakeword eval configs/raro_parar.yaml
' > /workspace/train.log 2>&1 &

# STEP 13 — MONITORAR por DELTA, nunca por "Running" (lição 0025: run zumbi):
#   tempo = agora - timestamp_real_de_início (NÃO somar +Xmin de memória)
#   prova de vida = wc -c /workspace/train.log crescendo entre 2 momentos
#   ⚠️ 15000 VoxCPM é lento (~3-4s/clip) — a 0025 CANCELOU o full aos 60% por crédito. Vigiar saldo.

# STEP 14 — KILL-SIGNAL precoce: quando o eval do gravar imprimir optimal_recall,
#   se vier PIOR que 0.914 sintético → abortar e ajustar ANTES de gastar mais.
#   (eval sintético é SÓ sinal precoce, NUNCA o gate de aprovação — ver abaixo.)

# STEP 15 — DOWNLOAD raro_gravar.onnx + raro_parar.onnx + *_eval.json p/ o Mac,
#   em docs/superpowers/notebooks/modelos-treinados/ (sobrescrever os de prova).

# STEP 16 — TERMINATE a pod (NÃO Stop — Stop continua cobrando disco).
```

## Gate de aprovação (DEVICE, não sintético)

O `eval.json` (91,4% sintético) é **MENTIROSO** para este fim — deu 91,4% e o modelo fez 0/4 na voz real. **NÃO é o gate.**

1. Re-bundle os 4 `.onnx` novos no app (a Copy Bundle Resources já existe, commit `3e59951`) — copiar p/ `Runner/Resources/` e confirmar que entram no bundle do app E do RunnerTests.
2. Rodar `WakeWordRecallTests` no iPhone 12 (terminal-first, signing via `-allowProvisioningUpdates`, device DESBLOQUEADO).
3. **PASS:** `gravar 4/4 .start` (hoje 0/4) + `parar 4/4 .stop` (hoje 3/4) + **zero cross-fire**, com margem (gravar maxScore >0.34, parar >0.23, ideal >0.45). Ler as linhas `RECALL RESULT` + `SCORES[...]` do os_log.
4. ADR-0023 >80% é o piso, mas 80% de 4 fixtures é granularidade ruim → tratar como **4/4 obrigatório** neste set; expandir fixtures (+ vozes/distâncias) antes de declarar ship-ready.

## Toques do dono (o que só o Eduardo faz)

1. Conta RunPod + cartão + US$10 crédito + AUTO-PAY OFF.
2. Token HuggingFace read-only (grátis, huggingface.co/settings/tokens).
3. Deploy da pod (RTX 5090 ou 4090, template cu128/torch280, disco 50GB).
4. Conectar e ficar acessível durante o run (decisão de abortar se VoxCPM travar o crédito).
5. **TERMINATE a pod no fim.**
6. Rodar o iPhone 12 e reportar o resultado do `WakeWordRecallTests`.

## Custo/tempo

- **Medido (0025):** prova n=2000 ~US$3, passou sintético ~92%.
- **Estimado (não medido p/ full real):** full 15000 dos 2 modelos ~2-3h, ~US$1-3 GPU. Carregar US$10 cobre o run + uma 2ª iteração. Risco real ≠ taxa/h, é o hang do HF (queima horas a GPU 0% se pular o fix #1) + VoxCPM lento (0025 cancelou aos 60%).

## Se REPROVAR mesmo após esta rodada

Próxima rung NÃO é "medium model" (piora overfit). É a **Rung 4 (ADR-0023 addendum):** 1 gate "Raro" (ONNX) + 2ª etapa de disambiguação gravar/parar (reusar SFSpeech foreground do ADR-0022) — não depende da qualidade da voz sintética.

## Referências

- Configs: `configs/raro_gravar.yaml`, `configs/raro_parar.yaml` (editados nesta sessão)
- Gate de device: `apps/mobile/ios/RunnerTests/WakeWordRecallTests.swift` + `Fixtures/`
- Runbook RunPod base: `COMO-TREINAR-runpod-4090.md` (os 3 fixes)
- Sessão do gate: `docs/sessions/0027-s2d-wakeword-detector-built-recall-gate-gravar-weak.md`
- Memórias: `raro-pattern-wakeword-train-runpod-5090-hf-token`, `raro-pattern-wakeword-offline-recall-gate-before-wiring`, `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`
- Sintaxe `custom_negative_phrases`: livekit-wakeword v0.2.1 `config.py:122` + `generate.py:390-391` + `docs/data-generation.md`
