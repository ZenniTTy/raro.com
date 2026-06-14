# Prompt para o Claude Cowork — executar o treino do wake-word "Raro" (Parte 2 em diante)

> Cole TUDO abaixo (entre as linhas `===`) como mensagem para o Claude Cowork.

===

# Sua tarefa: treinar e avaliar 2 modelos de wake-word ("Raro gravar" / "Raro parar") numa GPU e me reportar os números

Você vai rodar um treino de detector de palavra-chave on-device e me devolver, no fim, **o recall e os falsos-positivos/hora de cada um dos dois comandos**. Execute você mesmo se tiver um ambiente com GPU CUDA; se não tiver, me guie passo a passo no Kaggle (notebook já aberto). NÃO declare "pronto" sem os números da avaliação (`eval`).

## FATOS JÁ VALIDADOS EM FONTE PRIMÁRIA (não re-derive de memória; se precisar checar, use github.com/livekit/livekit-wakeword + pypi.org/project/livekit-wakeword + docs.livekit.io/agents/multimodality/audio/wakeword)

- **Ferramenta:** `livekit-wakeword` versão **0.2.1** (Python ≥3.11).
- **Idioma:** português EXIGE `tts_backend: voxcpm`. **Piper é english-only** (confirmado na doc). VoxCPM precisa de **GPU CUDA (~8GB VRAM)** — sem GPU não roda.
- **CLI real:** `livekit-wakeword setup --config X.yaml` (baixa modelos base) → `livekit-wakeword run X.yaml` (faz generate→augment→train→export) → `livekit-wakeword eval X.yaml` (mede recall + FP/hora + curva DET). A flag `--config` é SÓ do `setup`; `run` e `eval` recebem o caminho do config como argumento POSICIONAL.
- **Instalação:** `pip install "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"` + system deps (Ubuntu) `espeak-ng libsndfile1 ffmpeg sox portaudio19-dev`.
- **Saída:** um `<model_name>.onnx` por config + um JSON de métricas.
- **Decisão de arquitetura:** 1 modelo por frase → `raro_gravar.yaml` (comando START) e `raro_parar.yaml` (comando STOP). Configs separados.
- **Gate de aceite:** recall offline **> 80%** E FP/hora baixo (~< 0.5). 
- **Aviso oficial:** acurácia multilíngue é menor que inglês. ⚠️ PT-BR NÃO está listado explicitamente nos "30 idiomas" do VoxCPM — então, CEDO no processo, confirme que o áudio sintético de "raro gravar" sai inteligível em português; se sair ruim, é gatilho de Plano B (pare e me avise).
- `output_format` NÃO precisa ser declarado (ONNX é o default; a doc só documenta `output_format: tflite` para TROCAR — não use).

## PROTOCOLO — duas rodadas

### RODADA 1 — QUICK (só provar que roda de ponta a ponta; ~20-40 min). n_samples=2000.
Execute este bloco (em ambiente GPU CUDA; no Kaggle, célula `%%bash`):

```bash
%%bash
set -e
# Kaggle: rodar TUDO no /tmp (~1.1TB). /kaggle/working tem cota 20GB e o setup baixa ~17GB
# (estourou na 1ª rodada real, 2026-06-12). Instalação SEMPRE antes do CLI (senão "command not found").
rm -rf /kaggle/working/data /kaggle/working/output
export HF_HOME=/tmp/hf
mkdir -p /tmp/raro_run/configs /tmp/hf /tmp/raro_data
cd /tmp/raro_run
apt-get update -qq && apt-get install -y -qq espeak-ng libsndfile1 ffmpeg sox portaudio19-dev
pip install -q "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
python -c "import torch; assert torch.cuda.is_available(), 'SEM GPU CUDA — VoxCPM/PT-BR nao roda'; print('GPU OK:', torch.cuda.get_device_name(0))"
command -v livekit-wakeword || { echo 'ERRO: livekit-wakeword nao instalou'; exit 1; }
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
data_dir: /tmp/raro_data
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
mkdir -p /kaggle/working/saidas
find /tmp/raro_run -name "*.onnx" -exec cp {} /kaggle/working/saidas/ \; 2>/dev/null || true
find /tmp/raro_run -name "*.json"  -exec cp {} /kaggle/working/saidas/ \; 2>/dev/null || true
echo "===== ARQUIVOS GERADOS (Output > saidas) ====="; ls -la /kaggle/working/saidas/ || true
echo "FIM."
```

- Se terminar com **"FIM."** + arquivos `.onnx` listados → pipeline OK, vá para a RODADA 2.
- Se der **erro**: NÃO invente correção. Leia a mensagem, cheque contra a doc real (links acima), e me reporte: (a) o erro completo, (b) a causa provável, (c) o fix que você propõe — antes de aplicar. Se o erro for "comando/flag/campo não existe", a doc real manda.

### RODADA 2 — FULL (os números de verdade; algumas horas). 
Repita o MESMO bloco, mas troque os dois valores:
- `n_samples: 2000` → `n_samples: 15000`
- `n_samples_val: 500` → `n_samples_val: 3000`
(o resto idêntico.) Se passar de ~8h ou travar, PARE e me avise (a gente reduz o tamanho ou troca de GPU).

## O QUE ME REPORTAR NO FINAL
Para CADA comando (`raro_gravar` e `raro_parar`), tire do `eval`:
1. **Recall** (acerto da palavra) — em %.
2. **Falsos-positivos por hora** (disparo à toa).
3. Caminho do `.onnx` gerado + do JSON de métricas.
E um **veredito**: passou no gate (recall>80% E FP baixo)? Se SIM, me avise que está pronto pra integração no iPhone. Se NÃO, me diga qual Plano B você recomenda (subir n_samples/model_size, +voice_design_prompts para 50-100, reforçar negativos PT-BR, ou gravações reais).

## REGRAS (para não repetir erros)
- Valide em fonte primária antes de mudar qualquer comando/config — nunca de memória.
- Não declare "pronto/funcionou" sem os números do `eval`.
- Reporte qualquer erro com a evidência; não mascare nem improvise workaround.

===
