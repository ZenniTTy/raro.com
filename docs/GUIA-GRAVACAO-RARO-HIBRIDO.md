# Guia de Gravação — "Raro" para treino híbrido (S2.F)

> Objetivo: coletar 50–100 gravações reais da palavra **"Raro"** (só ela, isolada) para entrar no TREINO do modelo (não só na validação). Isso fecha o domain gap de timbre que o experimento de controle provou ser a causa (modelo `parar` reconhece sua voz forte=0.73, modelo `raro` não=0.25 → o `raro` foi mal treinado, não a palavra).

## Por que tantas e tão variadas

O modelo precisa aprender a **sua** voz "Raro" em condições reais. Quanto mais variação (distância, tom, ambiente), mais ele generaliza. 1 gravação perfeita repetida 50× ensina menos que 50 gravações diferentes. A meta é **diversidade**, não perfeição.

## Formato técnico (importante — o pipeline exige)

- **16 kHz, mono, PCM 16-bit, .wav**
- Cada arquivo = **uma** elocução de "Raro" (~0.7–1.2s), com um pouco de silêncio antes/depois
- Não precisa ser estúdio — pelo contrário, queremos variação real

## Como gravar (a forma mais simples)

Você pode gravar do jeito que for mais fácil (app de gravador do iPhone, ou direto perto do Mac). O importante é a **variação**. Eu converto tudo pro formato certo depois — então **não se preocupe com o formato na hora de gravar**, só grave com qualidade audível.

### As ~60 elocuções recomendadas (varie assim):

**Tom / entonação (grave cada um ~3×):**
1. "Raro" normal, voz neutra
2. "Raro" mais alto (como se chamasse de longe)
3. "Raro" baixinho / quase sussurro
4. "Raro" rápido
5. "Raro" devagar/arrastado
6. "Raro" animado/empolgado
7. "Raro" cansado/monótono

**Distância do microfone (grave o conjunto acima em cada distância):**
- Perto (~20cm)
- Médio (~1 metro)
- Longe (~2-3 metros, como se o telefone estivesse na mesa)

**Ambiente (se possível, repita em 2-3 lugares):**
- Silencioso (quarto)
- Com algum ruído de fundo (TV baixa, rua, ventilador)
- Ao ar livre (se der — simula pescaria)

**Bônus (simula o caso de uso real):**
- "Raro" com o iPhone **dentro do bolso** ou coberto por tecido (abafado)
- "Raro" andando/movimento

## Quantidade

- **Mínimo útil:** 50 elocuções variadas
- **Ideal:** 80–100
- Pode gravar tudo num arquivo só (eu corto) OU vários arquivos — como for mais fácil pra você

## Onde colocar

Grave e me diga onde estão (ex: "salvei em Downloads", ou me manda o caminho). Eu cuido de:
- Cortar em clips individuais (se vier tudo junto)
- Converter pro formato exato (16kHz mono)
- Validar a qualidade (descartar os ruins)
- Injetar no treino com peso + augmentation de bolso

## O que acontece depois (eu faço)

1. Processo suas gravações → `positive_train/`
2. Configuro augmentation agressivo (RIR + low-pass de bolso + ruído)
3. Re-treino no RunPod (~US$3)
4. Mido no recall offline (grátis) se "Raro" subiu de 0.25 → 0.5+
5. Se passar: bundle no app + você testa ao vivo

---

**Resumo pra você:** grave umas 50-100 vezes a palavra "Raro" (só ela), variando bastante o jeito de falar, a distância e o ambiente. Não precisa caprichar no formato — eu ajusto. Quanto mais variado, melhor o modelo aprende a SUA voz. Me avisa onde salvou.
