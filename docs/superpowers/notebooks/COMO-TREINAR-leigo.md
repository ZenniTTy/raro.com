# Como treinar o modelo "Raro" — checklist leigo (Kaggle, grátis)

> Sua parte: rodar o treino numa máquina com GPU grátis (Kaggle) e me trazer 2 números.
> Você NÃO precisa programar — é colar um bloco e clicar em rodar. Leva ~10 min de cliques + espera.

---

## ⚠️ Entenda em 1 frase antes de começar

São **duas rodadas**:
1. **Rodada RÁPIDA (~20-40 min):** só pra ver se "roda sem erro". O modelo sai fraco de propósito.
2. **Rodada CHEIA (algumas horas):** essa dá os números de verdade.

Faça a RÁPIDA primeiro. Se ela rodar limpa, faça a CHEIA.

---

## PARTE 1 — Abrir a máquina grátis (Kaggle)

- [ ] 1. Entre em **kaggle.com** e faça login (ou crie conta grátis).
- [ ] 2. **Verifique o telefone** (obrigatório pra GPU grátis): clique na sua foto (canto sup. direito) → **Settings** → **Phone Verification** → confirme o número.
- [ ] 3. No menu da esquerda, clique em **Create** → **New Notebook**.
- [ ] 4. No painel da **direita**, em **Session options**:
  - [ ] **Accelerator** → escolha **GPU T4 x2**.
  - [ ] **Internet** → deixe **On** (ligado).
- [ ] 5. Pronto, a máquina está aberta. Agora é colar e rodar.

---

## PARTE 2 — Rodada RÁPIDA (provar que roda)

- [ ] 6. Apague o que estiver na primeira célula e **cole o bloco inteiro abaixo** nela:

```bash
%%bash
set -e
export WORK=/kaggle/working
export HF_HOME=$WORK/.cache/hf
mkdir -p $HF_HOME configs

# instala o necessário
apt-get update -qq && apt-get install -y -qq espeak-ng libsndfile1 ffmpeg sox portaudio19-dev
pip install -q "livekit-wakeword[train,eval,export,voxcpm]==0.2.1"

# confere a GPU (sem ela, VoxCPM/PT-BR nao roda)
python -c "import torch; assert torch.cuda.is_available(), 'SEM GPU — ligue o Accelerator GPU T4 nas Session options'; print('GPU OK:', torch.cuda.get_device_name(0))"

# vozes sinteticas (descricoes em ingles; a frase sai em portugues)
PROMPTS='  voice_design_prompts:
    - "A young adult woman, clear mid-pitch voice, moderate pace, calm"
    - "A young adult man, warm baritone, steady pace, friendly"
    - "A middle-aged woman, slightly low voice, relaxed pace, confident"
    - "A middle-aged man, deep voice, slow pace, authoritative"
    - "A teenage girl, bright high-pitched voice, quick pace, energetic"
    - "An elderly man, gravelly low voice, slow pace, measured"
    - "A woman speaking from a distance with light room reverb"
    - "A man speaking close to the mic, intimate"'

# config do "Raro gravar" (RAPIDO: n_samples baixo)
cat > configs/raro_gravar.yaml <<EOF
model_name: raro_gravar
target_phrases:
  - "raro gravar"
tts_backend: voxcpm
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

# config do "Raro parar"
sed 's/raro_gravar/raro_parar/; s/raro gravar/raro parar/' configs/raro_gravar.yaml > configs/raro_parar.yaml

# baixa modelos base + treina os dois comandos
livekit-wakeword setup --config configs/raro_gravar.yaml
for c in raro_gravar raro_parar; do
  echo "===== treinando $c ====="
  livekit-wakeword run configs/$c.yaml
  echo "===== avaliando $c ====="
  livekit-wakeword eval configs/$c.yaml
done

echo "===== ARQUIVOS GERADOS ====="
find $WORK -name "*.onnx" -printf "%p (%s bytes)\n" || true
echo "FIM."
```

- [ ] 7. Clique no **▶ (Run)** da célula (ou aperte **Shift+Enter**).
- [ ] 8. **Espere.** Vai aparecer bastante texto rolando. É normal demorar 20-40 min.
- [ ] 9. **Olhe o final do texto:**
  - ✅ Se terminar com **"FIM."** e listar arquivos **`.onnx`** → rodou limpo. **Vá pra PARTE 3.**
  - ❌ Se parar com texto **vermelho** (erro) → **copie esse texto vermelho inteiro e me mande.** Não tente consertar sozinho.

---

## PARTE 3 — Rodada CHEIA (os números de verdade)

> Só faça se a RÁPIDA terminou com "FIM." sem erro.

- [ ] 10. Na mesma célula, troque **as duas linhas** `n_samples: 2000` e `n_samples_val: 500` por:
  ```
  n_samples: 15000
  n_samples_val: 3000
  ```
  (é só editar os números no bloco que você já colou)
- [ ] 11. Clique em **▶ Run** de novo.
- [ ] 12. **Espere** — agora demora **algumas horas**. Pode deixar rodando (a janela do Kaggle precisa ficar aberta; o limite é 9h).
- [ ] 13. Quando terminar com "FIM.", **vá pra PARTE 4.**

---

## PARTE 4 — Me trazer o resultado

- [ ] 14. No painel da **direita**, em **Output** / **Data**, ache os arquivos **`raro_gravar.onnx`** e **`raro_parar.onnx`** → baixe os dois (botão de download).
- [ ] 15. Ache também os arquivos que terminam em **`.json`** com as métricas → baixe.
- [ ] 16. **Me mande:** os 2 arquivos `.onnx` + os `.json`, OU só me diga os dois números que aparecem na avaliação de cada comando:
  - **Recall** (o quanto ele acerta o "Raro") — queremos **acima de 80%**.
  - **Falsos positivos por hora** (o quanto ele dispara à toa) — queremos **baixo**.

Com esses números eu decido: **bom → integro no iPhone.** **Fraco → ajusto o treino (Plano B)** e você roda de novo.

---

## Se algo der errado (rede de segurança)

- Qualquer **texto vermelho** = erro. **Copie e cole pra mim.** Não improvise.
- Se passar de **~8h** sem terminar na rodada cheia: pare, e me avise — a gente reduz o tamanho ou aluga uma GPU mais rápida (~R$10).
- Se a célula reclamar de **"SEM GPU"**: você esqueceu de ligar o **Accelerator GPU T4** nas *Session options* (Parte 1, passo 4). Ligue e rode de novo.

> Detalhe honesto: esse bloco foi validado lendo a documentação oficial, mas não foi rodado de verdade (eu não tenho GPU). Pode aparecer algum ajuste na 1ª vez — por isso o "copie o erro e me mande". A gente resolve junto.
